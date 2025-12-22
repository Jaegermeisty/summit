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
    
    var sortedExercises: [Exercise] {
        workout.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
    }
    
    var body: some View {
        List {
            Section {
                if sortedExercises.isEmpty {
                    ContentUnavailableView {
                        Label("No Exercises", systemImage: "dumbbell")
                    } description: {
                        Text("Add exercises to this workout to get started")
                    }
                } else {
                    ForEach(sortedExercises) { exercise in
                        ExerciseRowView(exercise: exercise)
                    }
                }
            } header: {
                Text("Exercises")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // TODO: Add exercise
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.headline)
            
            HStack(spacing: 16) {
                Label("\(Int(exercise.targetWeight))kg", systemImage: "scalemass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Label("\(exercise.targetRepsMin)-\(exercise.targetRepsMax) reps", systemImage: "repeat")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Label("\(exercise.numberOfSets) sets", systemImage: "square.stack.3d.up")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let notes = exercise.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
        }())
    }
    .modelContainer(ModelContainer.preview)
}
