# Diary Implementation & Calculation Documentation

This document provides a comprehensive technical overview of the `diary` feature, focusing on the progress calculation math and AI-driven reflection logic.

## 1. Progress Calculation Logic
Diary progress is calculated across four dimensions to encourage comprehensive reflection.

| Dimension | Points | Condition |
| :--- | :--- | :--- |
| **Feedback Base** | +5 points | Awarded if content exists. |
| **Completion** | +10 points | Awarded if the entry is finished. |
| **Media Bonus** | 5 pts / attachment | Points for each attached media item. |
| **Duration (Effort)** | 7 to 20 points | Based on word count (100: +7, 200: +10, 400: +15, 800+: +20). |
| **Sentiment Bonus** | +10 points | Awarded for a positive sentiment score (> 0.5). |

### Equation
$P_{diary} = \text{clamp}(PointsEarned - Penalties, 0, 100)$
$R_{diary} = 1.0 + 4.0 \times (\frac{P}{100})$

## 2. AI Reflection & Insights
The Diary feature leverages AI to deepen the user's focus:
- **Sentiment Analysis**: AI analyzes the "Mood" and "Content" to provide a summary and sentiment score.
- **Contextual Snapshots**: The AI pulls data from the user's `day_tasks` to ask relevant questions during reflection.
- **Achievement Impact**: High-quality diary entries (tracked via word count and sentiment) contribute to the consistency metrics used in the `RewardManager`.

## 3. Database Schema & Data Mapping

Diary entries are stored in the `diary_entries` table. It heavily utilizes JSONB for flexible storage of mood, AI questions, media, and context.

