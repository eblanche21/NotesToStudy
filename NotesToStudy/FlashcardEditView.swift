import SwiftUI

struct FlashcardEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var flashcards: [Flashcard]
    @State private var question: String = ""
    @State private var answer: String = ""
    @State private var selectedNoteId: UUID?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Question")) {
                    TextEditor(text: $question)
                        .frame(height: 100)
                }
                
                Section(header: Text("Answer")) {
                    TextEditor(text: $answer)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Flashcard")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    let flashcard = Flashcard(
                        question: question,
                        answer: answer,
                        noteId: selectedNoteId
                    )
                    flashcards.append(flashcard)
                    dismiss()
                }
                .disabled(question.isEmpty || answer.isEmpty)
            )
        }
    }
} 