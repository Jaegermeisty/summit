//
//  ActiveWorkoutSessionView.swift
//  summit
//
//  Created on 2025-12-22
//

import SwiftUI
import SwiftData

struct ActiveWorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workout: Workout
    let plan: WorkoutPlan

    @State private var exerciseStates: [ExerciseState] = []
    @State private var showingCompleteConfirmation = false

    var sortedExercises: [Exercise] {
        workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    var progress: Double {
        guard !exerciseStates.isEmpty else { return 0 }
        let completedCount = exerciseStates.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(exerciseStates.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                GradientProgressBar(progress: progress)
                    .frame(height: 8)

                ScrollView {
                    VStack(spacing: 20) {
                        // Workout header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(workout.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(plan.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let notes = workout.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // Exercise list
                        ForEach(exerciseStates.indices, id: \.self) { index in
                            ExerciseLogCard(
                                state: $exerciseStates[index],
                                lastSession: DataHelpers.lastSession(
                                    for: exerciseStates[index].exercise.name,
                                    in: modelContext
                                )
                            )
                            .padding(.horizontal)
                        }

                        // Complete workout button
                        Button {
                            showingCompleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Complete Workout", systemImage: "checkmark.circle.fill")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .padding(.horizontal)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Complete Workout?", isPresented: $showingCompleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Complete", role: .destructive) {
                    completeWorkout()
                }
            } message: {
                Text("Are you sure you want to finish this workout? Your progress will be saved.")
            }
        }
        .onAppear {
            initializeExerciseStates()
        }
    }

    private func initializeExerciseStates() {
        exerciseStates = sortedExercises.map { exercise in
            let lastLog = DataHelpers.lastSession(for: exercise.name, in: modelContext)
            let suggestedWeight = lastLog?.weight ?? exercise.targetWeight

            return ExerciseState(
                exercise: exercise,
                weight: suggestedWeight,
                sets: Array(repeating: SetData(reps: nil), count: exercise.numberOfSets)
            )
        }
    }

    private func completeWorkout() {
        // Create workout session
        let session = WorkoutSession(
            workoutTemplateId: workout.id,
            workoutTemplateName: workout.name,
            workoutPlanId: plan.id,
            workoutPlanName: plan.name
        )
        modelContext.insert(session)

        // Create exercise logs
        for (index, state) in exerciseStates.enumerated() {
            let completedReps = state.sets.compactMap { $0.reps }
            guard !completedReps.isEmpty else { continue }

            let log = ExerciseLog(
                exerciseName: state.exercise.name,
                weight: state.weight,
                reps: completedReps,
                orderIndex: index,
                session: session
            )
            modelContext.insert(log)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving workout session: \(error)")
        }
    }
}

// MARK: - Exercise State

struct ExerciseState {
    let exercise: Exercise
    var weight: Double
    var sets: [SetData]

    var isCompleted: Bool {
        sets.allSatisfy { $0.reps != nil }
    }
}

struct SetData {
    var reps: Int?
}

// MARK: - Exercise Log Card

struct ExerciseLogCard: View {
    @Binding var state: ExerciseState
    let lastSession: ExerciseLog?

    @FocusState private var focusedSetIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(state.exercise.name)
                        .font(.headline)

                    Spacer()

                    if state.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 12) {
                    Label("Target: \(state.exercise.targetRepsMin)-\(state.exercise.targetRepsMax) reps", systemImage: "target")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("\(state.exercise.numberOfSets) sets", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let lastLog = lastSession {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundStyle(.orange)

                        Text("Last: \(Int(lastLog.weight))kg × \(lastLog.reps.map(String.init).joined(separator: ", ")) reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let notes = state.exercise.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(.orange)

                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Weight input
            HStack(spacing: 12) {
                Text("Weight (kg)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Weight", value: $state.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)
            }

            // Sets
            VStack(spacing: 12) {
                ForEach(state.sets.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .leading)

                        TextField("Reps", value: $state.sets[index].reps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .multilineTextAlignment(.center)
                            .focused($focusedSetIndex, equals: index)

                        Text("reps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if let reps = state.sets[index].reps {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                }

                // Add/Remove set buttons
                HStack(spacing: 16) {
                    Button {
                        state.sets.append(SetData(reps: nil))
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if state.sets.count > 1 {
                        Button {
                            state.sets.removeLast()
                        } label: {
                            Label("Remove Set", systemImage: "minus.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

// MARK: - Gradient Progress Bar

struct GradientProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                // Progress with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .orange, .green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
    }
}

#Preview {
    ActiveWorkoutSessionView(
        workout: {
            let workout = Workout(name: "Push Day", orderIndex: 0)

            let bench = Exercise(
                name: "Bench Press",
                targetWeight: 60.0,
                targetRepsMin: 6,
                targetRepsMax: 8,
                numberOfSets: 3,
                notes: "Pause at bottom",
                orderIndex: 0,
                workout: workout
            )

            let shoulder = Exercise(
                name: "Shoulder Press",
                targetWeight: 40.0,
                targetRepsMin: 8,
                targetRepsMax: 10,
                numberOfSets: 3,
                orderIndex: 1,
                workout: workout
            )

            return workout
        }(),
        plan: WorkoutPlan(name: "Push Pull Legs")
    )
    .modelContainer(ModelContainer.preview)
}
