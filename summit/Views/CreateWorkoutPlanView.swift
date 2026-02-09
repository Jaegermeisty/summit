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
            ZStack {
                formBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        formHeader

                        fieldCard(
                            title: "Name",
                            helper: "e.g., Push Pull Legs, Upper Lower, Full Body"
                        ) {
                            TextField("Plan Name", text: $planName)
                                .textInputAutocapitalization(.words)
                        }

                        fieldCard(
                            title: "Description",
                            helper: "Add notes about your training plan, focus areas, or goals"
                        ) {
                            TextField("Description (optional)", text: $planDescription, axis: .vertical)
                                .lineLimit(3...6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
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

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create a plan")
                .font(.custom("Avenir Next", size: 22))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)
        }
    }

    private func fieldCard<Content: View>(
        title: String,
        helper: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("Avenir Next", size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitTextSecondary)

            content()
                .font(.custom("Avenir Next", size: 16))
                .foregroundStyle(Color.summitText)
                .accentColor(Color.summitOrange)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.summitCardElevated)
                )

            Text(helper)
                .font(.custom("Avenir Next", size: 12))
                .foregroundStyle(Color.summitTextTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var formBackground: some View {
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
                .fill(Color.summitOrange.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 140, y: -140)
        }
        .ignoresSafeArea()
    }
    
    private func createPlan() {
        let trimmedName = planName.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = planDescription.trimmingCharacters(in: .whitespaces)
        let hasActivePlan = DataHelpers.activeWorkoutPlan(in: modelContext) != nil
        let newPlan = WorkoutPlan(
            name: trimmedName,
            planDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
            isActive: !hasActivePlan
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
