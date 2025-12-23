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
                        .foregroundStyle(Color.summitTextSecondary)
                } footer: {
                    Text("e.g., Push Pull Legs, Upper Lower, Full Body")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    TextField("Description (optional)", text: $planDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.body)
                } header: {
                    Text("Description")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                } footer: {
                    Text("Add notes about your training plan, focus areas, or goals")
                        .font(.caption)
                        .foregroundStyle(Color.summitTextTertiary)
                }
                .listRowBackground(Color.summitCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle("New Workout Plan")
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
                        createPlan()
                    }
                    .disabled(planName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(planName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.summitTextTertiary : Color.summitOrange)
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
