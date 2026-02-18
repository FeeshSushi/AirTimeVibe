# AirTimeVibe – Xcode Setup Guide

## Requirements
- Xcode 15+
- iOS 17+ deployment target
- Swift 5.9+

---

## 1. Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - **Product Name:** `AirTimeVibe`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None (we use SwiftData manually)
4. Save the project **into** this `AirTimeVibe/` folder

---

## 2. Add the Source Files

After Xcode creates the project, it will generate a default `ContentView.swift` and an app entry file.

**Delete** the auto-generated files and add all the files from this folder instead:

### In Xcode's Project Navigator:
- Right-click the project group → **Add Files to "AirTimeVibe"**
- Select all `.swift` files from:
  - `Models/`
  - `Views/Routines/`
  - `Views/Exercise/`
  - `Views/Workout/`
  - `Views/History/`
  - `Utilities/`
  - Root: `AirTimeVibeApp.swift`, `ContentView.swift`

> Tip: You can add the whole folder structure at once — Xcode will include subfolders as groups.

---

## 3. Configure Info.plist

The app needs permission to access the Photos library for video picking.

In Xcode, select your project → **Info** tab → add these keys:

| Key | Value |
|-----|-------|
| `NSPhotoLibraryUsageDescription` | `AirTimeVibe needs access to your photo library to attach workout videos.` |

---

## 4. Set Deployment Target

- Select the project target → **General**
- Set **Minimum Deployments** to **iOS 17.0**

---

## 5. Build & Run

- Select a simulator or your physical device
- Press **⌘R** to build and run
- On first run on a physical device, trust your developer certificate in **Settings → General → VPN & Device Management**

---

## File Structure

```
AirTimeVibe/
├── AirTimeVibeApp.swift         # App entry point + SwiftData container
├── ContentView.swift            # Tab bar (Routines / History)
├── Models/
│   ├── Routine.swift            # @Model: name, ordered exercises
│   ├── Exercise.swift           # @Model: name, sets, reps, notes, video
│   ├── WorkoutSession.swift     # @Model: logged workout session
│   └── ExerciseLog.swift        # @Model: per-exercise log + SetEntry struct
├── Views/
│   ├── Routines/
│   │   ├── RoutinesView.swift       # List of all routines
│   │   ├── RoutineDetailView.swift  # Exercises in a routine + Start Workout
│   │   └── AddRoutineView.swift     # Create new routine sheet
│   ├── Exercise/
│   │   ├── ExerciseEditorView.swift # Add / edit exercise (shared)
│   │   ├── VideoPickerView.swift    # PHPicker wrapper
│   │   └── VideoTrimmerView.swift   # In-app trim UI with drag handles
│   ├── Workout/
│   │   └── ActiveWorkoutView.swift  # Step-through workout + set logging
│   └── History/
│       ├── HistoryView.swift        # Past sessions list
│       └── SessionDetailView.swift  # Session breakdown
└── Utilities/
    └── VideoExporter.swift      # AVAssetExportSession trim helper
```

---

## Notes

- **Videos** are stored as `.mp4` files in the app's Documents directory. They persist across launches.
- **Trimming** exports a new clipped copy — the original is not modified.
- **All data** is local. No network access or accounts required.
