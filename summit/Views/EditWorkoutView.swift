//
//  EditWorkoutView.swift
//  Summit
//
//  Created on 2026-02-09
//

import SwiftUI
import SwiftData

struct EditWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var workout: Workout

    @State private var workoutName: String
    @State private var workoutNotes: String

    init(workout: Workout) {
        _workout = Bindable(wrappedValue: workout)
        _workoutName = State(initialValue: workout.name)
        _workoutNotes = State(initialValue: workout.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workout Name", text: $workoutName)
                        .font(.body)
                } header: {
                    Text("Name")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    TextField("Notes (optional)", text: $workoutNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.body)
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
            .navigationTitle("Edit Workout")
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
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(workoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.summitTextTertiary : Color.summitOrange)
                }
            }
        }
    }

    private func saveChanges() {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = workoutNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        workout.name = trimmedName
        workout.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving workout edits: \(error)")
        }
    }
}

#Preview {
    EditWorkoutView(workout: Workout(name: "Push Day", notes: "Tempo focus", orderIndex: 0))
        .modelContainer(ModelContainer.preview)
}
