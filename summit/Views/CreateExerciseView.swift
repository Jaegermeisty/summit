//
//  CreateExerciseView.swift
//  Summit
//
//  Created on 2026-02-07
//

import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExerciseDefinition.name, order: .forward) private var definitions: [ExerciseDefinition]
    @Query private var existingExercises: [Exercise]

    let workout: Workout

    @State private var exerciseName: String = ""
    @State private var selectedDefinition: ExerciseDefinition?
    @State private var targetWeight: Double = 0
    @State private var targetRepsMin: Int = 6
    @State private var targetRepsMax: Int = 8
    @State private var numberOfSets: Int = 3
    @State private var notes: String = ""

    private var normalizedName: String {
        ExerciseDefinition.normalize(exerciseName)
    }

    private var suggestions: [ExerciseDefinition] {
        let query = normalizedName
        guard !query.isEmpty else { return [] }

        let prefixMatches = definitions.filter { $0.normalizedName.hasPrefix(query) }
        if !prefixMatches.isEmpty {
            return Array(prefixMatches.prefix(6))
        }

        let containsMatches = definitions.filter { $0.normalizedName.contains(query) }
        return Array(containsMatches.prefix(6))
    }

    private var canSave: Bool {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && targetRepsMin > 0 && targetRepsMax >= targetRepsMin && numberOfSets > 0
    }

    init(workout: Workout) {
        self.workout = workout
        let workoutId = workout.id
        _existingExercises = Query(
            filter: #Predicate<Exercise> { exercise in
                exercise.workoutId == workoutId
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                suggestionsSection
                targetsSection
                notesSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.summitBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.summitTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createExercise()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? Color.summitOrange : Color.summitTextTertiary)
                }
            }
            .onChange(of: exerciseName) { _, _ in
                let normalized = normalizedName
                if let match = definitions.first(where: { $0.normalizedName == normalized }) {
                    if selectedDefinition?.id != match.id {
                        selectedDefinition = match
                    }
                    autofillWeightIfNeeded(from: match)
                } else if let selectedDefinition, selectedDefinition.normalizedName != normalized {
                    self.selectedDefinition = nil
                }
            }
            .onChange(of: targetRepsMin) { _, newValue in
                if newValue > targetRepsMax {
                    targetRepsMax = newValue
                }
            }
            .onChange(of: targetRepsMax) { _, newValue in
                if newValue < targetRepsMin {
                    targetRepsMin = newValue
                }
            }
        }
    }

    private var nameSection: some View {
        Section {
            TextField("Exercise Name", text: $exerciseName)
                .font(.body)
        } header: {
            Text("Name")
                .textCase(nil)
                .font(.subheadline)
                .foregroundStyle(Color.summitTextSecondary)
        } footer: {
            Text("Names are matched case-insensitively, so “bench press” and “Bench Press” are the same exercise.")
                .font(.caption)
                .foregroundStyle(Color.summitTextTertiary)
        }
        .listRowBackground(Color.summitCard)
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        let suggestionList: [ExerciseDefinition] = suggestions

        if !suggestionList.isEmpty {
            Section {
                ForEach(suggestionList, id: \ExerciseDefinition.id) { (definition: ExerciseDefinition) in
                    Button {
                        applyDefinition(definition)
                    } label: {
                        HStack {
                            Text(definition.name)
                            Spacer()
                            if selectedDefinition?.id == definition.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.summitOrange)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Suggestions")
                    .textCase(nil)
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
            }
            .listRowBackground(Color.summitCard)
        }
    }

    private var targetsSection: some View {
        Section {
            HStack {
                Text("Target Weight")
                    .foregroundStyle(Color.summitTextSecondary)

                Spacer()

                TextField("0", value: $targetWeight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)

                Text("kg")
                    .foregroundStyle(Color.summitTextSecondary)
            }

            Stepper(value: $targetRepsMin, in: 1...30) {
                HStack {
                    Text("Min Reps")
                    Spacer()
                    Text("\(targetRepsMin)")
                        .foregroundStyle(Color.summitTextSecondary)
                }
            }

            Stepper(value: $targetRepsMax, in: 1...30) {
                HStack {
                    Text("Max Reps")
                    Spacer()
                    Text("\(targetRepsMax)")
                        .foregroundStyle(Color.summitTextSecondary)
                }
            }

            Stepper(value: $numberOfSets, in: 1...20) {
                HStack {
                    Text("Sets")
                    Spacer()
                    Text("\(numberOfSets)")
                        .foregroundStyle(Color.summitTextSecondary)
                }
            }
        } header: {
            Text("Targets")
                .textCase(nil)
                .font(.subheadline)
                .foregroundStyle(Color.summitTextSecondary)
        }
        .listRowBackground(Color.summitCard)
    }

    private var notesSection: some View {
        Section {
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .font(.body)
        } header: {
            Text("Notes")
                .textCase(nil)
                .font(.subheadline)
                .foregroundStyle(Color.summitTextSecondary)
        }
        .listRowBackground(Color.summitCard)
    }

    private func createExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let definition = resolveDefinition(for: trimmedName)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let newExercise = Exercise(
            definition: definition,
            targetWeight: targetWeight,
            targetRepsMin: targetRepsMin,
            targetRepsMax: targetRepsMax,
            numberOfSets: numberOfSets,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            orderIndex: existingExercises.count,
            workout: workout
        )

        modelContext.insert(newExercise)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving exercise: \(error)")
        }
    }

    private func resolveDefinition(for name: String) -> ExerciseDefinition {
        let normalized = ExerciseDefinition.normalize(name)

        if let selectedDefinition, selectedDefinition.normalizedName == normalized {
            return selectedDefinition
        }

        if let existing = definitions.first(where: { $0.normalizedName == normalized }) {
            return existing
        }

        let definition = ExerciseDefinition(name: name)
        modelContext.insert(definition)
        return definition
    }

    private func applyDefinition(_ definition: ExerciseDefinition) {
        selectedDefinition = definition
        exerciseName = definition.name
        autofillWeightIfNeeded(from: definition)
    }

    private func autofillWeightIfNeeded(from definition: ExerciseDefinition) {
        guard targetWeight == 0 else { return }
        if let suggestedWeight = DataHelpers.suggestedTargetWeight(for: definition, in: modelContext) {
            targetWeight = suggestedWeight
        }
    }
}

#Preview {
    CreateExerciseView(workout: Workout(name: "Push Day", orderIndex: 0))
        .modelContainer(ModelContainer.preview)
}
