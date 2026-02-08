//
//  AnalyticsView.swift
//  Summit
//
//  Created on 2026-02-08
//

import SwiftUI
import SwiftData
import Charts

private enum AnalyticsMode: String, CaseIterable, Identifiable {
    case exercise = "Exercise"
    case plan = "Plan"

    var id: String { rawValue }
}

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseDefinition.name, order: .forward) private var definitions: [ExerciseDefinition]
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]

    @State private var mode: AnalyticsMode = .exercise
    @State private var selectedExerciseId: UUID?
    @State private var selectedPlanId: UUID?

    @State private var exerciseSeries: [ExerciseMetricPoint] = []
    @State private var planSeries: [PlanMetricPoint] = []

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                ForEach(AnalyticsMode.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if mode == .exercise {
                exerciseSection
            } else {
                planSection
            }

            Spacer()
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedExerciseId == nil {
                selectedExerciseId = definitions.first?.id
            }
            if selectedPlanId == nil {
                selectedPlanId = plans.first?.id
            }
            reloadExerciseSeries()
            reloadPlanSeries()
        }
        .onChange(of: selectedExerciseId) { _, _ in
            reloadExerciseSeries()
        }
        .onChange(of: selectedPlanId) { _, _ in
            reloadPlanSeries()
        }
    }

    private var exerciseSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Exercise")
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)

                Spacer()

                Picker("Exercise", selection: $selectedExerciseId) {
                    ForEach(definitions) { definition in
                        Text(definition.name).tag(Optional(definition.id))
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            if exerciseSeries.isEmpty {
                ContentUnavailableView {
                    Label("No Exercise Data", systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text("Complete a workout to see your progress here")
                }
                .padding(.top, 20)
            } else {
                Chart(exerciseSeries) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.oneRepMax)
                    )
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.oneRepMax)
                    )
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 260)
                .padding(.horizontal)
            }
        }
    }

    private var planSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Plan")
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)

                Spacer()

                Picker("Plan", selection: $selectedPlanId) {
                    ForEach(plans) { plan in
                        Text(plan.name).tag(Optional(plan.id))
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            if planSeries.isEmpty {
                ContentUnavailableView {
                    Label("No Plan Data", systemImage: "chart.bar.xaxis")
                } description: {
                    Text("Complete workouts in this plan to see progress")
                }
                .padding(.top, 20)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan Strength Score")
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                        .padding(.horizontal)

                    Chart(planSeries) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Strength", point.strengthScore)
                        )
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Strength", point.strengthScore)
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 220)
                    .padding(.horizontal)

                    Text("Plan Volume")
                        .font(.subheadline)
                        .foregroundStyle(Color.summitTextSecondary)
                        .padding(.horizontal)

                    Chart(planSeries) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic) { value in
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 220)
                    .padding(.horizontal)
                }
            }
        }
    }

    private func reloadExerciseSeries() {
        guard let selectedExerciseId,
              let definition = definitions.first(where: { $0.id == selectedExerciseId }) else {
            exerciseSeries = []
            return
        }

        let logs = DataHelpers.exerciseHistory(for: definition.name, in: modelContext)
        let points = logs.compactMap { log -> ExerciseMetricPoint? in
            guard let session = log.session, session.isCompleted else { return nil }
            return ExerciseMetricPoint(
                date: session.date,
                oneRepMax: log.estimatedOneRepMax
            )
        }
        exerciseSeries = points.sorted(by: { $0.date < $1.date })
    }

    private func reloadPlanSeries() {
        guard let selectedPlanId,
              let plan = plans.first(where: { $0.id == selectedPlanId }) else {
            planSeries = []
            return
        }

        let sessions = DataHelpers.completedSessions(for: plan, in: modelContext)
        var points: [PlanMetricPoint] = []

        for session in sessions {
            let logs = DataHelpers.logs(for: session, in: modelContext)
            let avgStrength: Double
            if logs.isEmpty {
                avgStrength = 0
            } else {
                let totalStrength = logs.reduce(0.0) { partial, log in
                    partial + log.estimatedOneRepMax
                }
                avgStrength = totalStrength / Double(logs.count)
            }
            let volume = logs.reduce(0.0) { partial, log in
                partial + (log.weight * Double(log.reps.reduce(0, +)))
            }
            points.append(PlanMetricPoint(date: session.date, volume: volume, strengthScore: avgStrength))
        }

        planSeries = points.sorted(by: { $0.date < $1.date })
    }
}

private struct ExerciseMetricPoint: Identifiable {
    let id = UUID()
    let date: Date
    let oneRepMax: Double
}

private struct PlanMetricPoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
    let strengthScore: Double
}

#Preview {
    NavigationStack {
        AnalyticsView()
            .modelContainer(ModelContainer.preview)
    }
}
