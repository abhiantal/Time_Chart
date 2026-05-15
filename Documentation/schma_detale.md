# 📊 The Time Chart: Database Schema Documentation

This document provides a comprehensive technical breakdown of the entire database architecture. It details which tables are synchronized for offline use, which remain server-side, and the complexity of the business logic (functions/triggers) attached to each.

---

## 🌎 Overview: Data Storage Strategy

| Strategy | Description | Key Tables |
| :--- | :--- | :--- |
| **BOTH (Synced)** | Bi-directional sync via **PowerSync**. Data is available offline on the device and persists in Supabase Cloud. | Posts, Chats, Tasks, Analytics, Profiles. |
| **CLOUD ONLY** | Server-side only. Used for heavy processing, auditing, or security-sensitive transients. Not synced to local storage. | Notification Queue, AI Logs, FCM Tokens. |
| **LOCAL ONLY** | Temporary data stored only on the device SQLite. Used for sync queues or UI transients. | Media Sync Queue, Sync Exclusions. |

---

## 🛠️ Functional Area: Core & Social
*Location: `packages/Posts`, `packages/Core`*

| Table Name | Storage | Functions | Triggers | Purpose |
| :--- | :--- | :---: | :---: | :--- |
| `user_profiles` | BOTH | 5 | 1 | Identity, bio, and public display settings. |
| `user_settings` | BOTH | 2 | 1 | App preferences (Theme, Daily Reminders). |
| `categories` | BOTH | 0 | 0 | System and user-created task categories. |
| `posts` | BOTH | 8 | 2 | Social feed content (Captions, Media Refs). |
| `reactions` | BOTH | 2 | 2 | Unified Likes system for posts and comments. |
| `comments` | BOTH | 3 | 2 | Threaded discussion and replies system. |
| `follows` | BOTH | 4 | 2 | Social graph (Follower/Following relationships). |
| `saves` | BOTH | 2 | 2 | User bookmarks for posts and media. |
| `post_views` | BOTH | 1 | 0 | Engagement analytics (Reach count). |

---

## 📋 Functional Area: Productivity (Tasks & Goals)
*Location: `packages/Task_Goal`*

| Table Name | Storage | Functions | Triggers | Purpose |
| :--- | :--- | :---: | :---: | :--- |
| `day_tasks` | BOTH | 5 | 2 | Short-term daily focus items and check-ins. |
| `weekly_tasks` | BOTH | 4 | 2 | Mid-term progress and weekly objectives. |
| `long_goals` | BOTH | 3 | 2 | Multi-month roadmaps and major milestones. |
| `bucket_models` | BOTH | 3 | 2 | Lifelong bucket list items (High-level goals). |
| `diary_entries` | BOTH | 2 | 2 | Mood tracking and daily reflection logs. |

---

## 💬 Functional Area: Real-Time Communication
*Location: `packages/Chats`*

| Table Name | Storage | Functions | Triggers | Purpose |
| :--- | :--- | :---: | :---: | :--- |
| `chats` | BOTH | 5 | 1 | Parent container for 1-on-1 and Group rooms. |
| `chat_members` | BOTH | 3 | 1 | Membership levels, roles, and mute status. |
| `chat_messages` | BOTH | 6 | 2 | Message history, edits, and timestamps. |
| `chat_invites` | BOTH | 4 | 1 | Invitation and group entry request system. |
| `chat_message_attachments` | BOTH | 1 | 0 | Links to media files stored in Storage. |

---

## 📈 Functional Area: Analytics & Mentorship
*Location: `packages/Analytics`*

| Table Name | Storage | Functions | Triggers | Purpose |
| :--- | :--- | :---: | :---: | :--- |
| `performance_analytics` | BOTH | 15+ | 1 | Massive summary table for streaks/points/XP. |
| `battle_challenges` | BOTH | 6 | 2 | Competitive PvP task-completion challenges. |
| `mentorship_connections` | BOTH | 12 | 1 | Mentor/Mentee access and feedback system. |

---

## 🔔 Functional Area: Infrastructure & Intelligence
*Location: `packages/notification_helpers_sql`, `packages/Notification_AI`*

| Table Name | Storage | Functions | Triggers | Purpose |
| :--- | :--- | :---: | :---: | :--- |
| `notifications` | BOTH | 2 | 1 | Resident history of in-app alerts (Bell icon). |
| `notification_queue` | CLOUD | 1 | 0 | Transient buffer for Edge Function push. |

| `fcm_tokens` | CLOUD | 5 | 0 | Push notification device registration keys. |
| `ai_history` | CLOUD | 2 | 1 | Log of AI prompts and token usage metrics. |

---

## 🎓 Technical Summary

- **Total Tables**: ~28
- **Total Functions**: ~110
- **Total Triggers**: ~45
- **Primary Database**: PostgreSQL (Supabase)
- **Local Database**: SQLite (via PowerSync)
- **Logic Layer**: All data integrity and counts (Likes, Streaks, Points) are handled via **Database Triggers** to ensure consistency between offline and online states.
