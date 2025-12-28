# GymLog - iOS Workout Tracker

A modern, feature-rich iOS app for logging gym workouts built with SwiftUI and SwiftData. Track your strength training and cardio exercises with precision, analyze your progress, and repeat your favorite workouts.

## Features

### 🏋️ Workout Logging
- **Start and track workouts** with real-time duration timer (capped at 2 hours)
- **Add exercises on the fly** from a comprehensive library or create custom exercises
- **Track sets, reps, and weight** for strength exercises
- **Work time tracking** - measure actual time spent executing each set with play/pause timers
- **Cardio exercises** - dedicated timer with play/pause and manual entry for minutes
- **Smart defaults** - automatically suggests last used weight/reps or template defaults for a 90kg male
- **Bodyweight exercises** - clean display (just shows reps unless weight is added)
- **Set management** - expandable/collapsible set rows with quick +/- buttons for weight and reps
- **Mark sets as completed** with visual indicators
- **Add notes** to workouts for personal records

### 📊 Exercise Library
- **70+ pre-loaded exercises** across 9 muscle groups
- **Muscle groups**: Chest, Back, Shoulders, Biceps, Triceps, Legs, Core, Cardio, Full Body
- **Search functionality** - find exercises quickly or create custom ones on the spot
- **Default weights** - intelligent defaults for each exercise based on a 90kg male in decent shape
- **Exercise history** - automatically tracks your last used weight and reps per exercise

### 🔄 Repeat Workout
- **Duplicate any past workout** with one tap
- **Step through exercises** from top to bottom
- **Change active set** and reorder exercises as needed
- **Work time reset** - new workout starts fresh (no carried-over work times)
- **Performance comparison** - see side-by-side comparison of new vs. old workout
  - Compare weight, reps, sets, and work time
  - Visual indicators for improvements or declines
  - Exercise-by-exercise breakdown

### 📈 Statistics & Progress
- **Comprehensive stats** - weekly, monthly, yearly, and all-time tracking
- **Total metrics**: workouts completed, time spent, volume lifted, sets performed
- **Work time vs. duration** - distinguish between total workout time and actual work time
- **Muscle group breakdown** - see which areas you're focusing on
- **Personal records** - track your best sets and progress over time

### 📜 History
- **View all past workouts** with detailed breakdowns
- **Search and filter** by time period
- **Workout details** - see all sets, weights, reps, and work times
- **Edit completed workouts** - make corrections or additions
- **Delete workouts** - remove unwanted entries
- **Repeat workouts** - easily duplicate and compare

### 🎨 Design
Modern, dark gym-inspired aesthetic:
- **Primary Color**: Vibrant orange (#FF6B35)
- **Secondary Color**: Electric cyan (#00D9FF)
- **Accent Color**: Golden yellow (#FFE66D)
- Dark backgrounds with elevated surfaces
- Rounded, modern typography
- Smooth animations and transitions
- Intuitive, gesture-friendly interface

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**

## Getting Started

1. Open `GymLog/GymLog.xcodeproj` in Xcode
2. Select your target device (iPhone simulator or physical device)
3. Press `Cmd + R` to build and run

### Deploying to Your iPhone

1. Connect your iPhone via USB
2. In Xcode, select your device from the device menu
3. Go to **Signing & Capabilities** in the project settings
4. Select your Apple Developer team (or use your personal team for development)
5. Build and run (`Cmd + R`)

## Project Structure

```
GymLog/
├── GymLog.xcodeproj/              # Xcode project configuration
└── GymLog/
    ├── GymLogApp.swift            # App entry point with SwiftData setup
    ├── ContentView.swift          # Main tab view (Home, History, Exercises, Stats)
    ├── Models/
    │   ├── Models.swift           # SwiftData models:
    │   │                          #   - Workout (with duration, work time, repeat tracking)
    │   │                          #   - Exercise (with cardio duration support)
    │   │                          #   - ExerciseSet (with work time tracking)
    │   │                          #   - WorkoutTemplate, TemplateExercise
    │   │                          #   - ExerciseHistory, HistoricalSet
    │   └── ExerciseTemplates.swift # Exercise library with default weights
    ├── Views/
    │   ├── HomeView.swift         # Dashboard with quick stats and active workout
    │   ├── WorkoutView.swift      # Active workout logging with timers
    │   │                          #   - Set row expansion/collapse
    │   │                          #   - Work time timers per set
    │   │                          #   - Cardio exercise timers
    │   │                          #   - Workout comparison view
    │   ├── HistoryView.swift      # Past workouts list
    │   ├── ExerciseLibraryView.swift # Browse exercises
    │   ├── WorkoutDetailView.swift   # Workout details and repeat functionality
    │   └── StatsView.swift        # Statistics and charts
    ├── Theme/
    │   ├── Theme.swift            # Colors, typography, styling
    │   └── Components.swift      # Reusable UI components
    └── Assets.xcassets/           # App icon and color assets
```

## Key Features Explained

### Work Time Tracking
Each strength exercise set has its own play/pause timer. This measures the actual time you spend executing the set (not rest time). The total work time is summed across all sets and displayed separately from the overall workout duration.

### Cardio Exercises
Cardio exercises use a different interface:
- Large timer display with seconds incrementing
- Play/pause button to track time
- Manual entry option for minutes
- No sets/reps - just duration tracking

### Smart Weight Defaults
When adding an exercise:
1. **First priority**: Last weight used for that exercise in your most recent workout
2. **Second priority**: Template default weight (based on 90kg male standards)
3. **Fallback**: 0 lbs (for custom exercises or bodyweight)

### Bodyweight Exercises
Exercises like pull-ups, push-ups, and dips display cleanly:
- Shows just "12 reps" instead of "0 lbs × 12 reps"
- Weight field available if you add weight (e.g., weighted pull-ups)
- Automatically detects bodyweight vs. weighted exercises

### Repeat Workout Flow
1. Open any completed workout from history
2. Tap "Repeat This Workout"
3. New workout is created with all exercises and sets
4. Work times are reset (fresh start)
5. Complete the workout
6. See side-by-side comparison with the original

## Data Persistence

Uses **SwiftData** for local persistence:
- All data saves automatically as you work
- Workouts, exercises, and sets persist between app launches
- Cascade delete relationships (deleting a workout deletes its exercises and sets)
- Schema migration handling for future updates

## Future Enhancements (Potential)

- Apple Health integration for syncing workout data
- Workout templates and programs
- Progress photos
- Social sharing
- Cloud sync across devices
- Advanced analytics and insights

## License

MIT License - Feel free to use and modify!
