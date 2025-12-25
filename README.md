# GymLog - iOS Workout Tracker

A modern, beautiful iOS app for logging gym workouts built with SwiftUI and SwiftData.

## Features

### 🏋️ Workout Logging
- Start empty workouts and add exercises on the fly
- Track sets, reps, and weight for each exercise
- Real-time workout timer
- Mark sets as completed
- Add notes to workouts

### 📊 Exercise Library
- 70+ pre-loaded exercises across 9 muscle groups
- Search and filter exercises
- Organized by muscle group (Chest, Back, Shoulders, Biceps, Triceps, Legs, Core, Cardio, Full Body)
- Primary exercises marked for quick access

### 📈 Statistics & Progress
- Weekly, monthly, yearly, and all-time stats
- Total workouts, time, volume, and sets tracked
- Muscle group breakdown visualization
- Personal records tracking
- Activity charts

### 📜 History
- View all past workouts
- Search and filter by time period
- Detailed workout breakdown
- Edit or delete past workouts

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Open `GymLog/GymLog.xcodeproj` in Xcode
2. Select your target device (iPhone simulator or physical device)
3. Press `Cmd + R` to build and run

## Project Structure

```
GymLog/
├── GymLog.xcodeproj/        # Xcode project configuration
└── GymLog/
    ├── GymLogApp.swift      # App entry point with SwiftData setup
    ├── ContentView.swift    # Main tab view
    ├── Models/
    │   ├── Models.swift           # SwiftData models (Workout, Exercise, ExerciseSet)
    │   └── ExerciseTemplates.swift # Exercise library data
    ├── Views/
    │   ├── HomeView.swift         # Dashboard with quick stats
    │   ├── WorkoutView.swift      # Active workout logging
    │   ├── HistoryView.swift      # Past workouts list
    │   ├── ExerciseLibraryView.swift # Browse exercises
    │   ├── WorkoutDetailView.swift   # Workout details
    │   └── StatsView.swift        # Statistics and charts
    ├── Theme/
    │   ├── Theme.swift            # Colors, typography, styling
    │   └── Components.swift       # Reusable UI components
    └── Assets.xcassets/           # Colors and app icon
```

## Design

The app features a dark, gym-inspired aesthetic with:
- **Primary Color**: Vibrant orange (#FF6B35)
- **Secondary Color**: Electric cyan (#00D9FF)
- **Accent Color**: Golden yellow (#FFE66D)
- Dark backgrounds with elevated surfaces
- Rounded, modern typography
- Smooth animations and haptic feedback

## Data Persistence

Uses SwiftData for local persistence:
- Workouts are saved automatically
- Exercises and sets cascade delete with workouts
- Data persists between app launches

## License

MIT License - Feel free to use and modify!
