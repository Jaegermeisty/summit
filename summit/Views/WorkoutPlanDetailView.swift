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

private enum ActiveSheet: Identifiable {
    case createWorkout
    case phasePrompt

    var id: String {
        switch self {
        case .createWorkout: return "createWorkout"
        case .phasePrompt: return "phasePrompt"
        }
    }
}

struct WorkoutPlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var clipboard: ClipboardStore
    @Bindable var plan: WorkoutPlan
    @State private var workouts: [Workout] = []
    @State private var phases: [PlanPhase] = []

    @State private var activeSheet: ActiveSheet?
    @State private var createWorkoutPhaseId: UUID?
    @State private var workoutToDelete: Workout?
    @State private var showingDeleteConfirmation = false
    @State private var phasePromptMode: PhasePromptMode = .enable
    @State private var phaseNameInput: String = ""
    @State private var phaseToDelete: PlanPhase?
    @State private var showingDeletePhaseConfirmation = false
    @State private var showingEditPlan = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedWorkoutIds: Set<UUID> = []
    @State private var showingBulkDeleteConfirmation = false
    @State private var showingPastePhaseDialog = false
    @State private var pendingPasteWorkouts: [WorkoutTemplate] = []

    init(plan: WorkoutPlan) {
        _plan = Bindable(wrappedValue: plan)
    }

    var body: some View {
        contentList
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
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
                Menu {
                    Button {
                        editMode = (editMode == .active) ? .inactive : .active
                    } label: {
                        Label(editMode == .active ? "Done Selecting" : "Select Workouts", systemImage: "checklist")
                    }

                    if clipboard.hasWorkouts {
                        Button {
                            handlePasteAction()
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
                        showingEditPlan = true
                    } label: {
                        Label("Edit Plan", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.summitOrange)
                }
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
        .safeAreaInset(edge: .bottom) {
            if phases.isEmpty && editMode == .active && !selectedWorkoutIds.isEmpty {
                selectionActionBar(
                    doneAction: {
                        editMode = .inactive
                        selectedWorkoutIds.removeAll()
                    },
                    primaryTitle: "Copy",
                    primaryAction: copySelectedWorkouts,
                    secondaryTitle: "Delete",
                    secondaryRole: .destructive,
                    secondaryAction: { showingBulkDeleteConfirmation = true }
                )
                .padding(.bottom, 8)
            }
        }
        .sheet(item: $activeSheet, onDismiss: { refreshData() }) { sheet in
            switch sheet {
            case .createWorkout:
                CreateWorkoutView(workoutPlan: plan, preselectedPhaseId: createWorkoutPhaseId)
            case .phasePrompt:
                NavigationStack {
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
        }
        .sheet(isPresented: $showingEditPlan, onDismiss: { refreshData() }) {
            EditWorkoutPlanView(plan: plan)
        }
        .confirmationDialog("Paste Workouts", isPresented: $showingPastePhaseDialog) {
            ForEach(phases) { phase in
                Button("Paste to \(phase.name)") {
                    pasteWorkouts(into: phase)
                }
            }
            Button("New Phase...") {
                pendingPasteWorkouts = clipboard.workouts
                phaseNameInput = "Phase \(phases.count + 1)"
                showPhasePrompt(.add)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose a phase for the pasted workouts.")
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation, presenting: workoutToDelete) { workout in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout(workout)
            }
        } message: { workout in
            Text("Are you sure you want to delete '\(workout.name)'? All exercises in this workout will be permanently deleted. Exercise history will be kept. This cannot be undone.")
        }
        .alert("Delete Phase", isPresented: $showingDeletePhaseConfirmation, presenting: phaseToDelete) { phase in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePhase(phase)
            }
        } message: { phase in
            Text("Deleting '\(phase.name)' will remove all workouts inside it. Exercise history will be kept. This cannot be undone.")
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
            planDescriptionSection
            phaseInfoSection
            workoutsOrPhasesSection
        }
    }

    @ViewBuilder
    private var planDescriptionSection: some View {
        if let description = plan.planDescription {
            Section {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
            }
            .listRowBackground(Color.summitCard)
        }
    }

    private var phaseInfoSection: some View {
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
    }

    @ViewBuilder
    private var workoutsOrPhasesSection: some View {
        if phases.isEmpty {
            workoutsSection
        } else {
            phasesSection
        }
    }

    private var workoutsSection: some View {
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
                }
                .onDelete { offsets in
                    deleteWorkouts(at: offsets, in: nil)
                }
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

    private var phasesSection: some View {
        Section {
            ForEach(phases) { phase in
                NavigationLink {
                    PhaseDetailView(phase: phase, plan: plan)
                } label: {
                    PhaseListRowView(phase: phase, workoutCount: workouts.filter { $0.phaseId == phase.id }.count)
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

    private func deleteSelectedWorkouts() {
        let toDelete = selectedWorkouts
        guard !toDelete.isEmpty else { return }

        for workout in toDelete {
            modelContext.delete(workout)
        }

        do {
            reindexWorkouts(inPhaseId: nil)
            try modelContext.save()
            selectedWorkoutIds.removeAll()
            refreshData()
        } catch {
            print("Error deleting workouts: \(error)")
        }
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

    private func showCreateWorkout() {
        createWorkoutPhaseId = nil
        activeSheet = .createWorkout
    }

    private func showPhasePrompt(_ mode: PhasePromptMode) {
        phasePromptMode = mode
        if mode == .enable {
            phaseNameInput = "Phase 1"
        } else {
            phaseNameInput = "Phase \(phases.count + 1)"
        }
        activeSheet = .phasePrompt
    }

    private func handlePhasePrompt() {
        let trimmedName = phaseNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        switch phasePromptMode {
        case .enable:
            enablePhases(named: trimmedName)
        case .add:
            if let newPhase = addPhase(named: trimmedName), !pendingPasteWorkouts.isEmpty {
                pasteWorkouts(into: newPhase)
                pendingPasteWorkouts = []
            }
        }
    }

    private func enablePhases(named name: String) {
        let newPhase = PlanPhase(
            name: name,
            orderIndex: 0,
            isActive: true,
            planId: plan.id
        )
        modelContext.insert(newPhase)

        let planWorkouts = workouts.sorted(by: { $0.orderIndex < $1.orderIndex })
        for (index, workout) in planWorkouts.enumerated() {
            workout.phaseId = newPhase.id
            workout.orderIndex = index
        }

        do {
            try modelContext.save()
            refreshData()
        } catch {
            print("Error enabling phases: \(error)")
        }
    }

    @discardableResult
    private func addPhase(named name: String) -> PlanPhase? {
        let newPhase = PlanPhase(
            name: name,
            orderIndex: phases.count,
            isActive: false,
            planId: plan.id
        )
        modelContext.insert(newPhase)

        do {
            try modelContext.save()
            refreshData()
            return newPhase
        } catch {
            print("Error adding phase: \(error)")
            return nil
        }
    }

    private func setActivePhase(_ phase: PlanPhase) {
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

    private func deletePhase(_ phase: PlanPhase) {
        let wasActive = phase.isActive
        let remaining = phases.filter { $0.id != phase.id }.sorted(by: { $0.orderIndex < $1.orderIndex })

        // Manually delete workouts in this phase
        let phaseWorkouts = workouts.filter { $0.phaseId == phase.id }
        for w in phaseWorkouts { modelContext.delete(w) }

        modelContext.delete(phase)

        for (index, item) in remaining.enumerated() {
            item.orderIndex = index
        }

        if wasActive, let newActive = remaining.first {
            newActive.isActive = true
        }

        do {
            try modelContext.save()
            refreshData()
        } catch {
            print("Error deleting phase: \(error)")
        }
    }

    private func workouts(in phase: PlanPhase) -> [Workout] {
        workouts
            .filter { $0.phaseId == phase.id }
            .sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private func reindexWorkouts(inPhaseId phaseId: UUID?) {
        let filtered = workouts
            .filter { $0.phaseId == phaseId }
            .sorted(by: { $0.orderIndex < $1.orderIndex })

        for (index, workout) in filtered.enumerated() {
            workout.orderIndex = index
        }
    }

    private func moveWorkouts(from offsets: IndexSet, to destination: Int) {
        var updated = workouts.sorted(by: { $0.orderIndex < $1.orderIndex })
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

    private func selectionActionBar(
        doneAction: @escaping () -> Void,
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String,
        secondaryRole: ButtonRole? = nil,
        secondaryAction: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            Button("Done") {
                doneAction()
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.summitTextSecondary)

            Button(primaryTitle) {
                primaryAction()
            }
            .fontWeight(.semibold)
            .foregroundStyle(Color.summitOrange)

            Spacer()

            Button(secondaryTitle, role: secondaryRole) {
                secondaryAction()
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

    private func handlePasteAction() {
        guard clipboard.hasWorkouts else { return }
        if phases.isEmpty {
            pasteWorkouts(into: nil)
        } else {
            showingPastePhaseDialog = true
        }
    }

    private func pasteWorkouts(into phase: PlanPhase?) {
        guard clipboard.hasWorkouts else { return }
        let existing = DataHelpers.workouts(for: plan, in: modelContext, phase: phase)
        var nextIndex = existing.count

        for template in clipboard.workouts {
            let newWorkout = Workout(
                name: template.name,
                notes: template.notes,
                orderIndex: nextIndex,
                planId: plan.id,
                phaseId: phase?.id
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

    private func refreshData() {
        let planId = plan.id
        let workoutDescriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { item in
                item.planId == planId
            },
            sortBy: [SortDescriptor(\Workout.orderIndex, order: .forward)]
        )
        let phaseDescriptor = FetchDescriptor<PlanPhase>(
            predicate: #Predicate<PlanPhase> { item in
                item.planId == planId
            },
            sortBy: [SortDescriptor(\PlanPhase.orderIndex, order: .forward)]
        )

        workouts = (try? modelContext.fetch(workoutDescriptor)) ?? []
        phases = (try? modelContext.fetch(phaseDescriptor)) ?? []
    }

    private func exerciseCount(for workout: Workout) -> Int {
        let workoutId = workout.id
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.workoutId == workoutId
            }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    let exerciseCount: Int

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

                    Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
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

#Preview {
    NavigationStack {
        WorkoutPlanDetailView(plan: {
            let plan = WorkoutPlan(
                name: "Push Pull Legs",
                planDescription: "Classic 3-day split"
            )

            let pushDay = Workout(name: "Push Day", orderIndex: 0, planId: plan.id)
            let pullDay = Workout(name: "Pull Day", orderIndex: 1, planId: plan.id)
            let legDay = Workout(name: "Leg Day", orderIndex: 2, planId: plan.id)

            _ = pushDay
            _ = pullDay
            _ = legDay

            return plan
        }())
    }
    .modelContainer(ModelContainer.preview)
    .environmentObject(ClipboardStore())
}
