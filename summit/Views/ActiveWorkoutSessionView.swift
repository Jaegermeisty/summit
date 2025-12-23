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
                                .foregroundStyle(Color.summitText)

                            Text(plan.name)
                                .font(.subheadline)
                                .foregroundStyle(Color.summitTextSecondary)

                            if let notes = workout.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(Color.summitTextTertiary)
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
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                        }
                        .background(Color.summitSuccess)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Active Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.summitBackground, for: .navigationBar)
            .background(Color.summitBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.summitTextSecondary)
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
            let suggestedWeight = lastLog?.weights.first ?? exercise.targetWeight

            // Initialize sets with suggested weight from last session or template
            let sets: [SetData] = (0..<exercise.numberOfSets).map { index in
                let weight = (index < (lastLog?.weights.count ?? 0)) ? lastLog!.weights[index] : suggestedWeight
                return SetData(weight: weight, reps: nil)
            }

            return ExerciseState(
                exercise: exercise,
                sets: sets
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
            let completedWeights = state.sets.compactMap { $0.weight }
            let completedReps = state.sets.compactMap { $0.reps }
            guard !completedReps.isEmpty, !completedWeights.isEmpty else { continue }

            let log = ExerciseLog(
                exerciseName: state.exercise.name,
                weights: completedWeights,
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
    var sets: [SetData]

    var isCompleted: Bool {
        sets.allSatisfy { $0.reps != nil && $0.weight != nil }
    }
}

struct SetData {
    var weight: Double?
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
                        .foregroundStyle(Color.summitText)

                    Spacer()

                    if state.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.summitSuccess)
                    }
                }

                HStack(spacing: 12) {
                    Label("Target: \(state.exercise.targetRepsMin)-\(state.exercise.targetRepsMax) reps", systemImage: "target")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextSecondary)

                    Label("\(state.exercise.numberOfSets) sets", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextSecondary)
                }

                if let lastLog = lastSession {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundStyle(Color.summitOrange)

                        let setsInfo = zip(lastLog.weights, lastLog.reps).map { "\(Int($0))kg×\($1)" }.joined(separator: ", ")
                        Text("Last: \(setsInfo)")
                            .font(.caption)
                            .foregroundStyle(Color.summitTextTertiary)
                    }
                }

                if let notes = state.exercise.notes, !notes.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(Color.summitOrange)

                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(Color.summitTextSecondary)
                    }
                }
            }

            // Sets with weight per set
            VStack(spacing: 12) {
                ForEach(state.sets.indices, id: \.self) { index in
                    HStack(spacing: 8) {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.summitTextSecondary)
                            .frame(width: 50, alignment: .leading)

                        TextField("kg", value: $state.sets[index].weight, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)

                        Text("×")
                            .foregroundStyle(Color.summitTextTertiary)

                        TextField("reps", value: $state.sets[index].reps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .multilineTextAlignment(.center)
                            .focused($focusedSetIndex, equals: index)

                        Spacer()

                        if state.sets[index].weight != nil && state.sets[index].reps != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.summitSuccess)
                                .font(.caption)
                        }
                    }
                }

                // Add/Remove set buttons
                HStack(spacing: 16) {
                    Button {
                        let lastWeight = state.sets.last?.weight ?? state.exercise.targetWeight
                        state.sets.append(SetData(weight: lastWeight, reps: nil))
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                            .font(.caption)
                            .foregroundStyle(Color.summitOrange)
                    }

                    if state.sets.count > 1 {
                        Button {
                            state.sets.removeLast()
                        } label: {
                            Label("Remove Set", systemImage: "minus.circle")
                                .font(.caption)
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.summitCard)
        )
    }
}

// MARK: - Progress Bar

struct GradientProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .padding(.horizontal, 16)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.orange)
                    .frame(width: max(0, (geometry.size.width - 32) * progress))
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}

#Preview {
    ActiveWorkoutSessionView(
        workout: {
            let workout = Workout(name: "Push Day", orderIndex: 0)

            _ = Exercise(
                name: "Bench Press",
                targetWeight: 60.0,
                targetRepsMin: 6,
                targetRepsMax: 8,
                numberOfSets: 3,
                notes: "Pause at bottom",
                orderIndex: 0,
                workout: workout
            )

            _ = Exercise(
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
