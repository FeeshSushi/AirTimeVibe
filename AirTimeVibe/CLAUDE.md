# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an Xcode project. There are no CLI build scripts — use Xcode directly:

- **Run**: `Cmd+R` in Xcode (targets iOS Simulator or physical device)
- **Build only**: `Cmd+B`
- **Tests**: `Cmd+U` (no tests currently exist in the project)
- **Minimum requirements**: Xcode 15+, iOS 17.0 deployment target, Swift 5.9+

Physical device setup: trust the developer certificate in iOS Settings → General → VPN & Device Management.

## Architecture

SwiftUI app using **SwiftData** for persistence (no Core Data, no networking). The pattern is views-directly-with-models (no ViewModel layer) — `@Query` in views fetches data reactively, `@Environment(\.modelContext)` handles writes.

### Data Model Relationships

```
Routine  →(cascade)→  [Exercise]
WorkoutSession  →(cascade)→  [ExerciseLog]  →(embedded)→  [SetEntry]
```

`WorkoutSession` denormalizes `routineName` as a String so history remains intact if a routine is deleted.

### State Management Pattern

`ActiveWorkoutView` uses draft structs (`SetEntryDraft`, `ExerciseLogDraft`) for in-memory set tracking during a live workout. Nothing is persisted until the user taps "Finish" — at that point drafts are committed to `WorkoutSession` + `ExerciseLog` + `SetEntry`.

### Video Storage

Videos are stored as `.mp4` files in the app's Documents directory. The `Exercise` model stores only the filename (`videoFileName`); the full URL is resolved via a computed property. When a user picks a video from the photo library (via `PHPickerViewController`), the temporary URL is copied to Documents. Trim points (`trimStart`, `trimEnd` as `Double` seconds) are stored on the model; actual trimming is done on-demand by `VideoExporter` using `AVAssetExportSession`.

### Navigation Structure

- `TabView` root: Routines tab | History tab
- `NavigationStack` for drill-down within Routines
- `.sheet` for modals (Add Routine, Exercise Editor, Video Picker/Trimmer)
- `.fullScreenCover` for `ActiveWorkoutView` (live workout)

## Required Info.plist Key

`NSPhotoLibraryUsageDescription` must be present for video picking to work.
