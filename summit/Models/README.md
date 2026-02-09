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
- On launch, the home screen should surface **"Start Next Workout"** based on the last completed session.
- Users can still manually pick a different workout if they want to skip or change the order.
- Analytics should support **global exercise history** across all plans (e.g., Bench Press progress continues even after switching plans).
- During a workout, show **last performance for this specific workout day** (same exercise template), not global history.
- Plans can optionally be split into **phases (blocks)** with a single active phase used for the next-workout rotation.

## Current Implementation (What Exists Today)

- SwiftData models for plans, phases, workouts, exercises, sessions, logs, and body weight.
- Shared and preview model containers with sample data.
- Canonical exercise catalog with case-insensitive matching and suggestions.
- Auto-fill target weight from last known template/log (when creating exercises).
- Active plan card on Home with "Start Workout".
- Session flow with per-set logging and last performance per workout/day.
- History list (last 5 completed sessions) with edit capability.
- Session completion toast on finish.
- Phases (blocks) for plans, with active phase selection and phase-aware next workout.
- Tab bar navigation (Home + Analytics tabs).
- Analytics screen:
  - Exercise progress (1RM) over time
  - Plan strength score and volume over time

## Planned / In-Scope Next Steps

These are **intended features**, not yet implemented:

- Paywall:
  - Free: create plans/workouts, track a session in-progress
  - Pro (one-time purchase): persistent history + analytics
  - Data only starts being saved **after** purchase; no retroactive history
  - In-progress session data should persist even if the app is backgrounded or closed
- Plan comparison view
- Phase management polish (multi-select move/copy, phase rename)

## MVP Roadmap (Checklist)

Foundation
- [x] Core SwiftData models + relationships
- [x] Shared + preview model containers
- [x] Plan list + create plan UI
- [x] Plan detail + create workout UI
- [x] Add exercise creation UI
- [x] Add exercise editing UI
- [x] Active plan selection (single active plan)
- [x] Home screen "Start Next Workout"
- [x] Plan phases (blocks) + active phase selection
- [x] Tab bar navigation (Home + Analytics)

Logging
- [x] Start/continue workout session flow
- [x] Per-set logging UI (weight + reps)
- [x] Show last performance for the **same workout/day** (exercise template) to guide weight selection
- [x] Persist session progress during app background/close
- [ ] Gate history saving behind Pro (currently saves for all users)
- [x] History list of recent workouts with edit capability (without changing original date)
- [x] Session completed toast

Analytics (Pro)
- [x] Exercise history graph (per exercise)
- [x] Global exercise history across all plans (same exercise name aggregates)
- [x] Plan-level progress graph (strength score + volume)
- [ ] Plan comparison view

Monetization
- [ ] One-time purchase paywall gating history + analytics

## Next Up (Prioritized)

1. Add paywall gating for history saving + analytics (one-time purchase).
2. Plan comparison view (side-by-side or overlay charts).
3. Phase management polish:
   - Rename phase
   - Multi-select move/copy workouts between phases
4. Exercise search + selector polish in Analytics (filters, favorites).

## Model Files

### Core Models
- `WorkoutPlan.swift` -- top-level program container (includes `isActive`)
- `PlanPhase.swift` -- phase/block within a plan (includes `isActive`, linked via `planId`)
- `Workout.swift` -- workout day within a plan (linked via `planId`, optionally `phaseId`)
- `ExerciseDefinition.swift` -- canonical exercise catalog entry (case-insensitive unique)
- `Exercise.swift` -- exercise template within a workout (has `workoutId` for queries + `@Relationship` for cascade delete)
- `WorkoutSession.swift` -- completed workout instance (historical record)
- `ExerciseLog.swift` -- logged exercise data (weight + reps per set, has `sessionId` for queries + `@Relationship` for cascade delete)
- `BodyWeightLog.swift` -- body weight tracking over time

### Utilities
- `ModelContainer+Extensions.swift` -- shared + preview SwiftData containers
- `DataHelpers.swift` -- helper queries (active plan, next workout, history)

## Data Model Relationships

```
WorkoutPlan
   +-- (many) PlanPhase     [linked by PlanPhase.planId]
   +-- (many) Workout       [linked by Workout.planId]
                                  +-- Workout.phaseId -> PlanPhase (optional)
                                  +-- (many) Exercise [@Relationship + Exercise.workoutId]
                                        +-- ExerciseDefinition

WorkoutSession --references--> Workout (by template ID)
    +-- (many) ExerciseLog [@Relationship + ExerciseLog.sessionId]
          +-- ExerciseDefinition

BodyWeightLog (independent)
```

**IMPORTANT:** WorkoutPlan, PlanPhase, and Workout are linked by plain UUID fields (NOT `@Relationship`). This is intentional -- see "SwiftData Known Issues" in INSTRUCTIONS.md. Exercise and ExerciseLog have both a plain UUID field (for query predicates) AND a `@Relationship` (for cascade delete).

## Storage

The app currently uses **local SwiftData persistence** via `ModelContainer.shared` (not in-memory). There is no iCloud sync configured yet.

## Notes

- All IDs are UUIDs for future compatibility.
- `WorkoutSession` stores template IDs and names to preserve history if templates change.
- `ExerciseDefinition` provides a canonical, case-insensitive exercise identity (global history across plans).
- `ExerciseLog` references `ExerciseDefinition` for consistent analytics across plans.
- `normalizedName` is used to match exercises ignoring case and extra whitespace.
- `orderIndex` fields maintain stable ordering for workouts and exercises.
- **Never use relationship traversal in `#Predicate`** (e.g., `$0.workout?.id`). Always use plain UUID fields (e.g., `$0.workoutId`). See INSTRUCTIONS.md for details.
- **Avoid `@Query` in views pushed by NavigationLink.** Use `FetchDescriptor` + `.onAppear` instead. See INSTRUCTIONS.md for details.
