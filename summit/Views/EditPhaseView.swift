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
            Form {
                Section {
                    TextField("Phase Name", text: $phaseName)
                        .font(.body)
                } header: {
                    Text("Name")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                }
                .listRowBackground(Color.summitCard)

                Section {
                    TextField("Notes (optional)", text: $phaseNotes, axis: .vertical)
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
            .navigationTitle("Edit Phase")
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
                    .disabled(phaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(phaseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.summitTextTertiary : Color.summitOrange)
                }
            }
        }
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
