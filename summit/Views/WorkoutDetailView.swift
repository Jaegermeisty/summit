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
    @EnvironmentObject private var clipboard: ClipboardStore
    @Bindable var workout: Workout
    @State private var exercises: [Exercise] = []

    @State private var showingCreateExercise = false
    @State private var editingExercise: Exercise?
    @State private var selectedSession: WorkoutSession?
    @State private var exerciseToDelete: Exercise?
    @State private var showingDeleteExerciseConfirmation = false
    @State private var showingEditWorkout = false
    @State private var editMode: EditMode = .inactive
    @State private var selectedExerciseIds: Set<UUID> = []
    @State private var showingBulkDeleteExercisesConfirmation = false
    @State private var showingMoveExercisesDialog = false
    @State private var availableWorkouts: [Workout] = []

    init(workout: Workout) {
        _workout = Bindable(wrappedValue: workout)
    }

    var body: some View {
        ZStack {
            workoutBackground

            List(selection: $selectedExerciseIds) {
                if let notes = workout.notes, !notes.isEmpty {
                    Section {
                        infoCard {
                            Text(notes)
                                .font(.custom("Avenir Next", size: 15))
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } header: {
                        sectionHeader(title: "Notes")
                    }
                }

            Section {
                Button {
                    selectedSession = DataHelpers.startSession(for: workout, in: modelContext)
                } label: {
                    infoCard {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Workout")
                                    .font(.custom("Avenir Next", size: 17))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.summitBackground)
                                Text("Begin your session and log sets")
                                    .font(.custom("Avenir Next", size: 12))
                                    .foregroundStyle(Color.summitBackground.opacity(0.75))
                            }

                            Spacer()

                            Image(systemName: "play.fill")
                                .font(.title3)
                                .foregroundStyle(Color.summitBackground)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.summitOrange,
                                            Color.summitOrange.opacity(0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } header: {
                    sectionHeader(title: "Session")
                }

                Section {
                    if exercises.isEmpty {
                        infoCard {
                            ContentUnavailableView {
                                Label("No Exercises", systemImage: "dumbbell")
                                    .foregroundStyle(Color.summitText)
                            } description: {
                                Text("Add exercises to this workout to get started")
                                    .foregroundStyle(Color.summitTextSecondary)
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
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(exercises) { exercise in
                            Group {
                                if editMode == .active {
                                    ExerciseRowView(exercise: exercise)
                                        .contentShape(Rectangle())
                                } else {
                                    Button {
                                        editingExercise = exercise
                                    } label: {
                                        ExerciseRowView(exercise: exercise)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .tag(exercise.id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: confirmDeleteExercises)
                        .onMove(perform: moveExercises)
                    }
                } header: {
                    sectionHeader(title: "Exercises")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.summitBackground, for: .navigationBar)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateExercise = true
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
                        Label(editMode == .active ? "Done Selecting" : "Select Exercises", systemImage: "checklist")
                    }

                    if clipboard.hasExercises {
                        Button {
                            pasteExercises()
                        } label: {
                            Label("Paste Exercises", systemImage: "doc.on.clipboard")
                        }
                    }

                    if !exercises.isEmpty {
                        Button {
                            copyAllExercises()
                        } label: {
                            Label("Copy All Exercises", systemImage: "doc.on.doc")
                        }
                    }

                    Button {
                        showingEditWorkout = true
                    } label: {
                        Label("Edit Workout", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.summitOrange)
                }
            }

        }
        .safeAreaInset(edge: .bottom) {
            if editMode == .active && !selectedExerciseIds.isEmpty {
                selectionActionBar(
                    doneAction: {
                        editMode = .inactive
                        selectedExerciseIds.removeAll()
                    },
                    moveAction: { showingMoveExercisesDialog = true },
                    copyAction: copySelectedExercises,
                    deleteAction: { showingBulkDeleteExercisesConfirmation = true }
                )
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingCreateExercise, onDismiss: { refreshExercises() }) {
            CreateExerciseView(workout: workout)
        }
        .sheet(item: $editingExercise, onDismiss: { refreshExercises() }) { exercise in
            EditExerciseView(exercise: exercise)
        }
        .sheet(isPresented: $showingEditWorkout) {
            EditWorkoutView(workout: workout)
        }
        .alert("Delete Exercise", isPresented: $showingDeleteExerciseConfirmation, presenting: exerciseToDelete) { exercise in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteExercise(exercise)
            }
        } message: { exercise in
            Text("Are you sure you want to delete '\(exercise.name)'? This removes it from the workout. Exercise history will be kept. This cannot be undone.")
        }
        .alert("Delete Exercises", isPresented: $showingBulkDeleteExercisesConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedExercises()
            }
        } message: {
            Text("Delete \(selectedExerciseIds.count) exercise(s)? Exercise history will be kept. This cannot be undone.")
        }
        .confirmationDialog("Move Exercises", isPresented: $showingMoveExercisesDialog) {
            ForEach(availableWorkouts.filter { $0.id != workout.id }) { target in
                Button("Move to \(target.name)") {
                    moveSelectedExercises(to: target)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose a workout for the selected exercises.")
        }
        .navigationDestination(item: $selectedSession) { session in
            WorkoutSessionView(session: session, workout: workout)
        }
        .onAppear {
            refreshExercises()
            loadAvailableWorkouts()
        }
    }

    private func confirmDeleteExercises(at offsets: IndexSet) {
        guard let index = offsets.first, exercises.indices.contains(index) else { return }
        exerciseToDelete = exercises[index]
        showingDeleteExerciseConfirmation = true
    }

    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)

        reindexExercises(excluding: exercise.id)

        do {
            try modelContext.save()
            refreshExercises()
        } catch {
            print("Error deleting exercise: \(error)")
        }
    }

    private func deleteSelectedExercises() {
        let toDelete = selectedExercises
        guard !toDelete.isEmpty else { return }

        for exercise in toDelete {
            modelContext.delete(exercise)
        }

        reindexExercises(excludingIds: Set(toDelete.map(\.id)))

        do {
            try modelContext.save()
            selectedExerciseIds.removeAll()
            refreshExercises()
        } catch {
            print("Error deleting exercises: \(error)")
        }
    }

    private func selectionActionBar(
        doneAction: @escaping () -> Void,
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

    private var workoutBackground: some View {
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
                .fill(Color.summitOrange.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: 150, y: -140)
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

    private func moveExercises(from offsets: IndexSet, to destination: Int) {
        var updated = exercises
        updated.move(fromOffsets: offsets, toOffset: destination)
        for (index, exercise) in updated.enumerated() {
            exercise.orderIndex = index
        }

        do {
            try modelContext.save()
            refreshExercises()
        } catch {
            print("Error reordering exercises: \(error)")
        }
    }

    private func copySelectedExercises() {
        let templates = selectedExercises.map { exercise in
            ExerciseTemplate(
                name: exercise.name,
                targetWeight: exercise.targetWeight,
                targetRepsMin: exercise.targetRepsMin,
                targetRepsMax: exercise.targetRepsMax,
                numberOfSets: exercise.numberOfSets,
                notes: exercise.notes
            )
        }
        clipboard.setExercises(templates)
        if editMode == .active {
            editMode = .inactive
        }
        selectedExerciseIds.removeAll()
    }

    private func copyAllExercises() {
        let templates = exercises
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
        clipboard.setExercises(templates)
    }

    private func pasteExercises() {
        guard clipboard.hasExercises else { return }
        var nextIndex = exercises.count

        for template in clipboard.exercises {
            let definition = DataHelpers.definition(named: template.name, in: modelContext)
            let newExercise = Exercise(
                definition: definition,
                targetWeight: template.targetWeight,
                targetRepsMin: template.targetRepsMin,
                targetRepsMax: template.targetRepsMax,
                numberOfSets: template.numberOfSets,
                notes: template.notes,
                orderIndex: nextIndex,
                workout: workout
            )
            modelContext.insert(newExercise)
            nextIndex += 1
        }

        do {
            try modelContext.save()
            refreshExercises()
        } catch {
            print("Error pasting exercises: \(error)")
        }
    }

    private func moveSelectedExercises(to target: Workout) {
        let toMove = selectedExercises
        guard !toMove.isEmpty else { return }

        let targetExercises = DataHelpers.exercises(for: target, in: modelContext)
        var nextIndex = targetExercises.count

        for exercise in toMove {
            exercise.workoutId = target.id
            exercise.workout = target
            exercise.orderIndex = nextIndex
            nextIndex += 1
        }

        reindexExercises(excludingIds: Set(toMove.map(\.id)))

        do {
            try modelContext.save()
            selectedExerciseIds.removeAll()
            refreshExercises()
        } catch {
            print("Error moving exercises: \(error)")
        }
    }

    private func reindexExercises(excluding excludedId: UUID) {
        reindexExercises(excludingIds: [excludedId])
    }

    private func reindexExercises(excludingIds excludedIds: Set<UUID>) {
        let remaining = exercises.filter { !excludedIds.contains($0.id) }
        let sorted = remaining.sorted(by: { $0.orderIndex < $1.orderIndex })
        for (newIndex, item) in sorted.enumerated() {
            item.orderIndex = newIndex
        }
    }

    private var selectedExercises: [Exercise] {
        exercises
            .filter { selectedExerciseIds.contains($0.id) }
            .sorted(by: { $0.orderIndex < $1.orderIndex })
    }

    private func loadAvailableWorkouts() {
        guard let planId = workout.planId else {
            availableWorkouts = []
            return
        }
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { item in
                item.planId == planId
            },
            sortBy: [SortDescriptor(\Workout.orderIndex, order: .forward)]
        )
        availableWorkouts = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func refreshExercises() {
        let workoutId = workout.id
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate<Exercise> { exercise in
                exercise.workoutId == workoutId
            },
            sortBy: [SortDescriptor(\Exercise.orderIndex, order: .forward)]
        )
        exercises = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.name)
                .font(.custom("Avenir Next", size: 17))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)

            HStack(spacing: 14) {
                infoChip(text: "\(Int(exercise.targetWeight))kg", systemImage: "scalemass")
                infoChip(text: "\(exercise.targetRepsMin)-\(exercise.targetRepsMax) reps", systemImage: "repeat")
                infoChip(text: "\(exercise.numberOfSets) sets", systemImage: "square.stack.3d.up")
            }

            if let notes = exercise.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(Color.summitOrange)

                    Text(notes)
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
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

    private func infoChip(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
            Text(text)
                .font(.custom("Avenir Next", size: 12))
        }
        .foregroundStyle(Color.summitTextSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.summitCardElevated)
        )
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: {
            let workout = Workout(name: "Push Day", orderIndex: 0)

            let benchDefinition = ExerciseDefinition(name: "Bench Press")
            let shoulderDefinition = ExerciseDefinition(name: "Shoulder Press")

            let bench = Exercise(
                definition: benchDefinition,
                targetWeight: 60.0,
                targetRepsMin: 6,
                targetRepsMax: 8,
                numberOfSets: 3,
                notes: "Pause at bottom",
                orderIndex: 0,
                workout: workout
            )

            let shoulder = Exercise(
                definition: shoulderDefinition,
                targetWeight: 40.0,
                targetRepsMin: 8,
                targetRepsMax: 10,
                numberOfSets: 3,
                orderIndex: 1,
                workout: workout
            )

            _ = bench
            _ = shoulder

            return workout
        }())
    }
    .modelContainer(ModelContainer.preview)
    .environmentObject(ClipboardStore())
}
