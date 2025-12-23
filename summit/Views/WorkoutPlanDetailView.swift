//
//  WorkoutPlanDetailView.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct WorkoutPlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let plan: WorkoutPlan

    @State private var showingCreateWorkout = false
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false

    var sortedWorkouts: [Workout] {
        plan.workouts.sorted(by: { $0.orderIndex < $1.orderIndex })
    }
    
    var body: some View {
        List {
            if let description = plan.planDescription {
                Section {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)
            }

            Section {
                if sortedWorkouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Workouts", systemImage: "figure.strengthtraining.traditional")
                            .foregroundStyle(Color.summitText)
                    } description: {
                        Text("Add your first workout to get started")
                            .foregroundStyle(Color.summitTextSecondary)
                    } actions: {
                        Button {
                            showingCreateWorkout = true
                        } label: {
                            Text("Add Workout")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.summitOrange)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedWorkouts) { workout in
                        NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                            WorkoutRowView(workout: workout)
                        }
                        .listRowBackground(Color.summitCard)
                    }
                    .onDelete(perform: deleteWorkouts)
                }
            } header: {
                Text("Workouts")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
            } footer: {
                if !sortedWorkouts.isEmpty {
                    Text("Swipe left on a workout to delete it")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.summitBackground)
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.summitBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Summit")
                    .font(.title3)
                    .italic()
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.summitOrange)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateWorkout = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.summitOrange)
                }
            }
        }
        .sheet(isPresented: $showingCreateWorkout) {
            CreateWorkoutView(workoutPlan: plan)
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation, presenting: workoutToDelete) { workout in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout(workout)
            }
        } message: { workout in
            Text("Are you sure you want to delete '\(workout.name)'? All exercises in this workout will be permanently deleted. This cannot be undone.")
        }
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            let workout = sortedWorkouts[index]
            workoutToDelete = workout
            showingDeleteConfirmation = true
        }
    }

    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)

        // Reorder remaining workouts
        let remaining = sortedWorkouts.filter { $0.id != workout.id }
        for (newIndex, workout) in remaining.enumerated() {
            workout.orderIndex = newIndex
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }
}

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Day \(workout.orderIndex + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.summitOrange)
                        )

                    Text(workout.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.summitText)
                }

                HStack(spacing: 4) {
                    Image(systemName: "dumbbell")
                        .font(.caption2)

                    Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundStyle(Color.summitTextSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        WorkoutPlanDetailView(plan: {
            let plan = WorkoutPlan(
                name: "Push Pull Legs",
                planDescription: "Classic 3-day split"
            )

            _ = Workout(name: "Push Day", orderIndex: 0, workoutPlan: plan)
            _ = Workout(name: "Pull Day", orderIndex: 1, workoutPlan: plan)
            _ = Workout(name: "Leg Day", orderIndex: 2, workoutPlan: plan)

            return plan
        }())
    }
    .modelContainer(ModelContainer.preview)
}
