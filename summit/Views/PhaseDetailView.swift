//
//  PhaseDetailView.swift
//  Summit
//
//  Created on 2026-02-08
//

import SwiftUI
import SwiftData

struct PhaseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var phase: PlanPhase
    let plan: WorkoutPlan

    @Query private var workouts: [Workout]
    @Query private var allWorkouts: [Workout]
    @Query private var phases: [PlanPhase]

    @State private var showingCreateWorkout = false
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false
    @State private var workoutToMove: Workout?
    @State private var showingMoveDialog = false

    init(phase: PlanPhase, plan: WorkoutPlan) {
        _phase = Bindable(wrappedValue: phase)
        self.plan = plan
        let phaseId = phase.id
        let planId = plan.id
        _workouts = Query(
            filter: #Predicate<Workout> { workout in
                workout.phase?.id == phaseId
            },
            sort: \Workout.orderIndex,
            order: .forward
        )
        _allWorkouts = Query(
            filter: #Predicate<Workout> { workout in
                workout.workoutPlan?.id == planId
            }
        )
        _phases = Query(
            filter: #Predicate<PlanPhase> { item in
                item.workoutPlan?.id == planId
            },
            sort: \PlanPhase.orderIndex,
            order: .forward
        )
    }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(phase.name)
                            .font(.headline)
                            .foregroundStyle(Color.summitText)

                        Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Color.summitTextSecondary)
                    }

                    Spacer()

                    if phase.isActive {
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.summitOrange)
                            )
                    } else {
                        Button("Set Active") {
                            setActivePhase()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .tint(Color.summitOrange)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.summitCard)

            Section {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Workouts", systemImage: "figure.strengthtraining.traditional")
                            .foregroundStyle(Color.summitText)
                    } description: {
                        Text("Add your first workout to \(phase.name)")
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
                        .contextMenu {
                            if phases.count > 1 {
                                Button {
                                    workoutToMove = workout
                                    showingMoveDialog = true
                                } label: {
                                    Label("Move to Phase", systemImage: "arrow.right")
                                }
                            }
                        }
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
        .navigationTitle(phase.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.summitBackground, for: .navigationBar)
        .toolbar {
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
            CreateWorkoutView(workoutPlan: plan, preselectedPhaseId: phase.id)
        }
        .confirmationDialog("Move Workout", isPresented: $showingMoveDialog, presenting: workoutToMove) { workout in
            ForEach(phases.filter { $0.id != phase.id }) { target in
                Button("Move to \(target.name)") {
                    moveWorkout(workout, to: target)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { workout in
            Text("Choose a phase for '\(workout.name)'.")
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
        guard let index = offsets.first, workouts.indices.contains(index) else { return }
        workoutToDelete = workouts[index]
        showingDeleteConfirmation = true
    }

    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
        reindexWorkouts()

        do {
            try modelContext.save()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }

    private func moveWorkout(_ workout: Workout, to targetPhase: PlanPhase) {
        guard workout.phase?.id != targetPhase.id else { return }

        let targetCount = workoutsForPhase(targetPhase).count
        workout.phase = targetPhase
        workout.orderIndex = targetCount

        reindexWorkouts()

        do {
            try modelContext.save()
        } catch {
            print("Error moving workout: \(error)")
        }
    }

    private func workoutsForPhase(_ targetPhase: PlanPhase) -> [Workout] {
        allWorkouts
            .filter { $0.phase?.id == targetPhase.id }
            .sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private func reindexWorkouts() {
        for (index, workout) in workouts.enumerated() {
            workout.orderIndex = index
        }
    }

    private func setActivePhase() {
        for item in phases {
            item.isActive = (item.id == phase.id)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error setting active phase: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        PhaseDetailView(phase: PlanPhase(name: "Phase 1"), plan: WorkoutPlan(name: "Push Pull Legs"))
            .modelContainer(ModelContainer.preview)
    }
}
