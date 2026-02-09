//
//  WorkoutDetailView.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var workout: Workout
    @Query private var exercises: [Exercise]

    @State private var showingCreateExercise = false
    @State private var editingExercise: Exercise?
    @State private var selectedSession: WorkoutSession?

    init(workout: Workout) {
        _workout = Bindable(wrappedValue: workout)
        let workoutId = workout.id
        _exercises = Query(
            filter: #Predicate<Exercise> { exercise in
                exercise.workoutId == workoutId
            },
            sort: \Exercise.orderIndex,
            order: .forward
        )
    }

    var body: some View {
        List {
            if let notes = workout.notes, !notes.isEmpty {
                Section {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                } header: {
                    Text("Notes")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)
            }

            Section {
                Button {
                    selectedSession = DataHelpers.startSession(for: workout, in: modelContext)
                } label: {
                    Text("Start Workout")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }

            Section {
                if exercises.isEmpty {
                    ContentUnavailableView {
                        Label("No Exercises", systemImage: "dumbbell")
                            .foregroundStyle(Color.summitText)
                    } description: {
                        Text("Add exercises to this workout to get started")
                            .foregroundStyle(Color.summitTextSecondary)
                    } actions: {
                        Button {
                            showingCreateExercise = true
                        } label: {
                            Text("Add Exercise")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.summitOrange)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(exercises) { exercise in
                        Button {
                            editingExercise = exercise
                        } label: {
                            ExerciseRowView(exercise: exercise)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.summitCard)
                    }
                    .onDelete(perform: deleteExercises)
                }
            } header: {
                Text("Exercises")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
            } footer: {
                if !exercises.isEmpty {
                    Text("Tap to edit • Swipe left to delete")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.summitBackground)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.summitBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Summit")
                    .font(.system(size: 18, weight: .bold))
                    .italic()
                    .foregroundStyle(Color.summitOrange)
                    .fixedSize()
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateExercise = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.summitOrange)
                }
            }
        }
        .sheet(isPresented: $showingCreateExercise) {
            CreateExerciseView(workout: workout)
        }
        .sheet(item: $editingExercise) { exercise in
            EditExerciseView(exercise: exercise)
        }
        .navigationDestination(item: $selectedSession) { session in
            WorkoutSessionView(session: session, workout: workout)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = exercises[index]
            modelContext.delete(exercise)
        }

        let remaining = exercises.enumerated().filter { !offsets.contains($0.offset) }
        for (newIndex, (_, exercise)) in remaining.enumerated() {
            exercise.orderIndex = newIndex
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting exercise: \(error)")
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.headline)
                .foregroundStyle(Color.summitText)

            HStack(spacing: 16) {
                Label("\(Int(exercise.targetWeight))kg", systemImage: "scalemass")
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)

                Label("\(exercise.targetRepsMin)-\(exercise.targetRepsMax) reps", systemImage: "repeat")
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)

                Label("\(exercise.numberOfSets) sets", systemImage: "square.stack.3d.up")
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
            }

            if let notes = exercise.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(Color.summitOrange)

                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.summitTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: {
            let workout = Workout(name: "Push Day", orderIndex: 0)

            let benchDefinition = ExerciseDefinition(name: "Bench Press")
            let shoulderDefinition = ExerciseDefinition(name: "Shoulder Press")

            let bench = Exercise(
                definition: benchDefinition,
                targetWeight: 60.0,
                targetRepsMin: 6,
                targetRepsMax: 8,
                numberOfSets: 3,
                notes: "Pause at bottom",
                orderIndex: 0,
                workout: workout
            )

            let shoulder = Exercise(
                definition: shoulderDefinition,
                targetWeight: 40.0,
                targetRepsMin: 8,
                targetRepsMax: 10,
                numberOfSets: 3,
                orderIndex: 1,
                workout: workout
            )

            _ = bench
            _ = shoulder

            return workout
        }())
    }
    .modelContainer(ModelContainer.preview)
}
