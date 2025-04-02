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

struct NoteNameView: View {
    @Binding var isPresented: Bool
    @Binding var noteTitle: String
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Note Title", text: $noteTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .navigationTitle("Name Your Note")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 0, y: 0),
                trailing: Button("Save") {
                    onSave()
                    isPresented = false
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
                .disabled(noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .toolbarBackground(Color.red, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
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
    @State private var showingNoteSelection = false
    @State private var selectedNotes: Set<UUID> = []
    @State private var showingAllFlashcards = false
    @State private var showingNoteNamePrompt = false
    @State private var newNoteTitle = ""
    
    var filteredFlashcards: [Flashcard] {
        if showingAllFlashcards {
            return flashcards
        } else {
            return flashcards.filter { flashcard in
                guard let noteId = flashcard.noteId else { return false }
                return selectedNotes.contains(noteId)
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Notes Tab
            NavigationView {
                List {
                    ForEach(notes) { note in
                        NoteRow(note: note, notes: $notes)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedNotes.contains(note.id) {
                                    selectedNotes.remove(note.id)
                                } else {
                                    selectedNotes.insert(note.id)
                                }
                            }
                            .background(selectedNotes.contains(note.id) ? Color.blue.opacity(0.2) : Color.clear)
                    }
                    .onDelete { indexSet in
                        // Get the IDs of notes to be deleted before removing them
                        let noteIdsToDelete = indexSet.map { notes[$0].id }
                        
                        // Remove the notes
                        notes.remove(atOffsets: indexSet)
                        
                        // Remove associated flashcards using the saved IDs
                        for noteId in noteIdsToDelete {
                            flashcards.removeAll { $0.noteId == noteId }
                        }
                        
                        // Clear selection if any of the deleted notes were selected
                        selectedNotes.removeAll()
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
                            
                            if !notes.isEmpty {
                                Button(action: {
                                    showingNoteSelection = true
                                }) {
                                    Label("Generate Flashcards", systemImage: "rectangle.stack")
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 1, x: 0, y: 0)
                        }
                    }
                }
                .toolbarBackground(Color.red, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label("Notes", systemImage: "note.text")
            }
            .tag(0)
            
            // Flashcards Tab
            NavigationView {
                VStack {
                    if !notes.isEmpty {
                        Toggle("Show All Flashcards", isOn: $showingAllFlashcards)
                            .font(.system(size: 15, weight: .regular))
                            .padding()
                    }
                    
                    List {
                        ForEach(filteredFlashcards) { flashcard in
                            FlashcardRow(flashcard: flashcard)
                        }
                    }
                }
                .navigationTitle("Flashcards")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingFlashcardEdit = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 1, x: 0, y: 0)
                        }
                    }
                }
                .toolbarBackground(Color.red, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label("Flashcards", systemImage: "rectangle.stack")
            }
            .tag(1)
            
            // Study Tab
            NavigationView {
                VStack {
                    if filteredFlashcards.isEmpty {
                        Text("No flashcards to study")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.gray)
                    } else {
                        Button(action: {
                            showingStudyView = true
                        }) {
                            Text("Start Studying")
                                .font(.system(size: 22, weight: .medium))
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .navigationTitle("Study")
                .toolbarBackground(Color.red, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
            }
            .tabItem {
                Label("Study", systemImage: "brain")
            }
            .tag(2)
        }
        .tint(.white)
        .onAppear {
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .red
            
            // Customize the unselected item appearance
            appearance.stackedLayoutAppearance.normal.iconColor = .white.withAlphaComponent(0.5)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.5)]
            
            // Use this appearance for both normal and scrolling states
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
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
            StudyView(flashcards: filteredFlashcards)
        }
        .sheet(isPresented: $showingNoteSelection) {
            NoteSelectionView(notes: notes, selectedNotes: $selectedNotes) { selectedNotes in
                processSelectedNotes(selectedNotes)
            }
        }
        .sheet(isPresented: $showingNoteNamePrompt) {
            NoteNameView(isPresented: $showingNoteNamePrompt, noteTitle: $newNoteTitle) {
                if let image = selectedImage {
                    let note = Note(image: image, title: newNoteTitle, date: Date())
                    notes.append(note)
                    newNoteTitle = "" // Reset for next use
                }
            }
        }
        .alert("Processing Notes", isPresented: $showingProcessingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please wait while we analyze your notes and create flashcards...")
        }
        .onChange(of: selectedImage) { newImage in
            if newImage != nil {
                newNoteTitle = "" // Reset title
                showingNoteNamePrompt = true
            }
        }
    }
    
    private func processSelectedNotes(_ selectedNoteIds: Set<UUID>) {
        isProcessingNote = true
        showingProcessingAlert = true
        
        var selectedNotes = notes.filter { selectedNoteIds.contains($0.id) }
        var newFlashcards: [Flashcard] = []
        let group = DispatchGroup()
        
        for note in selectedNotes {
            group.enter()
            AINoteProcessor.shared.processNoteImage(note.image) { generatedFlashcards in
                let flashcardsWithNoteId = generatedFlashcards.map { flashcard in
                    var newFlashcard = flashcard
                    newFlashcard.noteId = note.id
                    return newFlashcard
                }
                newFlashcards.append(contentsOf: flashcardsWithNoteId)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Filter out duplicates before adding new flashcards
            let uniqueFlashcards = newFlashcards.filter { newFlashcard in
                !flashcards.contains { existingFlashcard in
                    // Consider flashcards duplicate if they have the same question and answer
                    existingFlashcard.question.lowercased() == newFlashcard.question.lowercased() &&
                    existingFlashcard.answer.lowercased() == newFlashcard.answer.lowercased()
                }
            }
            
            flashcards.append(contentsOf: uniqueFlashcards)
            isProcessingNote = false
            showingProcessingAlert = false
            selectedNotes.removeAll()
        }
    }
}

struct NoteSelectionView: View {
    let notes: [Note]
    @Binding var selectedNotes: Set<UUID>
    let onGenerate: (Set<UUID>) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    HStack {
                        NoteRow(note: note, notes: .constant(notes))
                        Spacer()
                        if selectedNotes.contains(note.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedNotes.contains(note.id) {
                            selectedNotes.remove(note.id)
                        } else {
                            selectedNotes.insert(note.id)
                        }
                    }
                }
            }
            .navigationTitle("Select Notes")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Generate") {
                    onGenerate(selectedNotes)
                    dismiss()
                }
                .disabled(selectedNotes.isEmpty)
            )
        }
    }
}

struct NoteRow: View {
    let note: Note
    @Binding var notes: [Note]
    @State private var isEditingTitle = false
    @State private var editedTitle: String = ""
    
    var body: some View {
        HStack {
            Image(uiImage: note.image)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                if isEditingTitle {
                    TextField("Note Title", text: $editedTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .onSubmit {
                            updateTitle()
                        }
                } else {
                    Text(note.title)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .onTapGesture {
                            editedTitle = note.title
                            isEditingTitle = true
                        }
                }
                Text(note.date.formatted())
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func updateTitle() {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.title = editedTitle
            notes[index] = updatedNote
        }
        isEditingTitle = false
    }
}

struct FlashcardRow: View {
    let flashcard: Flashcard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flashcard.question)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
            Text(flashcard.answer)
                .font(.system(size: 16, weight: .light))
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
