# Day Tasks Implementation & Calculation Documentation

This document provides a comprehensive technical overview of the `day_tasks` feature, detailing the database schema, data mapping, and the complex calculation logic behind task metrics.

## 1. Database Schema & Data Mapping

All daily tasks are stored in the `day_tasks` table. It heavily utilizes JSONB columns to store nested model data.

### Table: `day_tasks`
Located in [day_tasks.sql](file:///c:/qoderProjects/the_time_chart/packages/Task_Goal/day_tasks.sql).

| Column | Data Type | Model Mapping | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | `id` | Primary key. |
| `user_id` | UUID | `userId` | Reference to the owner (`auth.users`). |
| `category_id` | UUID | `categoryId` | Reference to user categories. |
| `category_type` | TEXT | `categoryType` | Main category name (e.g., Work, Health). |
| `sub_types` | TEXT | `subTypes` | Sub-category details. |
| `about_task` | JSONB | `AboutTask` | `task_name`, `task_description`, `media_url`. |
| `indicators` | JSONB | `Indicators` | `status`, `priority`. |
| `timeline` | JSONB | `Timeline` | `starting_time`, `ending_time`, `overdue`, `completion_time`. |
| `feedback` | JSONB | `Feedback` | Contains a list of `Comment` objects (text + media). |
| `metadata` | JSONB | `Metadata` | `progress`, `points_earned`, `rating`, `reward_package`, `penalty`. |
| `social_info` | JSONB | `SocialInfo` | Public post meta (IDs, timestamps). |
| `share_info` | JSONB | `ShareInfo` | Chat sharing metadata. |

---

## 2. Calculation Logic (Evaluation Engine)

The task status and scoring are calculated using a strict evaluation engine. Metrics are updated via the `evaluateTask()` method.

### Points Calculation (`points_earned`)
Only "PASS" verified feedback contributes to positive points.

| Category | Bonus | Logic |
| :--- | :--- | :--- |
| **Feedback Base** | `count * 5` | Points for each verified feedback entry. |
| **Media Bonus** | `totalMediaCount * 5` | Points for each media file in PASS feedbacks. |
| **Text Bonus** | `wordCount * 3` | Points for total words in PASS feedback texts. |
| **Priority** | +5 to +15 points | High: +15, Medium: +10, Low: +5. |
| **On-Time** | +20 points | Awarded if `completionTime` is between `startingTime` and `endingTime`. |
| **Duration** | Up to +100 points | Based on actual duration `d` (hours): <br> d<1h: +5, 1-2h: +10, 2-3h: +15, 3-4h: +20, 4-5h: +30, 5-6h: +40, 6-7h: +50, 7-8h: +70, 8-9h: +80, 9h+: +100. |

### Penalty Calculations (`penalty`)

| Type | Deduction Logic | Equation |
| :--- | :--- | :--- |
| **Feedback Slots** | `-10 points` per missed window. | Window: `[slotEnd - 2 min, slotEnd + 2 min]` every 20 mins. |
| **Overdue** | `-10 points` per full hour. | Applied if no feedback exists by `ending_time`. Stops at 23:59. |
| **Missed Task** | `-100 points` | Applied if the day ends (23:59) with NO feedback. |

### Final Score, Rating & Progress

`final_score = points_earned - penalty`

| Final Score | Rating | Progress |
| :--- | :--- | :--- |
| ≤ 0 | 0.0 | 0% |
| 1 – 20 | 1.0 | 10% |
| 21 – 50 | 2.0 | 30% |
| 51 – 100 | 3.0 | 55% |
| 101 – 150 | 4.0 | 75% |
| 151 – 200 | 4.5 | 88% |
| > 200 | 5.0 | 100% |


---

## 3. AI Authenticity Verification

The `DayTaskAIService` uses a multi-modal AI model to verify that task completions are authentic and not fraudulent.

- **Strict Verification**: If enabled, tasks marked "Completed" with no media or irrelevant text are flagged.
- **AI Pass/Fail**:
    - **Pass**: Task proceeds to point calculation normally. AI may override progress/rating based on quality seen in media.
    - **Fail**: Status changed to `failed`, Points = `0`, Progress = `0`, and a flat `50-point` penalty is applied.
- **Verification Logic**: Uses `UniversalAIService` to compare the `taskDescription` against the uploaded `mediaUrls` and `feedbackText`.

The [Diary Feature](file:///c:/qoderProjects/the_time_chart/Documentation/Diary.md) integrates with Day Tasks by:
- **Contextual Snapshots**: When a diary entry is created for a specific day, it takes a copy of your active `day_tasks` to provide context for AI-driven reflection questions.
- **Progress Influence**: Writing a diary entry can contribute to overall consistency scores that impact the `RewardPackage` for long-term productivity tracking.

---

## 4. File Directory Breakdown

Files are located under [day_tasks](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/day_tasks/).

### Core Architecture
- **[models/day_task_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/day_tasks/models/day_task_model.dart)**
    - **Purpose**: Defines the data structural hierarchy and the math for points/penalties.
- **[providers/day_task_provider.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/day_tasks/providers/day_task_provider.dart)**
    - **Purpose**: Manages the UI state for the daily list. Handles initialization and user actions.
- **[repositories/day_task_repository.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/day_tasks/repositories/day_task_repository.dart)**
    - **Purpose**: PowerSync database interface. Handles SQL operations and offline persistence.
- **[services/day_task_ai_service.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/task_model/day_tasks/services/day_task_ai_service.dart)**
    - **Purpose**: AI integration for verifying feedback authenticity and generating captions.

## 5. UI Components
- **Screens**:
    - `day_schedule_screen.dart`: Main timeline view for the day.
    - `add_feedback_screen.dart`: UI for logging progress (camera/text).
    - `task_form_bottom_sheet.dart`: Form for creating/editing daily tasks.
- **Widgets**:
    - `day_task_card.dart`: Summary card with progress bars and status indicators.
    - `task_analysis_dialog.dart`: Popup showing exactly how points and ratings were calculated.
    - `task_options_menu.dart`: Actions (Cancel, Delete, Post Snap).
    - `day_task_calendar_dialog.dart`: Date picker for historical view.