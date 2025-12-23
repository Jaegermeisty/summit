//
//  EditExerciseView.swift
//  summit
//
//  Created on 2025-12-22
//

import SwiftUI
import SwiftData

struct EditExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise

    @State private var exerciseName: String
    @State private var targetWeight: String
    @State private var targetRepsMin: String
    @State private var targetRepsMax: String
    @State private var numberOfSets: String
    @State private var exerciseNotes: String

    @FocusState private var focusedField: Field?

    enum Field {
        case name, weight, repsMin, repsMax, sets, notes
    }

    init(exercise: Exercise) {
        self.exercise = exercise
        _exerciseName = State(initialValue: exercise.name)
        _targetWeight = State(initialValue: String(format: "%.1f", exercise.targetWeight))
        _targetRepsMin = State(initialValue: "\(exercise.targetRepsMin)")
        _targetRepsMax = State(initialValue: "\(exercise.targetRepsMax)")
        _numberOfSets = State(initialValue: "\(exercise.numberOfSets)")
        _exerciseNotes = State(initialValue: exercise.notes ?? "")
    }

    private var isFormValid: Bool {
        !exerciseName.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(targetWeight) != nil &&
        Int(targetRepsMin) != nil &&
        Int(targetRepsMax) != nil &&
        Int(numberOfSets) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise Name", text: $exerciseName)
                        .font(.body)
                        .focused($focusedField, equals: .name)
                } header: {
                    Text("Name")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    TextField("Weight", text: $targetWeight)
                        .keyboardType(.decimalPad)
                        .font(.body)
                        .focused($focusedField, equals: .weight)
                } header: {
                    Text("Target Weight (kg)")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Min")
                                .font(.caption)
                                .foregroundStyle(Color.summitTextSecondary)
                            TextField("6", text: $targetRepsMin)
                                .keyboardType(.numberPad)
                                .font(.body)
                                .focused($focusedField, equals: .repsMin)
                        }

                        Text("—")
                            .foregroundStyle(Color.summitTextSecondary)
                            .padding(.top, 20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Max")
                                .font(.caption)
                                .foregroundStyle(Color.summitTextSecondary)
                            TextField("8", text: $targetRepsMax)
                                .keyboardType(.numberPad)
                                .font(.body)
                                .focused($focusedField, equals: .repsMax)
                        }
                    }
                } header: {
                    Text("Target Reps")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    TextField("Number of Sets", text: $numberOfSets)
                        .keyboardType(.numberPad)
                        .font(.body)
                        .focused($focusedField, equals: .sets)
                } header: {
                    Text("Sets")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    TextField("Notes (optional)", text: $exerciseNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.body)
                        .focused($focusedField, equals: .notes)
                } header: {
                    Text("Notes")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle("Edit Exercise")
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

                ToolbarItem(placement: .principal) {
                    Text("Summit")
                        .font(.system(size: 18, weight: .bold))
                        .italic()
                        .foregroundStyle(Color.summitOrange)
                        .fixedSize()
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundStyle(isFormValid ? Color.summitOrange : Color.summitTextTertiary)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundStyle(Color.summitOrange)
                }
            }
        }
    }

    private func saveChanges() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = exerciseNotes.trimmingCharacters(in: .whitespaces)

        guard let weight = Double(targetWeight),
              let repsMin = Int(targetRepsMin),
              let repsMax = Int(targetRepsMax),
              let sets = Int(numberOfSets) else {
            return
        }

        exercise.name = trimmedName
        exercise.targetWeight = weight
        exercise.targetRepsMin = repsMin
        exercise.targetRepsMax = repsMax
        exercise.numberOfSets = sets
        exercise.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving exercise changes: \(error)")
        }
    }
}

#Preview {
    EditExerciseView(exercise: {
        let workout = Workout(name: "Push Day", orderIndex: 0)
        let exercise = Exercise(
            name: "Bench Press",
            targetWeight: 60.0,
            targetRepsMin: 6,
            targetRepsMax: 8,
            numberOfSets: 3,
            notes: "Pause at bottom",
            orderIndex: 0,
            workout: workout
        )
        return exercise
    }())
    .modelContainer(ModelContainer.preview)
}
