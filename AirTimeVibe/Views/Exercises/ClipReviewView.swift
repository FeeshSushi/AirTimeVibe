import SwiftUI
import AVFoundation
import SwiftData

struct ClipReviewView: View {
    @Environment(\.modelContext) private var context
    @State private var clips: [ClipDraft]
    let onSave: () -> Void

    init(clips: [ClipDraft], onSave: @escaping () -> Void) {
        _clips = State(initialValue: clips)
        self.onSave = onSave
    }

    private var allNamed: Bool {
        clips.allSatisfy { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        List {
            ForEach($clips) { $clip in
                ClipReviewRow(clip: $clip)
            }
        }
        .navigationTitle("Name Clips")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: saveAll) {
                Text("Save \(clips.count) Exercise\(clips.count == 1 ? "" : "s")")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!allNamed)
            .padding()
            .background(.bar)
        }
    }

    private func saveAll() {
        for clip in clips {
            let ex = Exercise(name: clip.name.trimmingCharacters(in: .whitespaces))
            ex.videoFileName = clip.url.lastPathComponent
            ex.category = clip.category
            ex.primaryMuscleGroup = clip.primaryMuscleGroup
            context.insert(ex)
        }
        onSave()
    }
}

// MARK: - Row

private struct ClipReviewRow: View {
    @Binding var clip: ClipDraft
    @State private var thumbnail: UIImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Thumbnail
                Group {
                    if let thumb = thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "video.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: 72, height: 48)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                TextField("Exercise name", text: $clip.name)
                    .font(.headline)
            }

            HStack(spacing: 12) {
                Picker("Category", selection: $clip.category) {
                    Text("No Category").tag(ExerciseCategory?.none)
                    ForEach(ExerciseCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.systemImage).tag(Optional(cat))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))

                Picker("Muscle Group", selection: $clip.primaryMuscleGroup) {
                    Text("No Muscle").tag(MuscleGroup?.none)
                    ForEach(MuscleGroup.allCases) { group in
                        Text(group.rawValue).tag(Optional(group))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 6)
        .task {
            thumbnail = await generateThumbnail(for: clip.url)
        }
    }

    private func generateThumbnail(for url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 144, height: 96)
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        guard let result = try? await generator.image(at: time) else { return nil }
        return UIImage(cgImage: result.image)
    }
}
