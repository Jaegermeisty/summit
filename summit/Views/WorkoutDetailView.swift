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
    let workout: Workout

    @State private var showingCreateExercise = false
    @State private var editingExercise: Exercise?

    var sortedExercises: [Exercise] {
        workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    var body: some View {
        List {
            // Workout notes section if they exist
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
                if sortedExercises.isEmpty {
                    ContentUnavailableView {
                        Label("No Exercises", systemImage: "dumbbell")
                    } description: {
                        Text("Add exercises to this workout to get started")
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
                    ForEach(sortedExercises) { exercise in
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
                if !sortedExercises.isEmpty {
                    Text("Tap to edit • Swipe left to delete")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.summitBackground)
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.summitBackground, for: .navigationBar)
        .toolbar {
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
    }

    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = sortedExercises[index]
            modelContext.delete(exercise)
        }

        // Reorder remaining exercises
        let remaining = sortedExercises.enumerated().filter { !offsets.contains($0.offset) }
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
        }())
    }
    .modelContainer(ModelContainer.preview)
}
