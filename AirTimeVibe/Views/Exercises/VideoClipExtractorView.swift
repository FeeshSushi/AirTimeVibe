import SwiftUI
import AVKit
import AVFoundation

struct ClipDraft: Identifiable {
    let id = UUID()
    let url: URL
    var name: String = ""
    var category: ExerciseCategory? = nil
    var primaryMuscleGroup: MuscleGroup? = nil
}

struct VideoClipExtractorView: View {
    let videoURL: URL

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var duration: Double = 1
    @State private var thumbnails: [UIImage] = []
    @State private var isPlaying = false
    @State private var isClipping = false
    @State private var currentTime: Double = 0
    @State private var timeObserver: Any?
    @State private var trimStart: Double = 0
    @State private var trimEnd: Double = 1
    @State private var clips: [ClipDraft] = []
    @State private var showingReview = false

    private let scrubberHeight: CGFloat = 64
    private let handleWidth: CGFloat = 18
    private let thumbnailCount = 12

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Video preview
                ZStack {
                    Color.black
                    if let player {
                        VideoPlayer(player: player)
                    }
                }
                .frame(height: 280)

                Spacer().frame(height: 16)

                // Trim timestamps
                HStack {
                    Text(formatTime(trimStart))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatTime(trimEnd - trimStart))
                        .font(.caption.bold().monospacedDigit())
                    Spacer()
                    Text(formatTime(trimEnd))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 10)

                // Thumbnail scrubber
                GeometryReader { geo in
                    let w = geo.size.width
                    let startX = CGFloat(trimStart / duration) * w
                    let endX = CGFloat(trimEnd / duration) * w
                    let playX = CGFloat(currentTime / duration) * w

                    ZStack(alignment: .leading) {
                        // Thumbnail strip
                        HStack(spacing: 0) {
                            ForEach(0..<thumbnails.count, id: \.self) { i in
                                Image(uiImage: thumbnails[i])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: w / CGFloat(thumbnails.count), height: scrubberHeight)
                                    .clipped()
                            }
                            if thumbnails.isEmpty {
                                Rectangle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: w, height: scrubberHeight)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Dimmed region before trim start
                        Rectangle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: max(0, startX), height: scrubberHeight)

                        // Dimmed region after trim end
                        Rectangle()
                            .fill(Color.black.opacity(0.55))
                            .frame(width: max(0, w - endX), height: scrubberHeight)
                            .offset(x: endX)

                        // Yellow selection border
                        Rectangle()
                            .stroke(Color.yellow, lineWidth: 2)
                            .frame(width: max(0, endX - startX), height: scrubberHeight)
                            .offset(x: startX)

                        // Start handle
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow)
                            .frame(width: handleWidth, height: scrubberHeight)
                            .offset(x: startX - handleWidth / 2)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let proposed = Double(value.location.x / w) * duration
                                        let clamped = max(0, min(trimEnd - 0.5, proposed))
                                        trimStart = clamped
                                        seek(to: clamped)
                                    }
                            )

                        // End handle
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.yellow)
                            .frame(width: handleWidth, height: scrubberHeight)
                            .offset(x: endX - handleWidth / 2)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let proposed = Double(value.location.x / w) * duration
                                        let clamped = max(trimStart + 0.5, min(duration, proposed))
                                        trimEnd = clamped
                                        seek(to: clamped)
                                    }
                            )

                        // Playhead
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: scrubberHeight)
                            .offset(x: playX)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: scrubberHeight)
                .padding(.horizontal, 20)

                Spacer().frame(height: 28)

                // Playback controls
                HStack(spacing: 40) {
                    Button {
                        seek(to: trimStart)
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }

                    Button {
                        togglePlayback()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        seek(to: trimEnd - 0.01)
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }

                Spacer().frame(height: 24)

                // Clip button
                Button(action: clipCurrent) {
                    Group {
                        if isClipping {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Clip", systemImage: "scissors")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isClipping || trimEnd - trimStart < 0.5)
                .padding(.horizontal, 20)

                Spacer().frame(height: 16)

                if !clips.isEmpty {
                    Text("\(clips.count) clip\(clips.count == 1 ? "" : "s") saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .navigationTitle("Extract Clips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done (\(clips.count))") {
                        showingReview = true
                    }
                    .disabled(clips.isEmpty)
                }
            }
            .navigationDestination(isPresented: $showingReview) {
                ClipReviewView(clips: clips) {
                    dismiss()
                }
            }
            .onAppear(perform: setup)
            .onDisappear(perform: cleanup)
        }
    }

    // MARK: - Setup

    private func setup() {
        let asset = AVURLAsset(url: videoURL)
        player = AVPlayer(url: videoURL)

        Task {
            do {
                let cmDuration = try await asset.load(.duration)
                let secs = cmDuration.seconds
                await MainActor.run {
                    duration = secs
                    trimEnd = secs
                }
                await generateThumbnails(asset: asset, duration: secs)
            } catch {}
        }

        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
            if currentTime >= trimEnd {
                player?.pause()
                isPlaying = false
                seek(to: trimStart)
            }
        }
    }

    private func cleanup() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        player?.pause()
    }

    // MARK: - Thumbnails

    private func generateThumbnails(asset: AVURLAsset, duration: Double) async {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 100, height: 70)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter  = CMTime(seconds: 0.1, preferredTimescale: 600)

        var images: [UIImage] = []
        for i in 0..<thumbnailCount {
            let t = CMTime(seconds: (duration / Double(thumbnailCount)) * Double(i), preferredTimescale: 600)
            if let result = try? await generator.image(at: t) {
                images.append(UIImage(cgImage: result.image))
            } else {
                images.append(UIImage())
            }
        }
        await MainActor.run { thumbnails = images }
    }

    // MARK: - Playback

    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            if currentTime >= trimEnd { seek(to: trimStart) }
            player?.play()
        }
        isPlaying.toggle()
    }

    private func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600),
                     toleranceBefore: .zero,
                     toleranceAfter: .zero)
    }

    // MARK: - Clipping

    private func clipCurrent() {
        isClipping = true
        player?.pause()
        isPlaying = false
        let start = trimStart
        let end = trimEnd
        Task {
            do {
                let url = try await VideoExporter.export(url: videoURL, trimStart: start, trimEnd: end)
                await MainActor.run {
                    clips.append(ClipDraft(url: url))
                    // Advance start handle to end of clipped segment
                    trimStart = end
                    trimEnd = duration
                    seek(to: end)
                    isClipping = false
                }
            } catch {
                await MainActor.run { isClipping = false }
            }
        }
    }
}
