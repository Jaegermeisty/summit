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
        ZStack {
            planBackground
            contentList
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
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
        .listStyle(.plain)
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
        .listRowSeparatorTint(.clear)
        .listSectionSeparatorTint(.clear)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    @ViewBuilder
    private var planDescriptionSection: some View {
        if let description = plan.planDescription {
            Section {
                infoCard {
                    Text(description)
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var phaseInfoSection: some View {
        Section {
            if phases.isEmpty {
                infoCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Phases")
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitText)

                        Text("Group workouts into phases if you want to rotate blocks.")
                            .font(.custom("Avenir Next", size: 13))
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
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                infoCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Phases")
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitText)

                        if let active = phases.first(where: { $0.isActive }) {
                            Text("Active: \(active.name)")
                                .font(.custom("Avenir Next", size: 13))
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                .listRowSeparator(.hidden)
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
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete { offsets in
                    deleteWorkouts(at: offsets, in: nil)
                }
                .onMove(perform: moveWorkouts)
            }
        } header: {
            sectionHeader(title: "Workouts")
                .listRowSeparator(.hidden)
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
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
            sectionHeader(title: "Phases")
                .listRowSeparator(.hidden)
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

    private var planBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.summitBackground,
                    Color(hex: "#111114")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.summitOrange.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: 140, y: -120)
        }
        .ignoresSafeArea()
    }

    private func sectionHeader(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.custom("Avenir Next", size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitTextSecondary)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.summitOrange, Color.summitOrange.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .cornerRadius(1)
        }
        .padding(.bottom, 4)
    }

    private func infoCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.summitCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                    )
            )
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.summitOrange.opacity(0.7))
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Day \(workout.orderIndex + 1)")
                            .font(.custom("Avenir Next", size: 11))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.summitCardElevated)
                            )

                        Text(workout.name)
                            .font(.custom("Avenir Next", size: 17))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitText)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell")
                            .font(.caption2)

                        Text("\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")")
                            .font(.custom("Avenir Next", size: 12))
                    }
                    .foregroundStyle(Color.summitTextSecondary)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

struct PhaseListRowView: View {
    let phase: PlanPhase
    let workoutCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(phase.isActive ? Color.summitOrange : Color.summitOrange.opacity(0.35))
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(phase.name)
                            .font(.custom("Avenir Next", size: 17))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitText)

                        if phase.isActive {
                            Text("Active")
                                .font(.custom("Avenir Next", size: 11))
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
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.summitTextTertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
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
        ZStack {
            formBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.custom("Avenir Next", size: 22))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitText)
                    }

                    fieldCard(
                        title: "Name",
                        helper: message
                    ) {
                        TextField("Phase Name", text: $phaseName)
                            .textInputAutocapitalization(.words)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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

    private func fieldCard<Content: View>(
        title: String,
        helper: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("Avenir Next", size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitTextSecondary)

            content()
                .font(.custom("Avenir Next", size: 16))
                .foregroundStyle(Color.summitText)
                .accentColor(Color.summitOrange)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.summitCardElevated)
                )

            Text(helper)
                .font(.custom("Avenir Next", size: 12))
                .foregroundStyle(Color.summitTextTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var formBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.summitBackground,
                    Color(hex: "#111114")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.summitOrange.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 140, y: -140)
        }
        .ignoresSafeArea()
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
