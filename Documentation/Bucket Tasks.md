# Bucket Model Implementation & Calculation Documentation

This document provides a comprehensive technical overview of the `bucket_model` feature, detailing the database schema, data mapping, and the calculation logic behind bucket metrics.

## 1. Database Schema & Data Mapping

Bucket data is stored in the `bucket_models` table. It uses JSONB columns to store nested hierarchical data.

### Table: `bucket_models`
Located in [bucket_models.sql](file:///c:/qoderProjects/the_time_chart/packages/Task_Goal/bucket_models.sql).

| Column | Data Type | Model Mapping | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | `id` | Primary key. |
| `user_id` | UUID | `userId` | Reference to the owner (`auth.users`). |
| `category_id` | UUID | `categoryId` | Reference to user categories. |
| `category_type` | TEXT | `categoryType` | Main category name. |
| `sub_types` | TEXT | `subTypes` | Sub-category details. |
| `title` | TEXT | `title` | The name/title of the bucket list. |
| `details` | JSONB | `BucketDetails` | `description`, `motivation`, `outcome`, `media_url`. |
| `checklist` | JSONB | `List<ChecklistItem>` | Array of tasks, each with `done`, `points`, and `feedback`. |
| `timeline` | JSONB | `BucketTimeline` | `start_date`, `due_date`, `complete_date`. |
| `metadata` | JSONB | `BucketMetadata` | `average_rating`, `average_progress`, `total_points_earned`. |
| `social_info` | JSONB | `SocialInfo` | Social posting meta data. |
| `share_info` | JSONB | `ShareInfo` | Chat sharing meta data. |

---

## 2. Calculation Logic

The logic resides in [bucket_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/bucket_model/models/bucket_model.dart). Metrics are updated via `recalculateRewards()`.

### Core Metrics

| Metric | Calculation Logic |
| :--- | :--- |
| **Points Earned** | Sum of bonuses (Feedback Base, Media, Completion +20, Streak +10 per 3 days). |
| **Penalties** | Overdue (-20), No Media (-10). |
| **Progress** | `clamp(pointsEarned - penalties, 0, 100)`. |
| **Rating** | Universal formula: `1.0 + 4.0 * (progress / 100)`. |
| **Status** | Based on `isCompleted` flag, `dueDate` vs `now`, and `progress > 0`. |

### Status Derivation
1.  **Completed**: Timeline has a `completeDate` OR all checklist items are done.
2.  **Missed**: Not completed AND `dueDate` is in the past.
3.  **In Progress**: Not completed/missed AND `progress > 0`.
4.  **Pending**: Default state for new buckets.

### Reward Integration
The model calls `RewardManager.calculate()` using the derived progress, rating, and points.
- **Time Gating**: Buckets are categorized as non-time-bound activities.
- **Equation**: $G_{time} = (H_{tier} \le 0)$ (Always passes).
- **Impact**: Buckets can reach **Prism**, **Radiant**, and **Nova** tiers based on checklist completion and quality alone.

---

## 3. AI Insights & Planning
The `BucketAiService` provides several intelligent features:
- **AI Planning**: Generates a custom `ai_plan` (checklist items) based on the bucket title and description.
- **Progress Suggestions**: Analyzes remaining items and suggests specific time-boxing strategies.
- **Authenticity Check**: While checklist items are user-toggled, AI analyzes the associated `feedback` notes to recommend rating adjustments.

---

## 4. File Directory Breakdown

Files are located under [bucket_model](file:///c:/qoderProjects/the_time_chart/lib/features/personal/bucket_model/).

### Core Architecture
- **[models/bucket_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/bucket_model/models/bucket_model.dart)**
    - **Purpose**: Defines the `BucketModel` and sub-models (`ChecklistItem`, `BucketDetails`, etc.).
    - **Logic**: Contains the `recalculateRewards()` and color derivation logic.
- **[providers/bucket_provider.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/bucket_model/providers/bucket_provider.dart)**
    - **Purpose**: UI state management using `ChangeNotifier`. Handles CRUD and checklist toggles.
- **[repositories/bucket_repository.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/bucket_model/repositories/bucket_repository.dart)**
    - **Purpose**: Database interface via PowerSync.
- **[services/bucket_ai_service.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/bucket_model/services/bucket_ai_service.dart)**
    - **Purpose**: AI integration for generating bucket plans and performance suggestions.

### UI Components
- **Screens**:
    - `bucket_list_screen.dart`: The main grid/list view of all buckets.
    - `bucket_detail_screen.dart`: Tabbed view for overview, checklist, and stats.
    - `add_edit_bucket_page.dart`: Form for creating or updating buckets.
- **Widgets**:
    - `bucket_card_widget.dart`: The main entry card for the bucket list.
    - `checklist_preview.dart`: Minimal view of checklist items.
    - `checklist_feedback_add_dialog.dart`: Popup for adding media/text to an item.
    - `bucket_options_menu.dart`: Actions (Pin, Delete, Share).
