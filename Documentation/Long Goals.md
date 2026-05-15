# Long Goals Implementation & Calculation Documentation

This document provides a comprehensive technical overview of the `long_goals` feature, detailing the database schema, data calculation logic, and file-by-file breakdown.

## 1. Database Schema & Data Mapping

All long goal data is stored in the `long_goals` table, utilizing JSONB columns for complex structures. Data is synchronized using [PowerSync](file:///c:/qoderProjects/the_time_chart/lib/services/powersync_service.dart).

### Table: `long_goals`
Located in [long_goals.sql](file:///c:/qoderProjects/the_time_chart/packages/Task_Goal/long_goals.sql).

| Column | Data Type | Model Mapping | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | `id` | Primary key. |
| `user_id` | UUID | `userId` | Reference to the owner. |
| `category_id` | UUID | `categoryId` | Optional category reference. |
| `title` | TEXT | `title` | Goal name. |
| `category_type` | TEXT | `categoryType` | Main category (Health, Career, etc.). |
| `sub_types` | TEXT | `subTypes` | Sub-categories. |
| `description` | JSONB | `GoalDescription` | `need`, `motivation`, `outcome`. |
| `timeline` | JSONB | `GoalTimeline` | `startDate`, `endDate`, and `workSchedule` (days, hours/day). |
| `indicators` | JSONB | `Indicators` | `status`, `priority`, `longGoalColor`, and `weeklyPlans`. |
| `metrics` | JSONB | `GoalMetrics` | `totalDays`, `completedDays`, `tasksPending`, and `weeklyMetrics`. |
| `analysis` | JSONB | `GoalAnalysis` | `averageProgress`, `averageRating`, `pointsEarned`, `rewardPackage`. |
| `goal_log` | JSONB | `List<WeeklyGoalLog>` | Historical feedback entries organized by week. |
| `social_info` | JSONB | `SocialInfo` | Public post information. |
| `share_info` | JSONB | `ShareInfo` | Chat sharing data. |

---

## 2. Calculation Logic

The core logic resides in [long_goal_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/long_goal/models/long_goal_model.dart). Metrics are updated via the `recalculate()` method.

### Metric Calculations

| Metric | Calculation Logic | Equation |
| :--- | :--- | :--- |
| **Points Earned** | Sum of bonuses (Feedback Base, Media, Completion +40, Duration, Milestone +20 per 25% progress). | $\sum \text{Bonuses}$ |
| **Penalty** | Overdue (-10/hr), Inactivity (-10 per 3 days). | $D = \sum \text{Penalties}$ |
| **Progress** | Net points after penalties. | $P = \text{clamp}(Points - Penalties, 0, 100)$ |
| **Consistency** | **Variance-aware** stability score. | $C = \mu_{progress} - \sigma_{progress}$ |
| **Rating** | Universal formula: `1.0 + 4.0 * (progress / 100)`. | $R = 1.0 + 4.0 \times (\frac{P}{100})$ |

### Consistency Scoring Detail
The `LongGoalModel` now uses standard deviation ($\sigma$) to penalize inconsistent "burst" performance. 
- A user with consistent $[80, 80, 80]$ progress will have a higher Consistency score than $[100, 40, 100]$, even if the average is the same.
- $C = \text{AverageProgress} - \text{StandardDeviation}$

### AI Authenticity Verification
- **Goal Verification**: Every daily log is optionally verified by AI via `LongGoalAIService.verifyDailyProgress`.
- **Logic**: The AI checks if the `feedbackText` and `media` are relevant to the goal's `need` and `outcome`.
- **Fail Impact**: If `is_authentic` is false, for that day: Progress = 0, Points = 0, and the day is marked as `incomplete`.

### Reward & Tier System
Integrated with [RewardManager](file:///c:/qoderProjects/the_time_chart/lib/reward_tags/reward_manager.dart).
- Calculates a `RewardPackage` based on progress, completed days, and "task stack" (streaks).
- Assigns one of 8 tiers and unique tags/badges.

---

## 3. File Directory Breakdown

Files are located under [long_goal](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/long_goal/).

### Core Architecture
- **[models/long_goal_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/long_goal/models/long_goal_model.dart)**
    - **Purpose**: Defines the data structures and `recalculate()` math.
- **[providers/long_goals_provider.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/long_goal/providers/long_goals_provider.dart)**
    - **Purpose**: UI state manager. Handles creates, updates, and navigation.
- **[repositories/long_goals_repository.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/long_goal/repositories/long_goals_repository.dart)**
    - **Purpose**: Database interface. Maps model JSON to the `long_goals` table.
- **[services/long_goal_ai_service.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/long_goal/services/long_goal_ai_service.dart)**
    - **Purpose**: AI Integration. Verifies feedback, generates captions, and suggests weekly plans.

### UI Components
- **Screens**:
    - `long_goals_home_screen.dart`: Dashboard view of all goals.
    - `long_goal_detail_screen.dart`: Deep dive into metrics, timeline, and weekly logs.
    - `create_goal_screen.dart`: Multi-step form for goal setting.
    - `add_feedback_screen.dart`: Interface for logging progress.
- **Widgets**:
    - `long_goal_card.dart`: Interactive summary card for list views.
    - `long_goal_calendar_widget.dart`: Monthly view of progress streaks.
    - `weekly_checklist_preview.dart`: Summary of upcoming milestones.
    - `long_goals_options_menu.dart`: Actions (Edit, Post, Delete, Status change).
