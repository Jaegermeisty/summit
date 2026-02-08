//
//  WorkoutPlanDetailView.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

private enum PhasePromptMode {
    case enable
    case add
}

struct WorkoutPlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var plan: WorkoutPlan
    @Query private var workouts: [Workout]
    @Query private var phases: [PlanPhase]

    @State private var showingCreateWorkout = false
    @State private var createWorkoutPhaseId: UUID?
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false
    @State private var showingPhasePrompt = false
    @State private var phasePromptMode: PhasePromptMode = .enable
    @State private var phaseNameInput: String = ""
    @State private var phaseToDelete: PlanPhase?
    @State private var showingDeletePhaseConfirmation = false

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
        _phases = Query(
            filter: #Predicate<PlanPhase> { phase in
                phase.workoutPlan?.id == planId
            },
            sort: \PlanPhase.orderIndex,
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
                if phases.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Organize your plan into phases (blocks). Workouts can’t live outside phases once enabled.")
                            .font(.subheadline)
                            .foregroundStyle(Color.summitTextSecondary)

                        Button {
                            showPhasePrompt(.enable)
                        } label: {
                            Text("Enable Phases")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.summitOrange)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.summitCard)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap a phase to see its workouts.")
                            .font(.caption)
                            .foregroundStyle(Color.summitTextTertiary)

                        Text("Active phase controls the next workout shown on Home.")
                            .font(.caption)
                            .foregroundStyle(Color.summitTextTertiary)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.summitCard)
                }
            }

            if phases.isEmpty {
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
                                showCreateWorkout()
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
                        .onDelete { offsets in
                            deleteWorkouts(at: offsets, in: nil)
                        }
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
            } else {
                Section {
                    ForEach(phases) { phase in
                        NavigationLink {
                            PhaseDetailView(phase: phase, plan: plan)
                        } label: {
                            PhaseListRowView(phase: phase, workoutCount: workouts(in: phase).count)
                        }
                        .listRowBackground(Color.summitCard)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if !phase.isActive {
                                Button {
                                    setActivePhase(phase)
                                } label: {
                                    Label("Set Active", systemImage: "star.fill")
                                }
                                .tint(Color.summitOrange)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                phaseToDelete = phase
                                showingDeletePhaseConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Phases")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
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
                    if phases.isEmpty {
                        showCreateWorkout()
                    } else {
                        showPhasePrompt(.add)
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.summitOrange)
                }
            }
        }
        .sheet(isPresented: $showingCreateWorkout) {
            CreateWorkoutView(workoutPlan: plan, preselectedPhaseId: createWorkoutPhaseId)
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation, presenting: workoutToDelete) { workout in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout(workout)
            }
        } message: { workout in
            Text("Are you sure you want to delete '\(workout.name)'? All exercises in this workout will be permanently deleted. This cannot be undone.")
        }
        .alert("Delete Phase", isPresented: $showingDeletePhaseConfirmation, presenting: phaseToDelete) { phase in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePhase(phase)
            }
        } message: { phase in
            Text("Deleting '\(phase.name)' will remove all workouts inside it. This cannot be undone.")
        }
        .navigationDestination(isPresented: $showingPhasePrompt) {
            PhasePromptView(
                title: phasePromptTitle,
                message: phasePromptMessage,
                confirmLabel: phasePromptConfirmLabel,
                phaseName: $phaseNameInput,
                onConfirm: {
                    handlePhasePrompt()
                }
            )
        }
    }

    private var phasePromptTitle: String {
        phasePromptMode == .enable ? "Enable Phases" : "Add Phase"
    }

    private var phasePromptMessage: String {
        switch phasePromptMode {
        case .enable:
            return "All existing workouts will be placed into the new phase. You can move workouts between phases later."
        case .add:
            return "Create a new phase for this plan."
        }
    }

    private var phasePromptConfirmLabel: String {
        phasePromptMode == .enable ? "Enable" : "Add"
    }

    private func deleteWorkouts(at offsets: IndexSet, in phase: PlanPhase?) {
        guard let index = offsets.first else { return }
        let source: [Workout]
        if let phase {
            source = workouts(in: phase)
        } else {
            source = workouts.sorted(by: { $0.orderIndex < $1.orderIndex })
        }
        guard source.indices.contains(index) else { return }
        workoutToDelete = source[index]
        showingDeleteConfirmation = true
    }

    private func deleteWorkout(_ workout: Workout) {
        let phase = workout.phase
        modelContext.delete(workout)

        do {
            reindexWorkouts(in: phase)
            try modelContext.save()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }

    private func showCreateWorkout() {
        createWorkoutPhaseId = nil
        showingCreateWorkout = true
    }

    private func showPhasePrompt(_ mode: PhasePromptMode) {
        phasePromptMode = mode
        if mode == .enable {
            phaseNameInput = "Phase 1"
        } else {
            phaseNameInput = "Phase \(phases.count + 1)"
        }
        showingPhasePrompt = true
    }

    private func handlePhasePrompt() {
        let trimmedName = phaseNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        switch phasePromptMode {
        case .enable:
            enablePhases(named: trimmedName)
        case .add:
            addPhase(named: trimmedName)
        }
    }

    private func enablePhases(named name: String) {
        let newPhase = PlanPhase(
            name: name,
            orderIndex: 0,
            isActive: true,
            workoutPlan: plan
        )
        modelContext.insert(newPhase)

        let planWorkouts = workouts.sorted(by: { $0.orderIndex < $1.orderIndex })
        for (index, workout) in planWorkouts.enumerated() {
            workout.phase = newPhase
            workout.orderIndex = index
        }

        do {
            try modelContext.save()
        } catch {
            print("Error enabling phases: \(error)")
        }
    }

    private func addPhase(named name: String) {
        let newPhase = PlanPhase(
            name: name,
            orderIndex: phases.count,
            isActive: false,
            workoutPlan: plan
        )
        modelContext.insert(newPhase)

        do {
            try modelContext.save()
        } catch {
            print("Error adding phase: \(error)")
        }
    }

    private func setActivePhase(_ phase: PlanPhase) {
        for item in phases {
            item.isActive = (item.id == phase.id)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error setting active phase: \(error)")
        }
    }

    private func deletePhase(_ phase: PlanPhase) {
        let wasActive = phase.isActive
        let remaining = phases.filter { $0.id != phase.id }.sorted(by: { $0.orderIndex < $1.orderIndex })

        modelContext.delete(phase)

        for (index, item) in remaining.enumerated() {
            item.orderIndex = index
        }

        if wasActive, let newActive = remaining.first {
            newActive.isActive = true
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting phase: \(error)")
        }
    }

    private func workouts(in phase: PlanPhase) -> [Workout] {
        workouts
            .filter { $0.phase?.id == phase.id }
            .sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private func reindexWorkouts(in phase: PlanPhase?) {
        let filtered = workouts
            .filter { $0.phase?.id == phase?.id }
            .sorted(by: { $0.orderIndex < $1.orderIndex })

        for (index, workout) in filtered.enumerated() {
            workout.orderIndex = index
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

struct PhaseListRowView: View {
    let phase: PlanPhase
    let workoutCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(phase.name)
                        .font(.headline)
                        .foregroundStyle(Color.summitText)

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
                    }
                }

                Text("\(workoutCount) workout\(workoutCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color.summitTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(Color.summitTextTertiary)
        }
        .padding(.vertical, 4)
    }
}

struct PhasePromptView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String
    let confirmLabel: String
    @Binding var phaseName: String
    let onConfirm: () -> Void

    private var canConfirm: Bool {
        !phaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Phase Name", text: $phaseName)
                } header: {
                    Text("Name")
                        .textCase(nil)
                } footer: {
                    Text(message)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel) {
                        onConfirm()
                        dismiss()
                    }
                    .disabled(!canConfirm)
                }
            }
        }
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
