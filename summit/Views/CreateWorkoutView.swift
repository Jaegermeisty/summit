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
    
    @State private var workoutName: String = ""
    
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
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("e.g., Push Day, Pull Day, Leg Day, Upper Body, Day 1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    HStack {
                        Text("Position in Plan")
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("Day \(workoutPlan.workouts.count + 1)")
                            .foregroundStyle(.primary)
                    }
                } footer: {
                    Text("This workout will be added as the next day in your plan rotation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createWorkout()
                    }
                    .disabled(workoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createWorkout() {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespaces)
        
        let newWorkout = Workout(
            name: trimmedName,
            orderIndex: workoutPlan.workouts.count,
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
