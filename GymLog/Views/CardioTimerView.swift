import SwiftUI
import SwiftData

// MARK: - Cardio Timer View
struct CardioTimerView: View {
    @Bindable var exercise: Exercise
    
    @State private var isRunning = false
    @State private var timerStartTime: Date?
    @State private var accumulatedTime: TimeInterval = 0
    
    private func currentTime(at date: Date) -> TimeInterval {
        if let startTime = timerStartTime {
            return accumulatedTime + date.timeIntervalSince(startTime)
        }
        return accumulatedTime
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0, paused: !isRunning)) { timeline in
            VStack(spacing: GymTheme.Spacing.md) {
                // Large timer display
                Text(formatTime(currentTime(at: timeline.date)))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(isRunning ? .gymPrimary : .gymText)
                    .frame(maxWidth: .infinity)
                
                // Control buttons
                HStack(spacing: GymTheme.Spacing.xl) {
                    // Reset button
                    Button {
                        resetTimer()
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(Color.gymSurface)
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.gymTextSecondary)
                            }
                            Text("Reset")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(.gymTextSecondary)
                        }
                    }
                    .disabled(accumulatedTime == 0 && !isRunning)
                    .opacity(accumulatedTime == 0 && !isRunning ? 0.5 : 1)
                    
                    // Play/Pause button
                    Button {
                        toggleTimer()
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(isRunning ? Color.gymWarning : Color.gymSuccess)
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text(isRunning ? "Pause" : "Start")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(isRunning ? .gymWarning : .gymSuccess)
                        }
                    }
                    
                    // Done button
                    Button {
                        markComplete()
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(exercise.isCompleted ? Color.gymSuccess : Color.gymSurface)
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: exercise.isCompleted ? "checkmark" : "flag.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(exercise.isCompleted ? .white : .gymSuccess)
                            }
                            Text(exercise.isCompleted ? "Done" : "Finish")
                                .font(GymTheme.Typography.caption)
                                .foregroundColor(.gymSuccess)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GymTheme.Spacing.md)
        }
        .onAppear {
            accumulatedTime = exercise.duration
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            // Pause - save accumulated time
            if let startTime = timerStartTime {
                accumulatedTime += Date().timeIntervalSince(startTime)
            }
            timerStartTime = nil
            isRunning = false
            
            // Save duration
            exercise.duration = accumulatedTime
            
            // Save to Convex
            Task {
                await saveCardioToConvex()
            }
        } else {
            // Play - start timer
            timerStartTime = Date()
            isRunning = true
        }
    }
    
    private func saveCardioToConvex() async {
        guard ConvexAPI.shared.isAuthenticated else {
            print("❌ Not authenticated - skipping Convex save")
            return
        }
        
        let workoutId = exercise.workout?.id.uuidString
        let durationSeconds = Int(exercise.duration) // Convert TimeInterval to Int seconds
        
        do {
            let result = try await ConvexAPI.shared.createSet(
                exerciseName: exercise.name,
                exerciseType: .cardio,
                duration: durationSeconds > 0 ? durationSeconds : nil,
                isCompleted: exercise.isCompleted ? true : nil,
                workoutId: workoutId
            )
            print("✅ Cardio saved to Convex: \(exercise.name), ID: \(result)")
        } catch {
            print("❌ Error saving cardio to Convex: \(error)")
        }
    }
    
    private func resetTimer() {
        isRunning = false
        timerStartTime = nil
        accumulatedTime = 0
        exercise.duration = 0
    }
    
    private func markComplete() {
        // Stop timer if running
        if isRunning {
            if let startTime = timerStartTime {
                accumulatedTime += Date().timeIntervalSince(startTime)
            }
            timerStartTime = nil
            isRunning = false
            exercise.duration = accumulatedTime
        }
        
        exercise.isCompleted.toggle()
        
        // Save to Convex when completed
        if exercise.isCompleted {
            Task {
                await saveCardioToConvex()
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

