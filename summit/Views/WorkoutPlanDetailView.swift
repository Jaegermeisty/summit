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
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false
    @State private var showingPhasePrompt = false
    @State private var phasePromptMode: PhasePromptMode = .enable
    @State private var phaseNameInput: String = ""
    @State private var selectedPhaseId: UUID?
    @State private var workoutToMove: Workout?
    @State private var showingMoveDialog = false

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
                    HStack {
                        Text("Active Phase")
                            .foregroundStyle(Color.summitTextSecondary)

                        Spacer()

                        Picker("Active Phase", selection: $selectedPhaseId) {
                            ForEach(phases) { phase in
                                Text(phase.name).tag(Optional(phase.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .listRowBackground(Color.summitCard)
                }
            } header: {
                HStack {
                    Text("Phases")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)

                    Spacer()

                    if !phases.isEmpty {
                        Button {
                            showPhasePrompt(.add)
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Color.summitOrange)
                        }
                        .accessibilityLabel("Add Phase")
                    }
                }
            } footer: {
                if !phases.isEmpty {
                    Text("You can move workouts between phases later from the workouts list.")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
            }

            Section {
                if visibleWorkouts.isEmpty {
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
                    ForEach(visibleWorkouts) { workout in
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
                Text(workoutsHeaderTitle)
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
            } footer: {
                if !visibleWorkouts.isEmpty {
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
        .confirmationDialog("Move Workout", isPresented: $showingMoveDialog, presenting: workoutToMove) { workout in
            ForEach(phases.filter { $0.id != workout.phase?.id }) { phase in
                Button("Move to \(phase.name)") {
                    moveWorkout(workout, to: phase)
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
        .alert(phasePromptTitle, isPresented: $showingPhasePrompt) {
            TextField("Phase Name", text: $phaseNameInput)
            Button("Cancel", role: .cancel) { }
            Button(phasePromptConfirmLabel) {
                handlePhasePrompt()
            }
            .disabled(phaseNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text(phasePromptMessage)
        }
        .onAppear {
            syncSelectedPhase()
        }
        .onChange(of: phases.count) { _, _ in
            syncSelectedPhase()
        }
        .onChange(of: selectedPhaseId) { _, newValue in
            updateActivePhase(to: newValue)
        }
    }

    private var activePhase: PlanPhase? {
        guard !phases.isEmpty else { return nil }
        if let selectedPhaseId, let match = phases.first(where: { $0.id == selectedPhaseId }) {
            return match
        }
        return DataHelpers.activePhase(for: plan, in: modelContext)
    }

    private var visibleWorkouts: [Workout] {
        if let phase = activePhase {
            return workouts
                .filter { $0.phase?.id == phase.id }
                .sorted(by: { $0.orderIndex < $1.orderIndex })
        }
        return workouts
            .filter { $0.phase == nil }
            .sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private var workoutsHeaderTitle: String {
        if let phaseName = activePhase?.name {
            return "Workouts • \(phaseName)"
        }
        return "Workouts"
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

    private func deleteWorkouts(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        workoutToDelete = visibleWorkouts[index]
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

        selectedPhaseId = newPhase.id

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

    private func syncSelectedPhase() {
        guard !phases.isEmpty else {
            selectedPhaseId = nil
            return
        }
        if let selectedPhaseId, phases.contains(where: { $0.id == selectedPhaseId }) {
            return
        }
        if let activePhase = DataHelpers.activePhase(for: plan, in: modelContext) {
            selectedPhaseId = activePhase.id
        }
    }

    private func updateActivePhase(to phaseId: UUID?) {
        guard let phaseId,
              let selected = phases.first(where: { $0.id == phaseId }) else { return }

        for phase in phases {
            phase.isActive = (phase.id == selected.id)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error setting active phase: \(error)")
        }
    }

    private func moveWorkout(_ workout: Workout, to phase: PlanPhase) {
        guard workout.phase?.id != phase.id else { return }

        let previousPhase = workout.phase
        let targetCount = workouts.filter { $0.phase?.id == phase.id }.count
        workout.phase = phase
        workout.orderIndex = targetCount

        reindexWorkouts(in: previousPhase)

        do {
            try modelContext.save()
        } catch {
            print("Error moving workout: \(error)")
        }
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
