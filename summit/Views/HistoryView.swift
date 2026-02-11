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
    @State private var displayLimit = 5
    @Query(
        filter: #Predicate<WorkoutSession> { session in
            session.isCompleted == true
        },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var sessions: [WorkoutSession]

    var body: some View {
        ZStack {
            historyBackground

            Group {
                if purchaseManager.isPro {
                    List {
                        Section {
                            if sessions.isEmpty {
                                ContentUnavailableView {
                                    Label("No History Yet", systemImage: "clock")
                                        .foregroundStyle(Color.summitText)
                                } description: {
                                    Text("Complete a workout to see it here")
                                        .foregroundStyle(Color.summitTextSecondary)
                                }
                                .listRowBackground(Color.clear)
                            } else {
                                ForEach(sessions.prefix(displayLimit)) { session in
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
                                    .listRowSeparator(.hidden)
                                }

                                if displayLimit < sessions.count {
                                    Button {
                                        displayLimit += 5
                                    } label: {
                                        HStack {
                                            Spacer()
                                            Text("Show more")
                                                .font(.custom("Avenir Next", size: 14))
                                                .foregroundStyle(Color.summitOrange)
                                            Spacer()
                                        }
                                    }
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
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
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                    .listRowSeparatorTint(.clear)
                    .listSectionSeparatorTint(.clear)
                } else {
                    List {
                        Section {
                            if let lastSession = sessions.first {
                                NavigationLink {
                                    if let workout = DataHelpers.workout(with: lastSession.workoutTemplateId, in: modelContext) {
                                        WorkoutSessionView(session: lastSession, workout: workout)
                                    } else {
                                        WorkoutSessionView(session: lastSession, workout: Workout(name: lastSession.workoutTemplateName))
                                    }
                                } label: {
                                    HistoryRowView(session: lastSession)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } else {
                                ContentUnavailableView {
                                    Label("No History Yet", systemImage: "clock")
                                        .foregroundStyle(Color.summitText)
                                } description: {
                                    Text("Complete a workout to see it here")
                                        .foregroundStyle(Color.summitTextSecondary)
                                }
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text("Last Session")
                                .textCase(nil)
                                .font(.custom("Avenir Next", size: 16))
                                .foregroundStyle(Color.summitTextSecondary)
                        }

                        Section {
                            HistoryUpsellCard(
                                title: "Unlock History",
                                subtitle: "See every session and unlock analytics.",
                                features: [
                                    "Full workout history",
                                    "Session details",
                                    "Plan and exercise analytics"
                                ],
                                primaryTitle: "Unlock Pro",
                                primaryAction: {
                                    Task { await purchaseManager.purchase() }
                                },
                                restoreAction: {
                                    Task { await purchaseManager.restorePurchases() }
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                    .listRowSeparatorTint(.clear)
                    .listSectionSeparatorTint(.clear)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            dismissKeyboard()
            displayLimit = 5
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

struct HistoryUpsellCard: View {
    let title: String
    let subtitle: String
    let features: [String]
    let primaryTitle: String
    let primaryAction: () -> Void
    let restoreAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.summitOrange.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.summitOrange)
                }

                Text(title)
                    .font(.custom("Avenir Next", size: 20))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.summitText)

                Text(subtitle)
                    .font(.custom("Avenir Next", size: 13))
                    .foregroundStyle(Color.summitTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.summitOrange)
                        Text(item)
                            .font(.custom("Avenir Next", size: 13))
                            .foregroundStyle(Color.summitText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.summitCardElevated)
            )

            Button {
                primaryAction()
            } label: {
                Text(primaryTitle)
                    .font(.custom("Avenir Next", size: 15))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.summitBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.summitOrange)
                    )
            }
            .buttonStyle(.plain)

            Button("Restore Purchase") {
                restoreAction()
            }
            .font(.custom("Avenir Next", size: 12))
            .foregroundStyle(Color.summitTextTertiary)
        }
        .padding(18)
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
