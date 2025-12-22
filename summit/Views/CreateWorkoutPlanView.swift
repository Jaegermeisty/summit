//
//  CreateWorkoutPlanView.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct CreateWorkoutPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var planName: String = ""
    @State private var planDescription: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Plan Name", text: $planName)
                        .font(.body)
                } header: {
                    Text("Name")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("e.g., Push Pull Legs, Upper Lower, Full Body")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    TextField("Description (optional)", text: $planDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                } header: {
                    Text("Description")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Add notes about your training plan, focus areas, or goals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Workout Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPlan()
                    }
                    .disabled(planName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func createPlan() {
        let trimmedName = planName.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = planDescription.trimmingCharacters(in: .whitespaces)

        // Check if there are any existing plans
        let descriptor = FetchDescriptor<WorkoutPlan>()
        let existingPlans = (try? modelContext.fetch(descriptor)) ?? []

        // First plan is active, subsequent plans are inactive
        let isActive = existingPlans.isEmpty

        let newPlan = WorkoutPlan(
            name: trimmedName,
            planDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
            isActive: isActive
        )

        modelContext.insert(newPlan)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving plan: \(error)")
        }
    }
}

#Preview {
    CreateWorkoutPlanView()
        .modelContainer(ModelContainer.preview)
}
