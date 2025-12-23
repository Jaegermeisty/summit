//
//  CreateExerciseView.swift
//  summit
//
//  Created on 2025-12-22
//

import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workout: Workout

    @State private var exerciseName: String = ""
    @State private var targetWeight: String = ""
    @State private var targetRepsMin: String = ""
    @State private var targetRepsMax: String = ""
    @State private var numberOfSets: String = ""
    @State private var exerciseNotes: String = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case name, weight, repsMin, repsMax, sets, notes
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
                } footer: {
                    Text("e.g., Bench Press, Squat, Deadlift, Pull-ups")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
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
                } footer: {
                    Text("Starting weight for this exercise")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
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
                } footer: {
                    Text("Target rep range per set (e.g., 6-8, 8-12)")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
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
                } footer: {
                    Text("How many sets per workout")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
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
                } footer: {
                    Text("e.g., Pause at bottom, rest-pause on last set, tempo")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    VStack(spacing: 12) {
                        Button {
                            saveExercise(andAddAnother: false)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Save & Exit")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.summitOrange)
                        .disabled(!isFormValid)

                        Button {
                            saveExercise(andAddAnother: true)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Save & Add Another")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.summitOrange)
                        .disabled(!isFormValid)
                    }
                    .listRowBackground(Color.clear)
                }
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

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundStyle(Color.summitOrange)
                }
            }
        }
    }

    private func saveExercise(andAddAnother: Bool) {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = exerciseNotes.trimmingCharacters(in: .whitespaces)

        guard let weight = Double(targetWeight),
              let repsMin = Int(targetRepsMin),
              let repsMax = Int(targetRepsMax),
              let sets = Int(numberOfSets) else {
            return
        }

        let newExercise = Exercise(
            name: trimmedName,
            targetWeight: weight,
            targetRepsMin: repsMin,
            targetRepsMax: repsMax,
            numberOfSets: sets,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            orderIndex: workout.exercises.count,
            workout: workout
        )

        modelContext.insert(newExercise)

        do {
            try modelContext.save()

            if andAddAnother {
                // Clear form for next exercise
                exerciseName = ""
                targetWeight = ""
                targetRepsMin = ""
                targetRepsMax = ""
                numberOfSets = ""
                exerciseNotes = ""
                focusedField = .name
            } else {
                dismiss()
            }
        } catch {
            print("Error saving exercise: \(error)")
        }
    }
}

#Preview {
    CreateExerciseView(workout: {
        let workout = Workout(name: "Push Day", orderIndex: 0)
        return workout
    }())
    .modelContainer(ModelContainer.preview)
}
