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
    @Bindable var plan: WorkoutPlan
    @Query private var workouts: [Workout]

    @State private var showingCreateWorkout = false
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false

    init(plan: WorkoutPlan) {
        _plan = Bindable(wrappedValue: plan)
        let planId = plan.id
        _workouts = Query(
            filter: #Predicate<Workout> { workout in
                workout.workoutPlan?.id == planId
            },
            sort: \Workout.orderIndex,
            order: .forward
        )
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
                if workouts.isEmpty {
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
                    ForEach(workouts) { workout in
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
                if !workouts.isEmpty {
                    Text("Swipe left on a workout to delete it")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.summitBackground)
        .navigationTitle(plan.name)
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
        guard let index = offsets.first else { return }
        workoutToDelete = workouts[index]
        showingDeleteConfirmation = true
    }

    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)

        let remaining = workouts.filter { $0.id != workout.id }
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
    @Bindable var workout: Workout
    @Query private var exercises: [Exercise]

    init(workout: Workout) {
        _workout = Bindable(wrappedValue: workout)
        let workoutId = workout.id
        _exercises = Query(
            filter: #Predicate<Exercise> { exercise in
                exercise.workout?.id == workoutId
            }
        )
    }

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

                    Text("\(exercises.count) exercise\(exercises.count == 1 ? "" : "s")")
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

            let pushDay = Workout(name: "Push Day", orderIndex: 0, workoutPlan: plan)
            let pullDay = Workout(name: "Pull Day", orderIndex: 1, workoutPlan: plan)
            let legDay = Workout(name: "Leg Day", orderIndex: 2, workoutPlan: plan)

            _ = pushDay
            _ = pullDay
            _ = legDay

            return plan
        }())
    }
    .modelContainer(ModelContainer.preview)
}
