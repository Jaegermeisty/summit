//
//  ContentView.swift
//  summit
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var workoutPlans: [WorkoutPlan]

    @State private var showingCreatePlan = false
    @State private var showingActiveWorkout = false
    @State private var planToDelete: WorkoutPlan?
    @State private var showingDeleteConfirmation = false

    var activePlan: WorkoutPlan? {
        workoutPlans.first(where: { $0.isActive })
    }

    var otherPlans: [WorkoutPlan] {
        workoutPlans.filter { !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workoutPlans.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Summit")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreatePlan = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreateWorkoutPlanView()
            }
            .sheet(isPresented: $showingActiveWorkout) {
                if let plan = activePlan,
                   let nextWorkout = DataHelpers.nextWorkout(in: plan, context: modelContext) {
                    ActiveWorkoutSessionView(workout: nextWorkout, plan: plan)
                }
            }
            .alert("Delete Workout Plan", isPresented: $showingDeleteConfirmation, presenting: planToDelete) { plan in
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePlan(plan)
                }
            } message: { plan in
                Text("Are you sure you want to delete '\(plan.name)'? All workouts and exercises in this plan will be permanently deleted. This cannot be undone.")
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Workout Plans", systemImage: "figure.strengthtraining.traditional")
        } description: {
            Text("Create your first workout plan to start tracking your progress")
        } actions: {
            Button {
                showingCreatePlan = true
            } label: {
                Text("Create Plan")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var mainContentView: some View {
        List {
            // Active Plan Section
            if let active = activePlan {
                Section {
                    ActivePlanCardView(
                        plan: active,
                        nextWorkout: DataHelpers.nextWorkout(in: active, context: modelContext),
                        onStartWorkout: {
                            showingActiveWorkout = true
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .contextMenu {
                        Button(role: .destructive) {
                            planToDelete = active
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Plan", systemImage: "trash")
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Plan")
                            .textCase(nil)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Rectangle()
                            .fill(Color.orange.opacity(0.8))
                            .frame(height: 2)
                    }
                    .padding(.bottom, 4)
                }
            }

            // Other Plans Section
            if !otherPlans.isEmpty {
                Section {
                    ForEach(otherPlans) { plan in
                        NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                            PlanRowView(plan: plan)
                        }
                        .contextMenu {
                            Button {
                                setActivePlan(plan)
                            } label: {
                                Label("Set as Active", systemImage: "star.fill")
                            }

                            Button(role: .destructive) {
                                planToDelete = plan
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Plan", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteOtherPlans)
                } header: {
                    Text("Other Plans")
                        .textCase(nil)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Swipe left to delete • Long press to set active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func deleteOtherPlans(at offsets: IndexSet) {
        for index in offsets {
            let plan = otherPlans[index]
            planToDelete = plan
            showingDeleteConfirmation = true
        }
    }

    private func deletePlan(_ plan: WorkoutPlan) {
        modelContext.delete(plan)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting plan: \(error)")
        }
    }

    private func setActivePlan(_ plan: WorkoutPlan) {
        // Deactivate all plans
        for p in workoutPlans {
            p.isActive = false
        }

        // Activate the selected plan
        plan.isActive = true

        do {
            try modelContext.save()
        } catch {
            print("Error setting active plan: \(error)")
        }
    }
}

struct PlanRowView: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                
                if plan.isActive {
                    Spacer()
                    
                    Text("Active")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.8))
                        )
                }
            }
            
            if let description = plan.planDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 12) {
                Label("\(plan.workouts.count)", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(plan.workouts.count == 1 ? "workout" : "workouts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivePlanCardView: View {
    let plan: WorkoutPlan
    let nextWorkout: Workout?
    let onStartWorkout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Plan info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(plan.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                if let description = plan.planDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Label("\(plan.workouts.count)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(plan.workouts.count == 1 ? "workout" : "workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Next workout info
            if let workout = nextWorkout {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Workout")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.name)
                                .font(.headline)

                            Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )

                // Start Workout button
                Button {
                    onStartWorkout()
                } label: {
                    HStack {
                        Spacer()
                        Label("Start Workout", systemImage: "play.fill")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            } else {
                Text("Add workouts to this plan to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
