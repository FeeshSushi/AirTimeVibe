import SwiftUI
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?

    init(exercise: Exercise) {
        self.exercise = exercise
        if let url = exercise.videoURL {
            self._player = State(initialValue: AVPlayer(url: url))
        }
    }

    var body: some View {
        ZStack {
            // Layer 1: Full-screen media
            if let player {
                PlayerLayerView(player: player)
                    .ignoresSafeArea()
                    .onTapGesture { togglePlayback() }
            } else if let imageURL = exercise.imageURL,
                      let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }

            // Layer 2: Bottom gradient scrim
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
            }
            .ignoresSafeArea()

            // Layer 3: Floating controls (respects safe area)
            VStack(alignment: .leading) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                    Button("Edit") { showingEdit = true }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.horizontal)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("\(exercise.sets) sets × \(exercise.reps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    if exercise.category != nil || exercise.primaryMuscleGroup != nil {
                        HStack(spacing: 8) {
                            if let cat = exercise.category {
                                Label(cat.rawValue, systemImage: cat.systemImage)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.2), in: Capsule())
                            }
                            if let group = exercise.primaryMuscleGroup {
                                Label(group.rawValue, systemImage: "figure.arms.open")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.2), in: Capsule())
                            }
                        }
                    }
                    if !exercise.notes.isEmpty {
                        Text(exercise.notes)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(SwipeBackEnabler())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            player?.play()
            guard let item = player?.currentItem else { return }
            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            if let obs = loopObserver {
                NotificationCenter.default.removeObserver(obs)
                loopObserver = nil
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                ExerciseEditorView(exercise: exercise)
            }
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}

// MARK: - SwipeBackEnabler

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            vc.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

// MARK: - PlayerLayerView

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    var gravity: AVLayerVideoGravity = .resizeAspectFill

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = gravity
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = gravity
    }
}
