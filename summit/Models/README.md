# Summit Data Model & App Overview

This folder contains the SwiftData model used by the **Summit** app, plus helper utilities for querying and previews.

## Product Vision (Target Behavior)

Summit is a simple, fast workout tracker built around **plans** and an **active plan**. The intended core flow is:

1. Create a workout plan
2. Add workouts (days) to the plan
3. Add exercises to each workout
4. Start a workout session
5. Log sets/reps/weight

The app should make it effortless to train from the **active plan**:
- On launch, the home screen should surface **“Start Next Workout”** based on the last completed session.
- Users can still manually pick a different workout if they want to skip or change the order.
- Analytics should support **global exercise history** across all plans (e.g., Bench Press progress continues even after switching plans).
- During a workout, show **last performance for this specific workout day** (same exercise template), not global history.

## Current Implementation (What Exists Today)

- SwiftData models for plans, workouts, exercises, sessions, logs, and body weight.
- Shared and preview model containers with sample data.
- UI for:
  - Plan list + empty state
  - Create plan
  - Plan detail (list/delete workouts)
  - Create workout
  - Workout detail (read-only exercise list)

## Planned / In-Scope Next Steps

These are **intended features**, not yet implemented:

- Active plan selection and “Start Next Workout” on the home screen
- Workout session UI for logging sets (reps/weight)
- Exercise history + progress graphs
- Plan-level analytics and plan comparisons
- Paywall:
  - Free: create plans/workouts, track a session in-progress
  - Pro (one-time purchase): persistent history + analytics
  - Data only starts being saved **after** purchase; no retroactive history
  - In-progress session data should persist even if the app is backgrounded or closed

## MVP Roadmap (Checklist)

Foundation
- [x] Core SwiftData models + relationships
- [x] Shared + preview model containers
- [x] Plan list + create plan UI
- [x] Plan detail + create workout UI
- [x] Add exercise creation UI
- [ ] Add exercise editing UI
- [ ] Active plan selection (single active plan)
- [ ] Home screen “Start Next Workout”

Logging
- [x] Start/continue workout session flow
- [x] Per-set logging UI (weight + reps)
- [x] Show last performance for the **same workout/day** (exercise template) to guide weight selection
- [x] Persist session progress during app background/close
- [ ] Save completed session to history (Pro only)
- [x] History list of recent workouts with edit capability (without changing original date)

Analytics (Pro)
- [ ] Exercise history graph (per exercise)
- [ ] Global exercise history across all plans (same exercise name aggregates)
- [ ] Plan-level progress graph
- [ ] Plan comparison view

Monetization
- [ ] One-time purchase paywall gating history + analytics

## Model Files

### Core Models
- `WorkoutPlan.swift` — top-level program container (includes `isActive`)
- `Workout.swift` — workout day within a plan
- `ExerciseDefinition.swift` — canonical exercise catalog entry (case-insensitive unique)
- `Exercise.swift` — exercise template within a workout
- `WorkoutSession.swift` — completed workout instance (historical record)
- `ExerciseLog.swift` — logged exercise data (weight + reps per set)
- `BodyWeightLog.swift` — body weight tracking over time

### Utilities
- `ModelContainer+Extensions.swift` — shared + preview SwiftData containers
- `DataHelpers.swift` — helper queries (active plan, next workout, history)

## Data Model Relationships

```
WorkoutPlan (1) ──→ (many) Workout
                     └──→ (many) Exercise ──→ ExerciseDefinition

WorkoutSession ──references──→ Workout (template)
    │
    └──→ (many) ExerciseLog ──→ ExerciseDefinition

BodyWeightLog (independent)
```

## Storage

The app currently uses **local SwiftData persistence** via `ModelContainer.shared` (not in-memory). There is no iCloud sync configured yet.

## Notes

- All IDs are UUIDs for future compatibility.
- `WorkoutSession` stores template IDs and names to preserve history if templates change.
- `ExerciseDefinition` provides a canonical, case-insensitive exercise identity (global history across plans).
- `ExerciseLog` references `ExerciseDefinition` for consistent analytics across plans.
- `normalizedName` is used to match exercises ignoring case and extra whitespace.
- `orderIndex` fields maintain stable ordering for workouts and exercises.
