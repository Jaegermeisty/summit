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
    @EnvironmentObject private var purchaseManager: PurchaseManager
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
        ZStack {
            historyBackground

            Group {
                if purchaseManager.isPro {
                    List {
                        Section {
                            if recentSessions.isEmpty {
                                ContentUnavailableView {
                                    Label("No History Yet", systemImage: "clock")
                                        .foregroundStyle(Color.summitText)
                                } description: {
                                    Text("Complete a workout to see it here")
                                        .foregroundStyle(Color.summitTextSecondary)
                                }
                                .listRowBackground(Color.clear)
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
                                    .listRowBackground(Color.clear)
                                }
                            }
                        } header: {
                            Text("Recent Sessions")
                                .textCase(nil)
                                .font(.custom("Avenir Next", size: 16))
                                .foregroundStyle(Color.summitTextSecondary)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                } else {
                    PaywallView(
                        title: "Unlock History",
                        subtitle: "Review your completed workouts and track long-term progress.",
                        features: [
                            "Full workout history",
                            "Session details",
                            "Progress tracking"
                        ],
                        primaryTitle: "Unlock Pro",
                        primaryAction: {
                            Task { await purchaseManager.purchase() }
                        },
                        showsRestore: true,
                        restoreAction: {
                            Task { await purchaseManager.restorePurchases() }
                        }
                    )
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

    private var historyBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.summitBackground,
                    Color(hex: "#101012")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.summitOrange.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 140, y: -120)
        }
        .ignoresSafeArea()
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.summitOrange.opacity(0.7))
                    .frame(width: 6)

                VStack(alignment: .leading, spacing: 6) {
                    Text(session.workoutTemplateName)
                        .font(.custom("Avenir Next", size: 18))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.summitText)

                    if !session.workoutPlanName.isEmpty {
                        Text(session.workoutPlanName)
                            .font(.custom("Avenir Next", size: 13))
                            .foregroundStyle(Color.summitTextSecondary)
                    }

                    if let phaseName = session.phaseName, !phaseName.isEmpty {
                        Text("Phase: \(phaseName)")
                            .font(.custom("Avenir Next", size: 12))
                            .foregroundStyle(Color.summitTextTertiary)
                    }
                }

                Spacer()

                Text(session.date, format: .dateTime.month().day())
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundStyle(Color.summitTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.summitCardElevated)
                    )
            }

            Text(session.date, format: .dateTime.year().hour().minute())
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
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(ModelContainer.preview)
            .environmentObject(PurchaseManager())
    }
}
