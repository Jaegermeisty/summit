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
    @EnvironmentObject private var clipboard: ClipboardStore
    @Bindable var phase: PlanPhase
    let plan: WorkoutPlan

    // Use @State + FetchDescriptor instead of @Query to avoid
    // SwiftData observation loops that freeze the UI on navigation.
    @State private var workouts: [Workout] = []
    @State private var allWorkouts: [Workout] = []
    @State private var phases: [PlanPhase] = []

    @State private var showingCreateWorkout = false
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false
    @State private var showingBulkDeleteConfirmation = false
    @State private var selectedWorkoutIds: Set<UUID> = []
    @State private var workoutToMove: Workout?
    @State private var showingMoveDialog = false
    @State private var showingEditPhase = false
    @State private var showingMovePhaseDialog = false
    @State private var showingPhasePrompt = false
    @State private var phaseNameInput: String = ""
    @State private var pendingMoveWorkouts: [Workout] = []
    @State private var editMode: EditMode = .inactive

    var body: some View {
        contentList
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle(phase.name)
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
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

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        editMode = (editMode == .active) ? .inactive : .active
                    } label: {
                        Label(editMode == .active ? "Done Selecting" : "Select Workouts", systemImage: "checklist")
                    }

                    if clipboard.hasWorkouts {
                        Button {
                            pasteWorkouts(into: phase)
                        } label: {
                            Label("Paste Workouts", systemImage: "doc.on.clipboard")
                        }
                    }

                    if !workouts.isEmpty {
                        Button {
                            copyWorkouts(workouts.sorted(by: { $0.orderIndex < $1.orderIndex }))
                        } label: {
                            Label("Copy All Workouts", systemImage: "doc.on.doc")
                        }
                    }

                    Button {
                        showingEditPhase = true
                    } label: {
                        Label("Edit Phase", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.summitOrange)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if editMode == .active && !selectedWorkoutIds.isEmpty {
                selectionActionBar(
                    doneAction: {
                        editMode = .inactive
                        selectedWorkoutIds.removeAll()
                    },
                    moveEnabled: phases.count > 1,
                    moveAction: { showingMovePhaseDialog = true },
                    copyAction: copySelectedWorkouts,
                    deleteAction: { showingBulkDeleteConfirmation = true }
                )
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingCreateWorkout, onDismiss: { refreshData() }) {
            CreateWorkoutView(workoutPlan: plan, preselectedPhaseId: phase.id)
        }
        .sheet(isPresented: $showingEditPhase, onDismiss: { refreshData() }) {
            EditPhaseView(phase: phase)
        }
        .sheet(isPresented: $showingPhasePrompt, onDismiss: { refreshData() }) {
            NavigationStack {
                PhasePromptView(
                    title: "Add Phase",
                    message: "Create a new phase and move the selected workouts.",
                    confirmLabel: "Add",
                    phaseName: $phaseNameInput,
                    onConfirm: {
                        createPhaseAndMove()
                    }
                )
            }
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
        .confirmationDialog("Move Workouts", isPresented: $showingMovePhaseDialog) {
            ForEach(phases.filter { $0.id != phase.id }) { target in
                Button("Move to \(target.name)") {
                    moveSelectedWorkouts(to: target)
                }
            }
            Button("New Phase...") {
                pendingMoveWorkouts = selectedWorkouts
                phaseNameInput = "Phase \(phases.count + 1)"
                showingPhasePrompt = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Select a phase for the selected workouts.")
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation, presenting: workoutToDelete) { workout in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout(workout)
            }
        } message: { workout in
            Text("Are you sure you want to delete '\(workout.name)'? All exercises in this workout will be permanently deleted. Exercise history will be kept. This cannot be undone.")
        }
        .alert("Delete Workouts", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedWorkouts()
            }
        } message: {
            Text("Delete \(selectedWorkoutIds.count) workout(s)? All exercises in these workouts will be permanently deleted. Exercise history will be kept. This cannot be undone.")
        }
        .onAppear {
            refreshData()
        }
    }

    private var contentList: some View {
        List(selection: $selectedWorkoutIds) {
            phaseHeaderSection
            workoutsSection
        }
    }

    private var phaseHeaderSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(phase.name)
                        .font(.headline)
                        .foregroundStyle(Color.summitText)

                    Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextSecondary)

                    if let notes = phase.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(Color.summitTextSecondary)
                    }
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
    }

    private var workoutsSection: some View {
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
                    Group {
                        if editMode == .active {
                            WorkoutRowView(workout: workout, exerciseCount: exerciseCount(for: workout))
                                .contentShape(Rectangle())
                        } else {
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutRowView(workout: workout, exerciseCount: exerciseCount(for: workout))
                            }
                        }
                    }
                    .tag(workout.id)
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
                .onMove(perform: moveWorkouts)
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

    // MARK: - Data Loading

    private func refreshData() {
        let phaseId = phase.id
        let planId = plan.id

        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.phaseId == phaseId },
            sortBy: [SortDescriptor(\Workout.orderIndex, order: .forward)]
        )
        let allWorkoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.planId == planId }
        )
        let phaseDescriptor = FetchDescriptor<PlanPhase>(
            predicate: #Predicate<PlanPhase> { $0.planId == planId },
            sortBy: [SortDescriptor(\PlanPhase.orderIndex, order: .forward)]
        )

        workouts = (try? modelContext.fetch(workoutDescriptor)) ?? []
        allWorkouts = (try? modelContext.fetch(allWorkoutDescriptor)) ?? []
        phases = (try? modelContext.fetch(phaseDescriptor)) ?? []
    }

    private func exerciseCount(for workout: Workout) -> Int {
        let workoutId = workout.id
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { $0.workoutId == workoutId }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Actions

    private func deleteWorkouts(at offsets: IndexSet) {
        guard let index = offsets.first, workouts.indices.contains(index) else { return }
        workoutToDelete = workouts[index]
        showingDeleteConfirmation = true
    }

    private func deleteWorkout(_ workout: Workout) {
        let phaseId = workout.phaseId
        modelContext.delete(workout)

        do {
            reindexWorkouts(inPhaseId: phaseId)
            try modelContext.save()
            refreshData()
        } catch {
            print("Error deleting workout: \(error)")
        }
    }

    private func deleteSelectedWorkouts() {
        let toDelete = selectedWorkouts
        guard !toDelete.isEmpty else { return }

        for workout in toDelete {
            modelContext.delete(workout)
        }

        do {
            try modelContext.save()
            selectedWorkoutIds.removeAll()
            refreshData()
        } catch {
            print("Error deleting workouts: \(error)")
        }
    }

    private func selectionActionBar(
        doneAction: @escaping () -> Void,
        moveEnabled: Bool,
        moveAction: @escaping () -> Void,
        copyAction: @escaping () -> Void,
        deleteAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            Button("Done") {
                doneAction()
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.summitTextSecondary)

            Button("Move") {
                moveAction()
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.summitOrange)
            .disabled(!moveEnabled)

            Button("Copy") {
                copyAction()
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.summitOrange)

            Spacer()

            Button("Delete", role: .destructive) {
                deleteAction()
            }
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.summitCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.summitTextTertiary.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func moveWorkouts(from offsets: IndexSet, to destination: Int) {
        var updated = workouts
        updated.move(fromOffsets: offsets, toOffset: destination)
        for (index, workout) in updated.enumerated() {
            workout.orderIndex = index
        }

        do {
            try modelContext.save()
            refreshData()
        } catch {
            print("Error reordering workouts: \(error)")
        }
    }

    private var selectedWorkouts: [Workout] {
        workouts
            .filter { selectedWorkoutIds.contains($0.id) }
            .sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private func copySelectedWorkouts() {
        copyWorkouts(selectedWorkouts)
        if editMode == .active {
            editMode = .inactive
        }
        selectedWorkoutIds.removeAll()
    }

    private func copyWorkouts(_ workouts: [Workout]) {
        let templates = workouts.map { workout in
            let exercises = DataHelpers.exercises(for: workout, in: modelContext)
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .map { exercise in
                    ExerciseTemplate(
                        name: exercise.name,
                        targetWeight: exercise.targetWeight,
                        targetRepsMin: exercise.targetRepsMin,
                        targetRepsMax: exercise.targetRepsMax,
                        numberOfSets: exercise.numberOfSets,
                        notes: exercise.notes
                    )
                }
            return WorkoutTemplate(name: workout.name, notes: workout.notes, exercises: exercises)
        }
        clipboard.setWorkouts(templates)
    }

    private func pasteWorkouts(into targetPhase: PlanPhase) {
        guard clipboard.hasWorkouts else { return }
        let existing = workouts.filter { $0.phaseId == targetPhase.id }
        var nextIndex = existing.count

        for template in clipboard.workouts {
            let newWorkout = Workout(
                name: template.name,
                notes: template.notes,
                orderIndex: nextIndex,
                planId: plan.id,
                phaseId: targetPhase.id
            )
            modelContext.insert(newWorkout)

            for (idx, exercise) in template.exercises.enumerated() {
                let definition = DataHelpers.definition(named: exercise.name, in: modelContext)
                let newExercise = Exercise(
                    definition: definition,
                    targetWeight: exercise.targetWeight,
                    targetRepsMin: exercise.targetRepsMin,
                    targetRepsMax: exercise.targetRepsMax,
                    numberOfSets: exercise.numberOfSets,
                    notes: exercise.notes,
                    orderIndex: idx,
                    workout: newWorkout
                )
                modelContext.insert(newExercise)
            }

            nextIndex += 1
        }

        do {
            try modelContext.save()
            refreshData()
        } catch {
            print("Error pasting workouts: \(error)")
        }
    }

    private func moveSelectedWorkouts(to target: PlanPhase) {
        let toMove = selectedWorkouts
        guard !toMove.isEmpty else { return }

        let targetCount = allWorkouts.filter { $0.phaseId == target.id }.count
        var nextIndex = targetCount
        for workout in toMove {
            workout.phaseId = target.id
            workout.orderIndex = nextIndex
            nextIndex += 1
        }

        // Reindex current phase after removing
        let remaining = workouts.filter { !selectedWorkoutIds.contains($0.id) }
        for (index, workout) in remaining.enumerated() {
            workout.orderIndex = index
        }

        do {
            try modelContext.save()
            selectedWorkoutIds.removeAll()
            refreshData()
        } catch {
            print("Error moving workouts: \(error)")
        }
    }

    private func createPhaseAndMove() {
        let trimmed = phaseNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newPhase = PlanPhase(
            name: trimmed,
            orderIndex: phases.count,
            isActive: false,
            planId: plan.id
        )
        modelContext.insert(newPhase)

        let toMove = pendingMoveWorkouts
        let targetCount = allWorkouts.filter { $0.phaseId == newPhase.id }.count
        var nextIndex = targetCount
        for workout in toMove {
            workout.phaseId = newPhase.id
            workout.orderIndex = nextIndex
            nextIndex += 1
        }

        // Reindex current phase after removing
        let remaining = workouts.filter { workout in
            !toMove.contains(where: { $0.id == workout.id })
        }
        for (index, workout) in remaining.enumerated() {
            workout.orderIndex = index
        }

        do {
            try modelContext.save()
            pendingMoveWorkouts = []
            selectedWorkoutIds.removeAll()
            refreshData()
        } catch {
            print("Error creating phase and moving workouts: \(error)")
        }
    }

    private func reindexWorkouts(inPhaseId phaseId: UUID?) {
        let filtered = allWorkouts
            .filter { $0.phaseId == phaseId }
            .sorted(by: { $0.orderIndex < $1.orderIndex })

        for (index, workout) in filtered.enumerated() {
            workout.orderIndex = index
        }
    }

    private func moveWorkout(_ workout: Workout, to targetPhase: PlanPhase) {
        guard workout.phaseId != targetPhase.id else { return }

        let targetId = targetPhase.id
        let targetCount = allWorkouts.filter { $0.phaseId == targetId }.count
        workout.phaseId = targetPhase.id
        workout.orderIndex = targetCount

        // Reindex current phase
        let remaining = workouts.filter { $0.id != workout.id }
        for (index, w) in remaining.enumerated() {
            w.orderIndex = index
        }

        do {
            try modelContext.save()
            refreshData()
        } catch {
            print("Error moving workout: \(error)")
        }
    }

    private func setActivePhase() {
        for item in phases {
            item.isActive = (item.id == phase.id)
        }

        do {
            try modelContext.save()
            refreshData()
        } catch {
            print("Error setting active phase: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        PhaseDetailView(phase: PlanPhase(name: "Phase 1"), plan: WorkoutPlan(name: "Push Pull Legs"))
            .modelContainer(ModelContainer.preview)
            .environmentObject(ClipboardStore())
    }
}
