//
//  EditPhaseView.swift
//  Summit
//
//  Created on 2026-02-09
//

import SwiftUI
import SwiftData

struct EditPhaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var phase: PlanPhase

    @State private var phaseName: String
    @State private var phaseNotes: String

    init(phase: PlanPhase) {
        _phase = Bindable(wrappedValue: phase)
        _phaseName = State(initialValue: phase.name)
        _phaseNotes = State(initialValue: phase.notes ?? "")
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
                            helper: "Rename this phase as it appears in your plan."
                        ) {
                            TextField("Phase Name", text: $phaseName)
                                .textInputAutocapitalization(.words)
                        }

                        fieldCard(
                            title: "Notes",
                            helper: "Optional notes about how long to run this phase."
                        ) {
                            TextField("Notes (optional)", text: $phaseNotes, axis: .vertical)
                                .lineLimit(2...4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Edit Phase")
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
                    .disabled(phaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(phaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.summitTextTertiary : Color.summitOrange)
                }
            }
        }
    }

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Edit phase")
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
        let trimmedName = phaseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = phaseNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        phase.name = trimmedName
        phase.notes = trimmedNotes.isEmpty ? nil : trimmedNotes

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving phase edits: \(error)")
        }
    }
}

#Preview {
    EditPhaseView(phase: PlanPhase(name: "Phase 1", orderIndex: 0))
        .modelContainer(ModelContainer.preview)
}