### Table: `diary_entries`
Located in [diary_entries.sql](file:///c:/qoderProjects/the_time_chart/packages/Task_Goal/diary_entries.sql).

| Column | Data Type | Model Mapping | Description |
| :--- | :--- | :--- | :--- |
| `id` | UUID | `id` | Primary key. |
| `user_id` | UUID | `userId` | Reference to the owner (`auth.users`). |
| `entry_date` | DATE | `entryDate` | The specific date this entry belongs to (Unique per user/date). |
| `title` | TEXT | `title` | Optional headline for the day. |
| `content` | TEXT | `content` | The main body of the diary entry. |
| `mood` | JSONB | `DiaryMood` | Stores `rating` (0-5), `label`, `score` (0-1), and `emoji`. |
| `shot_qna` | JSONB | `List<DiaryQnA>` | Array of reflection questions and answers (MCQ or Short Answer). |
| `attachments` | JSONB | `List<DiaryAttachment>`| Media files including `url`, `type`, `file_name`, and `thumbnail_url`. |
| `linked_items` | JSONB | `DiaryLinkedItems` | A snapshot of `long_goals`, `day_tasks`, `weekly_tasks`, and `bucket_items` active on the entry date. |
| `metadata` | JSONB | `DiaryMetadata` | Stores `ai_summary`, `sentiment_score`, `word_count`, `task_color`, and `reward_package`. |
| `settings` | JSONB | `DiarySettings` | User preferences like `is_private`, `is_favorite`, `is_pinned`. |
| `social_info` | JSONB | - | Public post metadata. |
| `share_info` | JSONB | - | Chat share metadata. |

---

## 2. Calculation Logic

The "calculative" part of the diary feature happens during entry creation in the repository and model-level getters.

### Metadata Calculation (In Repository)
When a diary entry is saved via [diary_repository.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/repositories/diary_repository.dart):
- **Word Count**: Calculated by splitting the content text on whitespace.
- **Task Color**: Based on the mood rating:
    - `rating >= 5` -> `low` (Calm/Positive colors).
    - `rating <= 2` -> `high` (Urgent/Attention-needed colors).
    - Default -> `medium`.
- **Reward Calculation**: Uses `RewardManager.forDiary()` based on word count, mood existence, Q&A answered, and attachments.
- **Sentiment Score**: Pulled directly from the mood's calculated `score`.

### Progress Calculation (@Model)
Located in [diary_entry_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/models/diary_entry_model.dart). Completeness is represented as a percentage [0-100]:

| Category | Reward/Penalty | Logic |
| :--- | :--- | :--- |
| **Base + Completion** | +15 points | Awarded for any valid content. |
| **Media** | +5 pts / media | Scaled by number of attachments. |
| **Duration (Effort)** | +7 to +20 points | Based on word count categories. |
| **Sentiment** | +10 points | If sentiment score > 0.5. |
| **Missed Day** | -50 points | Penalty if the day passes with no entry. |
| **Low Effort** | -10 points | Penalty if word count < 10. |

---

## 3. File Directory Breakdown

Files are located under [diary_model](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/).

### Core Architecture
- **[models/diary_entry_model.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/models/diary_entry_model.dart)**
    - **Purpose**: Defines the `DiaryEntryModel` and its sub-classes.
    - **Uses**: `CardColorHelper` for UI gradients, `RewardManager` for reward structures.
- **[providers/diary_ai_provider.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/providers/diary_ai_provider.dart)**
    - **Purpose**: Logic for generating AI questions and summaries.
    - **Uses**: `UniversalAIService` for NLP tasks, `DiaryRepository` for context.
- **[repositories/diary_repository.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/repositories/diary_repository.dart)**
    - **Purpose**: PowerSync database interface for CRUD operations.
    - **Uses**: `PowerSyncService`, `RewardManager` for metadata points.

### UI Screens
- **[screens/diary_entry_screen.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/screens/diary_entry_screen.dart)**
    - **Purpose**: The main editor for creating and editing daily entries.
    - **Uses**: `DiaryRepository`, `LongGoalsRepository`, `DayTaskRepository`, `WeekTaskRepository`, `BucketRepository`.
- **[screens/diary_dashboard_screen.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/screens/diary_dashboard_screen.dart)**
    - **Purpose**: Overview visualization of diary streaks and AI insights.
- **[screens/diary_list_screen.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/screens/diary_list_screen.dart)**
    - **Purpose**: Historical feed of all past diary entries.
- **[screens/diary_entry_detail_screen.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/screens/diary_entry_detail_screen.dart)**
    - **Purpose**: Read-only view for a specific day's reflection.
- **[screens/diary_options_menu.dart](file:///c:/qoderProjects/the_time_chart/lib/features/personal/diary_model/screens/diary_options_menu.dart)**
    - **Purpose**: Contextual actions (edit, delete, favorite, share).

---

## 4. Full Data Structure (Record Example)

```json
{
  "entry_id": "diary_001",
  "user_id": "user_123",
  "entry_date": "2026-03-12",
  "title": "A Productive Day",
  "content": "Today was a great day. I completed my tasks and felt very motivated to continue improving myself.",
  "mood": {
    "rating": 4, "label": "Happy", "score": 0.82, "emoji": "😊"
  },
  "shot_qna": [
    { "qna_number": "1", "type": "short_answer", "question": "...", "answer": "..." }
  ],
  "attachments": [
    { "id": "att_001", "type": "image", "url": "...", "file_name": "...", "file_size": 245000 }
  ],
  "linked_items": {
    "long_goals": [{ "id": "goal_001", "title": "Become a Flutter Expert" }],
    "day_tasks": [{ "id": "task_001", "title": "Finish Dashboard UI" }],
    "weekly_tasks": [{ "id": "week_task_001", "title": "..." }],
    "bucket_items": [{ "id": "bucket_001", "title": "..." }]
  },
  "metadata": {
    "task_color": "medium",
    "reward_package": {
      "earned": true, "tier": "spark", "points": 15, "tagName": "Consistency"
    },
    "word_count": 18,
    "has_attachments": true,
    "sentiment_score": 0.82,
    "ai_summary": "User had a productive and positive day."
  },
  "settings": {
    "is_private": true, "is_favorite": false, "is_pinned": false
  },
  "created_at": "2026-03-12T19:30:00Z",
  "updated_at": "2026-03-12T19:45:00Z"
}
```
