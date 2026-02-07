//
//  CreateWorkoutView.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct CreateWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workoutPlan: WorkoutPlan
    @Query private var existingWorkouts: [Workout]

    @State private var workoutName: String = ""
    @State private var workoutNotes: String = ""

    init(workoutPlan: WorkoutPlan) {
        self.workoutPlan = workoutPlan
        let planId = workoutPlan.id
        _existingWorkouts = Query(
            filter: #Predicate<Workout> { workout in
                workout.workoutPlan?.id == planId
            }
        )
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
                } footer: {
                    Text("e.g., Push Day, Pull Day, Leg Day, Upper Body, Day 1")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
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
                } footer: {
                    Text("Add notes about focus areas, intensity, or special instructions")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    HStack {
                        Text("Position in Plan")
                            .foregroundStyle(Color.summitTextSecondary)

                        Spacer()

                        Text("Day \(existingWorkouts.count + 1)")
                            .foregroundStyle(Color.summitText)
                    }
                } footer: {
                    Text("This workout will be added as the next day in your plan rotation")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle("New Workout")
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
                        createWorkout()
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(workoutName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.summitTextTertiary : Color.summitOrange)
                }
            }
        }
    }

    private func createWorkout() {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = workoutNotes.trimmingCharacters(in: .whitespaces)

        let newWorkout = Workout(
            name: trimmedName,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            orderIndex: existingWorkouts.count,
            workoutPlan: workoutPlan
        )

        modelContext.insert(newWorkout)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
        }
    }
}

#Preview {
    CreateWorkoutView(workoutPlan: WorkoutPlan(name: "Push Pull Legs"))
        .modelContainer(ModelContainer.preview)
}
