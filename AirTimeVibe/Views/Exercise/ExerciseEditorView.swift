import SwiftUI
import SwiftData
import AVKit

struct ExerciseEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var routine: Routine?   // set when adding a new exercise from a routine
    var exercise: Exercise? // set when editing an existing exercise

    @State private var name: String = ""
    @State private var sets: Int = 3
    @State private var reps: Int = 10
    @State private var notes: String = ""
    @State private var trimStart: Double = 0
    @State private var trimEnd: Double = 0

    @State private var pickedVideoURL: URL?
    @State private var previewPlayer: AVPlayer?
    @State private var showingVideoPicker = false
    @State private var showingTrimmer = false

    @State private var pickedImageURL: URL?
    @State private var showingImagePicker = false

    private var isEditing: Bool { exercise != nil }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Exercise name", text: $name)
            }

            Section("Volume") {
                Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                Stepper("Reps: \(reps)", value: $reps, in: 1...100)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }

            Section("Video") {
                if previewPlayer != nil {
                    VideoPlayer(player: previewPlayer)
                        .frame(height: 200)
                        .cornerRadius(10)
                        .listRowInsets(EdgeInsets())

                    Button("Trim Video") {
                        showingTrimmer = true
                    }

                    Button("Remove Video", role: .destructive) {
                        previewPlayer = nil
                        pickedVideoURL = nil
                        if let ex = exercise {
                            ex.videoFileName = nil
                            ex.trimStart = 0
                            ex.trimEnd = 0
                        }
                    }
                } else {
                    Button {
                        showingVideoPicker = true
                    } label: {
                        Label("Add Video from Library", systemImage: "video.badge.plus")
                    }
                }
            }

            Section("Image") {
                if let imageURL = pickedImageURL ?? exercise?.imageURL,
                   let uiImage = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                        .listRowInsets(EdgeInsets())

                    Button("Remove Image", role: .destructive) {
                        pickedImageURL = nil
                        if let ex = exercise {
                            ex.imageFileName = nil
                        }
                    }
                } else {
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Add Image from Library", systemImage: "photo.badge.plus")
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear(perform: loadExisting)
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView(selectedURL: $pickedVideoURL)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(selectedURL: $pickedImageURL)
        }
        .onChange(of: pickedVideoURL) { _, newURL in
            guard let url = newURL else { return }
            previewPlayer = AVPlayer(url: url)
        }
        .sheet(isPresented: $showingTrimmer) {
            if let url = pickedVideoURL ?? exercise?.videoURL {
                VideoTrimmerView(
                    videoURL: url,
                    trimStart: $trimStart,
                    trimEnd: $trimEnd,
                    onSave: { exportedURL in
                        pickedVideoURL = exportedURL
                        showingTrimmer = false
                    }
                )
            }
        }
    }

    private func loadExisting() {
        guard let ex = exercise else { return }
        name = ex.name
        sets = ex.sets
        reps = ex.reps
        notes = ex.notes
        trimStart = ex.trimStart
        trimEnd = ex.trimEnd
        if let url = ex.videoURL {
            previewPlayer = AVPlayer(url: url)
        }
        pickedImageURL = ex.imageURL
    }

    private func save() {
        Task {
            let videoFileName = await resolveVideoFileName()
            let imageFileName = await resolveImageFileName()
            await MainActor.run {
                if let ex = exercise {
                    ex.name = name
                    ex.sets = sets
                    ex.reps = reps
                    ex.notes = notes
                    ex.trimStart = trimStart
                    ex.trimEnd = trimEnd
                    if let fileName = videoFileName {
                        ex.videoFileName = fileName
                    }
                    if let fileName = imageFileName {
                        ex.imageFileName = fileName
                    }
                } else {
                    let newExercise = Exercise(
                        name: name.trimmingCharacters(in: .whitespaces),
                        sets: sets,
                        reps: reps,
                        notes: notes,
                        order: routine?.exercises.count ?? 0
                    )
                    newExercise.videoFileName = videoFileName
                    newExercise.trimStart = trimStart
                    newExercise.trimEnd = trimEnd
                    newExercise.imageFileName = imageFileName
                    context.insert(newExercise)
                    // Link to routine if created from within one; skip for standalone library exercises.
                    if let r = routine {
                        r.exercises.append(newExercise)
                    }
                }
                dismiss()
            }
        }
    }

    /// Copies the picked video to the Documents directory if needed and returns its filename.
    private func resolveVideoFileName() async -> String? {
        guard let url = pickedVideoURL else { return nil }
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if url.path.hasPrefix(docsDir.path) {
            return url.lastPathComponent
        }
        let fileName = UUID().uuidString + ".mp4"
        let destURL = docsDir.appendingPathComponent(fileName)
        try? FileManager.default.copyItem(at: url, to: destURL)
        return fileName
    }

    /// Copies the picked image to the Documents directory if needed and returns its filename.
    private func resolveImageFileName() async -> String? {
        guard let url = pickedImageURL else { return nil }
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        if url.path.hasPrefix(docsDir.path) {
            return url.lastPathComponent
        }
        let fileName = UUID().uuidString + ".jpg"
        let destURL = docsDir.appendingPathComponent(fileName)
        try? FileManager.default.copyItem(at: url, to: destURL)
        return fileName
    }
}
