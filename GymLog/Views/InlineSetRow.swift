import SwiftUI
import SwiftData

// MARK: - Inline Set Row
struct InlineSetRow: View {
    @Bindable var set: ExerciseSet
    let setNumber: Int
    let isActive: Bool
    let onTap: () -> Void
    let onDone: () -> Void
    let onDelete: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    // Computed property for current work time display
    private func currentWorkTime(at date: Date) -> TimeInterval {
        if let startTime = set.workStartTime {
            return set.workTime + date.timeIntervalSince(startTime)
        }
        return set.workTime
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0, paused: set.workStartTime == nil)) { timeline in
            if isActive {
                // Expanded editing view
                expandedView(at: timeline.date)
            } else {
                // Collapsed display view
                collapsedView(at: timeline.date)
            }
        }
    }
    
    // MARK: - Collapsed View (tap to edit)
    private func collapsedView(at date: Date) -> some View {
        HStack(spacing: GymTheme.Spacing.sm) {
            // Set number badge - tap to mark done
            Button {
                set.isCompleted.toggle()
            } label: {
                ZStack {
                    Circle()
                        .stroke(set.isCompleted ? Color.gymSuccess : Color.gymTextSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if set.isCompleted {
                        Circle()
                            .fill(Color.gymSuccess)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(setNumber)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gymTextSecondary)
                    }
                }
            }
            
            // Weight × Reps display - tap to edit
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if set.weight > 0 {
                            Text("\(Int(set.weight)) lbs")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.gymText)
                            
                            Text("×")
                                .foregroundColor(.gymTextSecondary)
                        }
                        
                        Text("\(set.reps) reps")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gymText)
                    }
                    
                    // Show work time if recorded or running
                    let workTime = currentWorkTime(at: date)
                    if workTime > 0 || set.workStartTime != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text(formatWorkTime(workTime))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(set.workStartTime != nil ? .gymPrimary : .gymTextSecondary)
                    }
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.vertical, GymTheme.Spacing.sm)
                .background(Color.gymBackground)
                .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
            }
            
            Spacer()
            
            // Work time timer button (compact) - on right side
            Button {
                toggleWorkTimer()
            } label: {
                ZStack {
                    Circle()
                        .fill(set.workStartTime != nil ? Color.gymPrimary : Color.gymSurface)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: set.workStartTime != nil ? "stop.fill" : "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(set.workStartTime != nil ? .white : .gymPrimary)
                }
            }
        }
        .padding(.vertical, GymTheme.Spacing.xs)
    }
    
    // MARK: - Expanded View (with +/- buttons)
    private func expandedView(at date: Date) -> some View {
        VStack(spacing: GymTheme.Spacing.sm) {
            // Header with set number and done button
            HStack {
                HStack(spacing: GymTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.gymPrimary)
                            .frame(width: 28, height: 28)
                        
                        Text("\(setNumber)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Set \(setNumber)")
                        .font(GymTheme.Typography.headline)
                        .foregroundColor(.gymText)
                }
                
                Spacer()
                
                // Mark complete toggle
                Button {
                    set.isCompleted.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(set.isCompleted ? .gymSuccess : .gymTextSecondary)
                        Text(set.isCompleted ? "Done" : "Mark Done")
                            .font(GymTheme.Typography.caption)
                            .foregroundColor(set.isCompleted ? .gymSuccess : .gymTextSecondary)
                    }
                }
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.gymError.opacity(0.7))
                }
            }
            
            // Work Time Timer Row
            HStack(spacing: GymTheme.Spacing.md) {
                // Play/Stop button
                Button {
                    toggleWorkTimer()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: set.workStartTime != nil ? "stop.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text(set.workStartTime != nil ? "Stop" : "Start")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(set.workStartTime != nil ? Color.gymWarning : Color.gymSuccess)
                    .clipShape(Capsule())
                }
                
                // Work time display
                VStack(alignment: .leading, spacing: 2) {
                    Text("Work Time")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gymTextSecondary)
                    
                    Text(formatWorkTime(currentWorkTime(at: date)))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(set.workStartTime != nil ? .gymPrimary : .gymText)
                }
                
                Spacer()
                
                // Reset button
                if set.workTime > 0 || set.workStartTime != nil {
                    Button {
                        resetWorkTimer()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.gymTextSecondary)
                    }
                }
            }
            .padding(GymTheme.Spacing.sm)
            .background(Color.gymSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
            
            // Weight row with +/- buttons
            HStack(spacing: GymTheme.Spacing.sm) {
                Button {
                    adjustWeight(-5)
                } label: {
                    Text("-5")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.gymPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                HStack(spacing: 4) {
                    TextField("0", text: $weightText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.gymText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .onChange(of: weightText) { _, newValue in
                            if let weight = Double(newValue) {
                                set.weight = weight
                            }
                        }
                    
                    Text("lbs")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gymTextSecondary)
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.vertical, GymTheme.Spacing.sm)
                .background(Color.gymSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    adjustWeight(5)
                } label: {
                    Text("+5")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gymPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.gymPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Reps row with +/- buttons
            HStack(spacing: GymTheme.Spacing.sm) {
                Button {
                    adjustReps(-1)
                } label: {
                    Text("-1")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gymSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.gymSecondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                HStack(spacing: 4) {
                    TextField("0", text: $repsText)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.gymText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .onChange(of: repsText) { _, newValue in
                            if let reps = Int(newValue) {
                                set.reps = reps
                            }
                        }
                    
                    Text("reps")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gymTextSecondary)
                }
                .padding(.horizontal, GymTheme.Spacing.md)
                .padding(.vertical, GymTheme.Spacing.sm)
                .background(Color.gymSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    adjustReps(1)
                } label: {
                    Text("+1")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gymSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.gymSecondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Done editing button
            Button {
                onDone()
            } label: {
                Text("Done Editing")
                    .font(GymTheme.Typography.subheadline)
                    .foregroundColor(.gymPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, GymTheme.Spacing.sm)
                    .background(Color.gymPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.small))
            }
        }
        .padding(GymTheme.Spacing.md)
        .background(Color.gymBackground)
        .clipShape(RoundedRectangle(cornerRadius: GymTheme.Radius.medium))
        .onAppear {
            weightText = set.weight > 0 ? String(format: "%.0f", set.weight) : ""
            repsText = set.reps > 0 ? "\(set.reps)" : ""
        }
    }
    
    private func toggleWorkTimer() {
        if set.workStartTime != nil {
            // Stop timer - accumulate time
            set.workTime += Date().timeIntervalSince(set.workStartTime!)
            set.workStartTime = nil
        } else {
            // Start timer
            set.workStartTime = Date()
        }
    }
    
    private func resetWorkTimer() {
        if set.workStartTime != nil {
            set.workStartTime = nil
        }
        set.workTime = 0
    }
    
    private func formatWorkTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func adjustWeight(_ delta: Double) {
        set.weight = max(0, set.weight + delta)
        weightText = String(format: "%.0f", set.weight)
    }
    
    private func adjustReps(_ delta: Int) {
        set.reps = max(0, set.reps + delta)
        repsText = "\(set.reps)"
    }
}

