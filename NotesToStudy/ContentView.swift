//
//  ContentView.swift
//  NotesToStudy
//
//  Created by Ethan Blanche on 4/1/25.
//

import SwiftUI
import PhotosUI

struct Note: Identifiable {
    let id = UUID()
    var image: UIImage
    var title: String
    var date: Date
}

struct Flashcard: Identifiable {
    let id = UUID()
    var question: String
    var answer: String
    var noteId: UUID?
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var notes: [Note] = []
    @State private var flashcards: [Flashcard] = []
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var showingFlashcardEdit = false
    @State private var selectedImage: UIImage?
    @State private var showingStudyView = false
    @State private var isProcessingNote = false
    @State private var showingProcessingAlert = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Notes Tab
            NavigationView {
                List {
                    ForEach(notes) { note in
                        NoteRow(note: note)
                    }
                }
                .navigationTitle("My Notes")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                showingCamera = true
                            }) {
                                Label("Take Photo", systemImage: "camera")
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Label("Choose Photo", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(0)
            
            // Flashcards Tab
            NavigationView {
                List {
                    ForEach(flashcards) { flashcard in
                        FlashcardRow(flashcard: flashcard)
                    }
                }
                .navigationTitle("Flashcards")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingFlashcardEdit = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem {
                Label("Flashcards", systemImage: "rectangle.stack")
            }
            .tag(1)
            
            // Study Tab
            NavigationView {
                VStack {
                    if flashcards.isEmpty {
                        Text("No flashcards to study")
                            .foregroundColor(.gray)
                    } else {
                        Button(action: {
                            showingStudyView = true
                        }) {
                            Text("Start Studying")
                                .font(.title2)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .navigationTitle("Study")
            }
            .tabItem {
                Label("Study", systemImage: "brain")
            }
            .tag(2)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $selectedImage)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingFlashcardEdit) {
            FlashcardEditView(flashcards: $flashcards)
        }
        .sheet(isPresented: $showingStudyView) {
            StudyView(flashcards: flashcards)
        }
        .alert("Processing Note", isPresented: $showingProcessingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please wait while we analyze your note and create flashcards...")
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                let note = Note(image: image, title: "New Note", date: Date())
                notes.append(note)
                processNoteWithAI(note)
            }
        }
    }
    
    private func processNoteWithAI(_ note: Note) {
        isProcessingNote = true
        showingProcessingAlert = true
        
        AINoteProcessor.shared.processNoteImage(note.image) { generatedFlashcards in
            DispatchQueue.main.async {
                // Add the generated flashcards with the note's ID
                let flashcardsWithNoteId = generatedFlashcards.map { flashcard in
                    var newFlashcard = flashcard
                    newFlashcard.noteId = note.id
                    return newFlashcard
                }
                flashcards.append(contentsOf: flashcardsWithNoteId)
                
                isProcessingNote = false
                showingProcessingAlert = false
            }
        }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        HStack {
            Image(uiImage: note.image)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(note.title)
                    .font(.headline)
                Text(note.date.formatted())
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FlashcardRow: View {
    let flashcard: Flashcard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flashcard.question)
                .font(.headline)
            Text(flashcard.answer)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
