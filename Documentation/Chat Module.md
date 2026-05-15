# Chat Module Documentation

## Overview
The Chat Module is a robust, real-time messaging system built with a hybrid offline-first architecture. It leverages **Supabase** for backend persistence and real-time synchronization, and **PowerSync** for local data management and offline capabilities.

## Architecture

### Data Flow
1.  **Local First**: All write operations (sending messages, deleting chats) are first applied to the local PowerSync database.
2.  **Sync**: PowerSync automatically synchronizes local changes with the Supabase PostgreSQL database.
3.  **Real-time Updates**: Real-time events (typing indicators, presence, instant message delivery) are handled via Supabase Realtime Channels.
4.  **Backend Logic**: Complex operations like group creation, member management, and message forwarding are handled via Supabase RPC functions to ensure data integrity and security (RLS).

### Components
- **Models**: Type-safe representations of Chats, Messages, and Members.
- **Repositories**: Direct data access layer for both local (PowerSync) and remote (Supabase) sources.
- **Providers**: State management layer (using `ChangeNotifier`) that coordinates between repositories and the UI.
- **Widgets**: Reusable UI components for chat bubbles, input fields, and list tiles.

## Key Features

### Messaging
- **1:1 & Group Chats**: Support for direct messaging and collaborative group environments.
- **Message Types**: Support for text, images, videos, voice notes, documents, and locations.
- **Shared Content**: Ability to share tasks, polls, and other app-specific content directly in chats.
- **Replies & Mentions**: Threaded conversations with @mentions support.
- **Reactions**: Emoji reactions on messages.

### Management
- **Role-based Access**: Owner, Admin, and Member roles with granular permissions.
- **Moderation**: Reporting content/users, blocking, and administrative controls.
- **Disappearing Messages**: Configurable auto-deletion of messages.
- **History Management**: Clear chat history or delete messages for everyone.

### User Experience
- **Typing Indicators**: Real-time feedback when someone is composing a message.
- **Presence**: Online/Offline status tracking.
- **Drafts**: Automatic saving of unsent messages locally.
- **Wallpaper & Themes**: Personalization of chat interface.

## Database Schema

The module relies on several key tables in the `chats` schema:
- `chats`: Stores chat metadata (name, type, visibility).
- `chat_messages`: Stores all sent messages and their content.
- `chat_members`: Manages membership, roles, and unread counts.
- `chat_message_attachments`: Stores references to uploaded files.
- `chat_reactions`: Stores user reactions to messages.

Detailed SQL definitions can be found in `packages/Chats/chats.sql` and `packages/Chats/chat_messages.sql`.

## Testing

### Unit Tests
Located in `test/features/chats/`:
- `chat_message_model_test.dart`: Verifies serialization and model logic.
- `chat_repository_test.dart`: Verifies interaction with PowerSync and Supabase (Mocked).
- `chat_provider_test.dart`: Verifies state management and UI logic.

### Running Tests
```bash
flutter test test/features/chats
```

## Security
- **Row Level Security (RLS)**: Ensures users can only access chats they are members of.
- **RPC Encapsulation**: Critical state changes are performed through server-side functions to prevent unauthorized data manipulation.
