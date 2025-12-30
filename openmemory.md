# GymLog - OpenMemory Guide

## Overview
GymLog is an iOS workout tracking app built with SwiftUI and SwiftData for local persistence, with Convex as the backend for cloud sync and multi-device support.

## Architecture

### Frontend (iOS)
- **Framework**: SwiftUI with iOS 17+
- **Local Storage**: SwiftData for offline-first persistence
- **Cloud Backend**: Convex via `ConvexMobile` Swift package
- **Theme**: Dark gym-inspired aesthetic (Orange #FF6B35, Cyan #00D9FF, Yellow #FFE66D)

### Backend (Convex)
- **Deployment**: `https://marvelous-cow-733.convex.cloud`
- **Dashboard**: `https://dashboard.convex.dev/d/marvelous-cow-733`

## User Defined Namespaces
- [Leave blank - user populates]

## Components

### Convex Schema (`convex/schema.ts`)
- **exercises**: Exercise library/templates with name, muscleGroup, exerciseType (resistance/calisthenics/cardio)
- **sets**: Individual workout sets with weight, reps, workTime, duration (cardio), notes, API key association
- **apiKeys**: Authentication tokens for multi-user support (hashed storage)

### Convex Functions
- **`convex/exercises.ts`**: getExercises, searchExercises, createExercise, seedExercises (internal)
- **`convex/sets.ts`**: createSet, updateSet, deleteSet, getSetsByDay, getDayWorkTime, getDayStatsByType, getExerciseHistory
- **`convex/apiKeys.ts`**: createApiKey (internal), validateApiKey (internal), touchApiKey, deactivateApiKey

### Swift Models (`GymLog/Models/`)
- **Models.swift**: Workout, Exercise, ExerciseSet, WorkoutTemplate, ExerciseHistory (SwiftData models)
- **ExerciseTemplates.swift**: Static exercise library with defaults

### Swift Services (`GymLog/Services/`)
- **ConvexService.swift**: Singleton service for Convex backend communication
- **ExerciseProgressionService.swift**: Logic for tracking exercise progression
- **TemplateSeederService.swift**: Seeds default workout templates

### Swift Views (`GymLog/Views/`)
- HomeView, WorkoutView, HistoryView, StatsView (main tabs)
- ExerciseLibraryView, ExercisePickerSheet
- WorkoutDetailView, DayDetailView
- TemplateLibraryView, TemplateDetailView, TemplateEditorView
- CardioTimerView, InlineExerciseCard, InlineSetRow

## Key Patterns

### Exercise Types
- **resistance**: Weight + reps based (bench press, curls)
- **calisthenics**: Bodyweight exercises (pull-ups, push-ups)
- **cardio**: Duration-based (treadmill, bike)

### API Key Authentication
- API keys generated server-side with `gym_` prefix
- Keys hashed before storage (never store raw)
- Each set linked to an API key for user isolation

### Day-Based Querying
- Sets queried by creation timestamp range
- Stats aggregated: total work time, volume, reps by type

## Setup Instructions

### Add Convex Swift Package to Xcode
1. Open `GymLog.xcodeproj` in Xcode
2. File → Add Package Dependencies
3. Enter: `https://github.com/get-convex/convex-swift`
4. Select `ConvexMobile` product

### Seed Exercise Library
Run in terminal:
```bash
npx convex run exercises:seedExercises
```

### Create API Key (for testing)
Run in terminal:
```bash
npx convex run apiKeys:createApiKey '{"name": "My iPhone"}'
```
Save the returned `apiKey` value - it's only shown once!
