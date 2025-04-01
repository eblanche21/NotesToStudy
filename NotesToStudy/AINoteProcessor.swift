import Vision
import UIKit
import NaturalLanguage

class AINoteProcessor {
    static let shared = AINoteProcessor()
    
    private let tagger = NLTagger(tagSchemes: [.lexicalClass])
    
    func processNoteImage(_ image: UIImage, completion: @escaping ([Flashcard]) -> Void) {
        // Ensure we're on a background thread for processing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let cgImage = image.cgImage else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Text recognition error: \(error)")
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    DispatchQueue.main.async {
                        completion([])
                    }
                    return
                }
                
                let text = observations.compactMap { observation -> String? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    return topCandidate.string
                }.joined(separator: "\n")
                
                self.generateFlashcards(from: text) { flashcards in
                    DispatchQueue.main.async {
                        completion(flashcards)
                    }
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform recognition: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    private func generateFlashcards(from text: String, completion: @escaping ([Flashcard]) -> Void) {
        // Ensure we're on a background thread for processing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion([])
                return
            }
            
            var flashcards: [Flashcard] = []
            
            // Split text into paragraphs and process each one
            let paragraphs = text.components(separatedBy: "\n\n")
            
            for paragraph in paragraphs {
                // Skip empty paragraphs
                guard !paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                
                // Use NLP to identify key concepts and relationships
                self.tagger.string = paragraph
                
                self.tagger.enumerateTags(in: paragraph.startIndex..<paragraph.endIndex, unit: .sentence, scheme: .lexicalClass) { tag, range in
                    guard let tag = tag else { return true }
                    
                    let sentence = String(paragraph[range])
                    
                    // Look for sentences that might contain question-answer pairs
                    if sentence.contains("?") || sentence.contains(":") || sentence.contains("is") {
                        // Try to split into question and answer
                        if let (question, answer) = self.splitIntoQA(sentence) {
                            let flashcard = Flashcard(
                                question: question,
                                answer: answer,
                                noteId: nil
                            )
                            flashcards.append(flashcard)
                        }
                    }
                    
                    return true
                }
            }
            
            completion(flashcards)
        }
    }
    
    private func splitIntoQA(_ text: String) -> (question: String, answer: String)? {
        // Try different patterns to split into Q&A
        let patterns = [
            // Question followed by answer
            #"^(.+?)\?\s*(.+)$"#,
            // Definition pattern (X is Y)
            #"^(.+?)\s+is\s+(.+)$"#,
            // Colon pattern (X: Y)
            #"^(.+?):\s*(.+)$"#,
            // Key-value pattern (X - Y)
            #"^(.+?)\s*-\s*(.+)$"#
        ]
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(text.startIndex..., in: text)
                
                if let match = regex.firstMatch(in: text, range: range) {
                    // Verify we have exactly 2 capture groups
                    guard match.numberOfRanges == 3 else { continue } // 3 because first range is the full match
                    
                    // Get the ranges for question and answer
                    let questionRange = match.range(at: 1)
                    let answerRange = match.range(at: 2)
                    
                    // Verify ranges are valid
                    guard questionRange.location != NSNotFound,
                          answerRange.location != NSNotFound,
                          questionRange.length > 0,
                          answerRange.length > 0 else {
                        continue
                    }
                    
                    // Convert NSRange to String.Index ranges
                    guard let questionStringRange = Range(questionRange, in: text),
                          let answerStringRange = Range(answerRange, in: text) else {
                        continue
                    }
                    
                    let question = String(text[questionStringRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let answer = String(text[answerStringRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Verify we have valid content
                    if !question.isEmpty && !answer.isEmpty {
                        return (question, answer)
                    }
                }
            } catch {
                print("Regex error: \(error)")
                continue
            }
        }
        
        return nil
    }
} 
