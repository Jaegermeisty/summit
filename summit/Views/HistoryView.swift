//
//  HistoryView.swift
//  Summit
//
//  Created on 2026-02-07
//

import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<WorkoutSession> { session in
            session.isCompleted == true
        },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    private var recentSessions: [WorkoutSession] {
        Array(sessions.prefix(5))
    }

    var body: some View {
        List {
            if recentSessions.isEmpty {
                ContentUnavailableView {
                    Label("No History Yet", systemImage: "clock")
                } description: {
                    Text("Complete a workout to see it here")
                }
            } else {
                ForEach(recentSessions) { session in
                    NavigationLink {
                        if let workout = DataHelpers.workout(with: session.workoutTemplateId, in: modelContext) {
                            WorkoutSessionView(session: session, workout: workout)
                        } else {
                            WorkoutSessionView(session: session, workout: Workout(name: session.workoutTemplateName))
                        }
                    } label: {
                        HistoryRowView(session: session)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            dismissKeyboard()
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct HistoryRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.workoutTemplateName)
                .font(.headline)

            if !session.workoutPlanName.isEmpty {
                Text(session.workoutPlanName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let phaseName = session.phaseName, !phaseName.isEmpty {
                Text("Phase: \(phaseName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(session.date, format: .dateTime.year().month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(ModelContainer.preview)
    }
}
