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
            ZStack {
                formBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        formHeader

                        fieldCard(
                            title: "Name",
                            helper: "Update the workout name shown in your plan."
                        ) {
                            TextField("Workout Name", text: $workoutName)
                                .textInputAutocapitalization(.words)
                        }

                        fieldCard(
                            title: "Notes",
                            helper: "Optional notes about focus areas, intensity, or cues."
                        ) {
                            TextField("Notes (optional)", text: $workoutNotes, axis: .vertical)
                                .lineLimit(2...4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Edit workout")
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
