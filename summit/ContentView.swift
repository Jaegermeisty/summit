//
//  ContentView.swift
//  GymTrack
//
//  Created on 2025-10-14
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var workoutPlans: [WorkoutPlan]
    
    @State private var showingCreatePlan = false
    
    var body: some View {
        NavigationStack {
            Group {
                if workoutPlans.isEmpty {
                    emptyStateView
                } else {
                    planListView
                }
            }
            .navigationTitle("GymTrack")
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
    
    private var planListView: some View {
        List {
            ForEach(workoutPlans) { plan in
                NavigationLink(destination: WorkoutPlanDetailView(plan: plan)) {
                    PlanRowView(plan: plan)
                }
            }
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

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
