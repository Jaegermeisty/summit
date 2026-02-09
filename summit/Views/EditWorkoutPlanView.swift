//
//  EditWorkoutPlanView.swift
//  Summit
//
//  Created on 2026-02-09
//

import SwiftUI
import SwiftData

struct EditWorkoutPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var plan: WorkoutPlan

    @State private var planName: String
    @State private var planDescription: String

    init(plan: WorkoutPlan) {
        _plan = Bindable(wrappedValue: plan)
        _planName = State(initialValue: plan.name)
        _planDescription = State(initialValue: plan.planDescription ?? "")
    }

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
                }
                .listRowBackground(Color.summitCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.summitBackground)
            .navigationTitle("Edit Plan")
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
                    .disabled(planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.summitTextTertiary : Color.summitOrange)
                }
            }
        }
    }

    private func saveChanges() {
        let trimmedName = planName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = planDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        plan.name = trimmedName
        plan.planDescription = trimmedDescription.isEmpty ? nil : trimmedDescription

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving plan edits: \(error)")
        }
    }
}

#Preview {
    EditWorkoutPlanView(plan: WorkoutPlan(name: "Push Pull Legs"))
        .modelContainer(ModelContainer.preview)
}
