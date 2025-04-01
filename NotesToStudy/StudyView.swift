import SwiftUI

struct StudyView: View {
    let flashcards: [Flashcard]
    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    @State private var studyProgress: [UUID: Bool] = [:]
    @State private var showingResults = false
    
    var body: some View {
        VStack {
            if flashcards.isEmpty {
                Text("No flashcards to study")
                    .foregroundColor(.gray)
            } else {
                // Progress bar
                ProgressView(value: Double(currentIndex), total: Double(flashcards.count))
                    .padding()
                
                // Flashcard
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 10)
                    
                    VStack {
                        if isShowingAnswer {
                            Text(flashcards[currentIndex].answer)
                                .font(.title2)
                                .padding()
                                .multilineTextAlignment(.center)
                        } else {
                            Text(flashcards[currentIndex].question)
                                .font(.title2)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(height: 300)
                .padding()
                .onTapGesture {
                    withAnimation {
                        isShowingAnswer.toggle()
                    }
                }
                
                // Navigation buttons
                HStack(spacing: 20) {
                    Button(action: {
                        studyProgress[flashcards[currentIndex].id] = false
                        moveToNextCard()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        studyProgress[flashcards[currentIndex].id] = true
                        moveToNextCard()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.green)
                    }
                }
                .padding()
                
                // Card counter
                Text("\(currentIndex + 1) of \(flashcards.count)")
                    .foregroundColor(.gray)
            }
        }
        .sheet(isPresented: $showingResults) {
            StudyResultsView(studyProgress: studyProgress)
        }
    }
    
    private func moveToNextCard() {
        if currentIndex < flashcards.count - 1 {
            currentIndex += 1
            isShowingAnswer = false
        } else {
            showingResults = true
        }
    }
}

struct StudyResultsView: View {
    @Environment(\.dismiss) var dismiss
    let studyProgress: [UUID: Bool]
    
    var correctCount: Int {
        studyProgress.filter { $0.value }.count
    }
    
    var totalCount: Int {
        studyProgress.count
    }
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount) * 100
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Study Session Complete!")
                    .font(.title)
                
                Text("\(correctCount) out of \(totalCount) correct")
                    .font(.title2)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(percentage >= 70 ? .green : .orange)
                
                Button("Done") {
                    dismiss()
                }
                .padding()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
} 