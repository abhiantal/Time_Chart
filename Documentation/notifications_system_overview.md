# The Time Chart Notification System Overview

This document provides a comprehensive list of all notification types in "The Time Chart" application, organized by category, along with their trigger logic and implementation details.

## System Architecture

The notification system follows a modular, two-tier architecture:

1.  **Backend (Supabase/PostgreSQL)**:
    *   **Triggers**: Instant notifications (Chat, Social, AI, Mentoring) are fired via database triggers.
    *   **Scheduled Polling**: Analytics and status-based notifications (Competition gaps, Streak warnings, Mentee milestones) are processed by a scheduler function.
    *   **Notification Queue**: All actions insert into the `notification_queue` table for processing and reliability.
2.  **App (Flutter)**:
    *   **Modular Handlers**: Category-specific classes in `notification_handlers.dart` manage foreground display and **navigation routing**.
    *   **Registry**: `notification_setup.dart` registers all handlers to the `NotificationRouter`.
    *   **Routing**: The `NotificationRouter` matches incoming types to the correct handler, which then uses `GoRouter` for screen navigation.

---

## 1. Analytics & Performance Modules (Elite Features)

These modules focus on user engagement, competition, and mentoring.

### A. Competition Module
**Flutter Handler:** `CompetitionNotificationHandler`

| Notification Type | Trigger Logic | How it Works |
| :--- | :--- | :--- |
| `competition_added_as_member` | Instant (Trigger) | Notifies when you are added to a battle by someone else. |
| `competition_challenge_received`| Instant (Trigger) | Notifies of a new challenge or invitation. |
| `competition_leaderboard_change`| Polling (Scheduler) | Alerts when rank changes significantly in a battle. |
| `competition_no_opponents` | Polling (Scheduler) | Alerts creator if a battle has 0 opponents. |
| `competition_slots_available` | Polling (Scheduler) | Alerts creator if a battle has vacant slots (< 5 members). |
| `competition_losing_warning` | Polling (Scheduler) | Alerts user if they are falling behind the battle leader. |

### B. Dashboard & Personal Performance
**Flutter Handler:** `DashboardNotificationHandler`

| Notification Type | Trigger Logic | How it Works |
| :--- | :--- | :--- |
| `dashboard_no_activity` | Polling (Scheduler) | Alerts if no tasks are added for the current day by noon. |
| `dashboard_streak_warning` | Polling (Scheduler) | Warning when your current streak is at risk of ending today. |
| `dashboard_streak_lost` | Polling (Scheduler) | Encouragement alert when a streak has just reset to 0. |
| `dashboard_streak_status` | Polling (Scheduler) | Periodic summary of your current vs best streak. |
| `dashboard_new_reward` | Instant (Trigger) | Fired when a new reward icon is unlocked. |

### C. Mentoring Module
**Flutter Handler:** `MentoringNotificationHandler`

| Notification Type | Trigger Logic | How it Works |
| :--- | :--- | :--- |
| `mentoring_request_received` | Instant (Trigger) | Notifies when someone requests access to your data. |
| `mentoring_access_approved` | Instant (Trigger) | Fired when your mentoring request is accepted. |
| `mentoring_duration_warning` | Polling (Scheduler) | Alerts users 3 days before a mentoring connection expires. |
| `mentoring_milestone_achieved` | Polling (Scheduler) | Notifies Mentor when Mentee hits a score milestone. |
| `mentoring_encouragement` | Instant (Trigger) | Fired when a mentor sends advice or reactions. |

---

## 2. Productivity & Management Modules

### A. Tasks (Daily & Weekly)
**Flutter Handlers:** `DayTaskNotificationHandler`, `WeekTaskNotificationHandler`

*   **Daily Tasks**: Covers reminders (`1hour`, `30min`, `10min`), in-progress alerts, ending soon, and feedback requirements.
*   **Weekly Tasks**: Covers reminders, deadlines, streaks, and missed task alerts.

### B. Long Goals & Buckets
**Flutter Handlers:** `LongGoalsNotificationHandler`, `BucketNotificationHandler`

*   **Goals**: Reminders, milestones, deadlines, and weekly progress reports.
*   **Buckets**: Reminders, deadlines, milestones, and collaboration invites.

### C. Diary
**Flutter Handler:** `DiaryNotificationHandler`

*   **Daily Diary**: Includes reminders, streak updates, and journaling prompts.

---

## 3. Social & System Modules

### A. Communication (Chat & Social)
**Flutter Handlers:** `ChatNotificationHandler`, `SocialNotificationHandler`

*   **Chat**: New messages, group messages, and @mentions.
*   **Social**: Likes, comments, replies, new followers, and post mentions.

### B. AI & System
**Flutter Handlers:** `AiNotificationHandler`, `SystemNotificationHandler`

*   **AI**: Token warnings, limit reached alerts, and service status.
*   **System**: App updates, announcements, and maintenance alerts.

---

## Technical File Reference

### Database (SQL Path: `notification/notification_helpers_sql/`)
*   **Core Logic**: `core/`
    *   `competition_notifications.sql`
    *   `dashboard_notifications.sql`
    *   `leaderboard_notifications.sql`
    *   `mentoring_notifications.sql`
*   **Infrastructure**: `system/`
    *   `fcm_helpers.sql`
    *   `system_notifications.sql`
    *   `ai_notifications.sql`
*   **Feature Specific**: `tasks_goals_buckets_diary/` and `chat_social/`

### App (Flutter Path: `lib/notifications/`)
*   **Definitions**: `core/notification_types.dart`
*   **Router Implementation**: `core/notification_routing.dart`
*   **Handler Logic**: `handlers/notification_handlers.dart` (Centralized handlers and navigation)
*   **Registry & Setup**: `notification_setup.dart`

