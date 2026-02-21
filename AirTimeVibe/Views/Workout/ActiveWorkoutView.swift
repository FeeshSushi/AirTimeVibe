import SwiftUI
import SwiftData
import AVKit

// MARK: - Draft type

struct ExerciseLogDraft {
    var exerciseName: String
    var targetSets: Int
    var targetReps: Int
    var completedSets: Int = 0

    init(exercise: Exercise) {
        self.exerciseName = exercise.name
        self.targetSets = exercise.sets
        self.targetReps = exercise.reps
    }
}

// MARK: - ActiveWorkoutView

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let routine: Routine

    @State private var currentIndex: Int? = 0
    @State private var drafts: [ExerciseLogDraft] = []
    @State private var showCancelConfirm = false
    @State private var finished = false

    private var sortedExercises: [Exercise] { routine.sortedExercises }

    var body: some View {
        if finished {
            FinishedView()
        } else {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(sortedExercises.indices, id: \.self) { i in
                        if i < drafts.count {
                            ExerciseReelCell(
                                exercise: sortedExercises[i],
                                draft: $drafts[i],
                                onCancel: { showCancelConfirm = true },
                                onFinish: saveSession
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentIndex)
            .ignoresSafeArea()
            .confirmationDialog("End this workout?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
                Button("End Workout", role: .destructive) { dismiss() }
                Button("Keep Going", role: .cancel) {}
            }
            .onAppear {
                drafts = sortedExercises.map { ExerciseLogDraft(exercise: $0) }
            }
        }
    }

    private func saveSession() {
        let session = WorkoutSession(routine: routine)
        context.insert(session)

        for draft in drafts {
            let log = ExerciseLog(
                exerciseName: draft.exerciseName,
                targetSets: draft.targetSets,
                targetReps: draft.targetReps
            )
            log.completedSets = (0..<draft.completedSets).map { _ in
                SetEntry(weight: 0, reps: draft.targetReps)
            }
            log.session = session
            context.insert(log)
        }

        finished = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}

// MARK: - FinishedView

private struct FinishedView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                Text("Workout Complete!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("Great work today.")
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - ExerciseReelCell

private struct ExerciseReelCell: View {
    let exercise: Exercise
    @Binding var draft: ExerciseLogDraft
    let onCancel: () -> Void
    let onFinish: () -> Void

    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?
    @State private var safeTop: CGFloat = 0
    @State private var safeBottom: CGFloat = 0

    init(exercise: Exercise, draft: Binding<ExerciseLogDraft>,
         onCancel: @escaping () -> Void, onFinish: @escaping () -> Void) {
        self.exercise = exercise
        self._draft = draft
        self.onCancel = onCancel
        self.onFinish = onFinish
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
                    .onTapGesture { completeSet() }
            } else if let imageURL = exercise.imageURL,
                      let uiImage = UIImage(contentsOfFile: imageURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea()
                    .onTapGesture { completeSet() }
            } else {
                Color.black
                    .ignoresSafeArea()
                    .onTapGesture { completeSet() }
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
            .allowsHitTesting(false)

            // Layer 3: Floating controls
            VStack(alignment: .leading) {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                    Button(action: onFinish) {
                        Text("Finish")
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, safeTop + 8)

                Spacer()

                VStack(alignment: .center, spacing: 12) {
                    Text(exercise.name)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("\(exercise.reps) reps per set")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    if !exercise.notes.isEmpty {
                        Text(exercise.notes)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(2)
                    }
                    SetDotsView(total: draft.targetSets, completed: draft.completedSets)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, safeBottom + 8)
            }
        }
        .onAppear {
            if let w = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first?.keyWindow {
                safeTop = w.safeAreaInsets.top
                safeBottom = w.safeAreaInsets.bottom
            }
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
    }

    private func completeSet() {
        guard draft.completedSets < draft.targetSets else { return }
        draft.completedSets += 1
    }
}

// MARK: - SetDotsView

private struct SetDotsView: View {
    let total: Int
    let completed: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                ZStack {
                    if i < completed {
                        Circle()
                            .fill(Color.green)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    }
                }
                .frame(width: 28, height: 28)
            }
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
