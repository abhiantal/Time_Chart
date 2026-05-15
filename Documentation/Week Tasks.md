# Week Task Implementation & Calculation Documentation

This document provides a comprehensive technical overview of the `week_task` feature, detailing the database schema, data calculation logic, and file-by-file breakdown.

## 1. Database Schema & Data Mapping

All week task data is stored in the `weekly_tasks` table. It uses JSONB columns to handle complex nested data.

### Table: `weekly_tasks`
Located in [weekly_tasks.sql](file:///c:/qoderProjects/the_time_chart/packages/Task_Goal/weekly_tasks.sql).

| Column | Data Type | Model Mapping | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | `id` | Primary key. |
| `user_id` | UUID | `userId` | Reference to the owner. |
| `category_id` | UUID | `categoryId` | Optional category reference. |
| `category_type` | TEXT | `categoryType` | Main category (Health, Career, etc.). |
| `sub_types` | TEXT | `subTypes` | Sub-categories. |
| `about_task` | JSONB | `AboutTask` | `taskName`, `taskDescription`, `mediaUrl`. |
| `indicators` | JSONB | `Indicators` | `status`, `priority`. |
| `timeline` | JSONB | `TaskTimeline` | `taskDays`, `startingDate`, `expectedEndingDate`, `startingTime`, `endingTime`, `taskDuration`. |
| `feedback` | JSONB | `List<DailyProgress>` | Daily logs contain `feedbacks` (media + text) and `dailyMetrics`. |
| `metadata` | JSONB | `WeeklySummary` | `progress`, `pointsEarned`, `rating`, `completedDays`, `rewardPackage`. |
| `social_info` | JSONB | `SocialInfo` | Public post information. |
| `share_info` | JSONB | `ShareInfo` | Chat sharing data. |

---

## 2. Calculation Logic

The logic is split between daily progress (tracked per day) and the weekly summary (aggregated). Core methods are in [week_task_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/week_task/models/week_task_model.dart).

### Daily Metrics (`DayMetrics`)
Calculated inside each day's `DailyProgress` after the task duration has ended.

| Metric | Calculation Logic | Points |
| :--- | :--- | :--- |
| **Feedback** | `feedbackCount * 5` | +5 per entry |
| **Media** | `mediaCount * 5` | +5 per media |
| **Text** | `wordCount * 3` | +3 per word |
| **Priority** | High: 15, Medium: 10, Low: 5 | +5/10/15 |
| **On-Time** | Feedback submitted between start and end time | +20 |
| **Duration** | Bonus based on total task duration `d` | +5 to +100 |
| **Slot Penalty** | Missed 4-min feedback window every 20 mins | -10 per slot |
| **Missed Rule** | No feedback submitted by end of task | -100 (Final) |

**Final Score Calculation**:
`final_score = points_earned (positive) - penalty (negative)`

### Weekly Summary (`WeeklySummary`)
Aggregates daily data and tracks long-term consistency.

| Metric | Calculation Logic | Equation |
| :--- | :--- | :--- |
| **Global Progress** | Average of scheduled day progress. | $P_{avg} = \frac{\sum P_{day}}{N_{scheduled}}$ |
| **Consistency Score**| Percentage of scheduled days completed. | $C = \frac{N_{completed}}{N_{scheduled}} \times 100$ |
| **Total Points** | Total points across the week. | $\sum \text{Points}_{day}$ |
| **Rating** | Universal formula applied to Global Progress. | $R_{avg} = 1.0 + 4.0 \times (\frac{P_{avg}}{100})$ |

### AI Integration
- **Daily Verification**: Uses `UniversalAIService` to compare `taskDescription` against `mediaUrls` and `feedbackText`. Updates `isPass` and `verificationReason`.
- **Timing**: AI verification runs once per task session after completion to optimize token usage.

---

## 3. File Directory Breakdown

Files are located under [week_task](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/week_task/).

### Core Architecture
- **[models/week_task_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/week_task/models/week_task_model.dart)**
    - **Purpose**: Defines the `WeekTaskModel` and sub-models. Handles the `recalculate()` loop.
- **[providers/week_task_provider.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/week_task/providers/week_task_provider.dart)**
    - **Purpose**: High-level state management. Orchestrates feedback submission and holds cooling-down timers.
- **[repositories/week_task_repository.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/week_task/repositories/week_task_repository.dart)**
    - **Purpose**: Database interface. Handles JSONB column parsing and `autoMarkMissedDays()` background logic.
- **[services/weekly_task_ai_service.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/week_task/services/weekly_task_ai_service.dart)**
    - **Purpose**: AI Service for generating social captions and performance suggestions.

### UI Components
- **Screens**:
    - `weekly_schedule_screen.dart`: Main dashboard for the week.
    - `week_task_detail_screen.dart`: Detailed view of a single task's performance.
    - `add_weekly_task_screen.dart`: Form to create new weekly habits/tasks.
    - `add_feedback_screen.dart`: UI for logging progress.
    - `weekly_analysis_screen.dart`: AI-powered performance analysis view.
- **Widgets**:
    - `grid_task_card.dart`: Compact visual representation of a task.
    - `week_task_calendar_widget.dart`: Calendar view of completion streaks.
    - `weekly_task_options_menu.dart`: Actions (Hold, Continue, Delete, Post).
    - `time_slot_manager_dialog.dart`: UI for managing scheduled hours.
