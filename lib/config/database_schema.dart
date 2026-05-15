// ================================================================
// FILE: lib/config/database_schema.dart
// Global schema for local async SQLite database (PowerSync)
// Optimized for 1M+ user scalability and backend parity
// ================================================================

import 'package:powersync/powersync.dart';

/// Global schema for local async SQLite database (PowerSync).
const schema = Schema([
  // --- CORE SYSTEM TABLES ---

  Table('user_profiles', [
    Column.text('user_id'),
    Column.text('email'),
    Column.text('username'),
    Column.text('display_name'),
    Column.text('profile_url'),
    Column.text('address'),
    Column.text('organization'), // JSONB
    Column.text('influencer'),   // JSONB
    Column.text('user_info'),    // JSONB
    Column.integer('is_profile_public'),
    Column.text('subscription_tier'),
    Column.integer('onboarding_completed'),
    Column.integer('open_to_chat'),
    Column.text('created_community_id'),
    Column.text('promoted_community_id'),
    Column.text('last_login'),
    Column.text('social_stats'), // JSONB
    Column.integer('score'),
    Column.integer('global_rank'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_user_profiles_user_id', [IndexedColumn('user_id')]),
    Index('idx_user_profiles_username', [IndexedColumn('username')]),
    Index('idx_user_profiles_email', [IndexedColumn('email')]),
    Index('idx_user_profiles_score', [IndexedColumn('score')])
  ]),

  Table('user_settings', [
    Column.text('user_id'),
    Column.text('appearance'),    // JSONB
    Column.text('notifications'), // JSONB
    Column.text('privacy'),       // JSONB
    Column.text('tasks'),         // JSONB
    Column.text('goals'),         // JSONB
    Column.text('bucket_list'),   // JSONB
    Column.text('diary'),         // JSONB
    Column.text('chat'),          // JSONB
    Column.text('social'),        // JSONB
    Column.text('ai'),            // JSONB
    Column.text('competition'),   // JSONB
    Column.text('security'),      // JSONB
    Column.text('data_storage'),  // JSONB
    Column.text('localization'),  // JSONB
    Column.text('accessibility'), // JSONB
    Column.text('experimental'),  // JSONB
    Column.text('widgets'),       // JSONB
    Column.text('analytics'),     // JSONB
    Column.text('mentoring'),     // JSONB
    Column.text('integrations'),  // JSONB
    Column.integer('settings_version'),
    Column.text('last_synced_at'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_user_settings_user_id', [IndexedColumn('user_id')])
  ]),

  Table('categories', [
    Column.text('user_id'),
    Column.text('category_for'),
    Column.text('category_type'),
    Column.text('sub_types'),
    Column.text('description'),
    Column.text('color'),
    Column.text('icon'),
    Column.integer('is_global'),
    Column.integer('is_active'),
    Column.integer('sort_order'),
    Column.text('metadata'), // JSONB
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_categories_user_id', [IndexedColumn('user_id')]),
    Index('idx_categories_type', [IndexedColumn('category_type')])
  ]),

  // --- TASK & GOAL TABLES ---

  Table('day_tasks', [
    Column.text('user_id'),
    Column.text('category_id'),
    Column.text('category_type'),
    Column.text('sub_types'),
    Column.text('about_task'), // JSONB
    Column.text('indicators'), // JSONB
    Column.text('timeline'),   // JSONB
    Column.text('feedback'),   // JSONB
    Column.text('metadata'),   // JSONB
    Column.text('social_info'), // JSONB
    Column.text('share_info'),  // JSONB
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_day_tasks_user_id', [IndexedColumn('user_id')]),
    Index('idx_day_tasks_category', [IndexedColumn('category_id')]),
    Index('idx_day_tasks_created', [IndexedColumn('created_at')])
  ]),

  Table('weekly_tasks', [
    Column.text('user_id'),
    Column.text('category_id'),
    Column.text('category_type'),
    Column.text('sub_types'),
    Column.text('about_task'), // JSONB
    Column.text('indicators'), // JSONB
    Column.text('timeline'),   // JSONB
    Column.text('feedback'),   // JSONB
    Column.text('metadata'),   // JSONB
    Column.text('social_info'), // JSONB
    Column.text('share_info'),  // JSONB
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_weekly_tasks_user_id', [IndexedColumn('user_id')]),
    Index('idx_weekly_tasks_category', [IndexedColumn('category_id')])
  ]),

  Table('long_goals', [
    Column.text('user_id'),
    Column.text('category_id'),
    Column.text('title'),
    Column.text('category_type'),
    Column.text('sub_types'),
    Column.text('description'), // JSONB
    Column.text('timeline'),    // JSONB
    Column.text('indicators'),   // JSONB
    Column.text('metrics'),      // JSONB
    Column.text('analysis'),     // JSONB
    Column.text('goal_log'),     // JSONB
    Column.text('social_info'),  // JSONB
    Column.text('share_info'),   // JSONB
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('search_vector')
  ], indexes: [
    Index('idx_long_goals_user_id', [IndexedColumn('user_id')]),
    Index('idx_long_goals_category', [IndexedColumn('category_id')])
  ]),

  Table('bucket_models', [
    Column.text('user_id'),
    Column.text('category_id'),
    Column.text('category_type'),
    Column.text('sub_types'),
    Column.text('title'),
    Column.text('details'),    // JSONB
    Column.text('checklist'),  // JSONB
    Column.text('timeline'),   // JSONB
    Column.text('metadata'),   // JSONB
    Column.text('social_info'), // JSONB
    Column.text('share_info'),  // JSONB
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('search_vector')
  ], indexes: [
    Index('idx_bucket_models_user_id', [IndexedColumn('user_id')]),
    Index('idx_bucket_models_created', [IndexedColumn('created_at')])
  ]),

  Table('diary_entries', [
    Column.text('user_id'),
    Column.text('entry_date'),
    Column.text('title'),
    Column.text('content'),
    Column.text('mood'),        // JSONB
    Column.text('shot_qna'),   // JSONB
    Column.text('attachments'), // JSONB
    Column.text('linked_items'), // JSONB
    Column.text('metadata'),    // JSONB
    Column.text('settings'),    // JSONB
    Column.text('social_info'), // JSONB
    Column.text('share_info'),  // JSONB
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('search_vector')
  ], indexes: [
    Index('idx_diary_entries_user_id', [IndexedColumn('user_id')]),
    Index('idx_diary_entries_date', [IndexedColumn('entry_date')])
  ]),

  // --- SOCIAL & FEED TABLES ---

  Table('posts', [
    Column.text('user_id'),
    Column.text('post_type'),
    Column.text('content_type'), //-- Legacy support/Local classification
    Column.text('caption'),
    Column.text('media'), //-- JSONB
    Column.integer('media_count'),
    Column.text('source_type'),
    Column.text('source_id'),
    Column.text('source_mode'),
    Column.text('source_snapshot'), //-- JSONB
    Column.text('article_data'), //-- JSONB
    Column.text('poll_data'),    //-- JSONB
    Column.integer('is_sponsored'),
    Column.text('ad_data'), //-- JSONB
    Column.text('ad_metrics'), //-- JSONB
    Column.text('ad_status'),
    Column.text('visibility'),
    Column.text('visible_to'), //-- JSONB
    Column.text('hide_from'),  //-- JSONB
    Column.text('reactions_count'), //-- JSONB
    Column.integer('comments_count'),
    Column.integer('reposts_count'),
    Column.integer('saves_count'),
    Column.integer('views_count'),
    Column.integer('shares_count'),
    Column.integer('clicks_count'),
    Column.integer('allow_comments'),
    Column.integer('allow_reactions'),
    Column.integer('allow_reposts'),
    Column.integer('allow_saves'),
    Column.integer('is_pinned'),
    Column.text('edit_history'),  //-- JSONB
    Column.text('created_at'),
    Column.text('published_at'),
    Column.text('updated_at')
  ],
      indexes: [
        Index('idx_posts_user_id', [IndexedColumn('user_id')]),
        Index('idx_posts_type', [IndexedColumn('post_type')]),
        Index('idx_posts_created', [IndexedColumn('created_at')])
      ]),

  Table('reactions', [
    Column.text('user_id'),
    Column.text('target_type'),
    Column.text('target_id'),
    Column.text('reaction_type'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_reactions_user_id', [IndexedColumn('user_id')]),
    Index('idx_reactions_target', [IndexedColumn('target_id')])
  ]),

  Table('comments', [
    Column.text('user_id'),
    Column.text('post_id'),
    Column.text('parent_comment_id'),
    Column.text('reply_to_user_id'),
    Column.integer('thread_depth'),
    Column.text('thread_path'),
    Column.text('content'),
    Column.text('content_rendered'),
    Column.text('mentions'), // JSONB
    Column.text('mentioned_usernames'), // JSONB
    Column.text('hashtags'), // JSONB
    Column.text('media'),    // JSONB
    Column.text('reactions_count'), // JSONB
    Column.integer('replies_count'),
    Column.integer('is_edited'),
    Column.text('edited_at'),
    Column.integer('is_deleted'),
    Column.integer('is_hidden'),
    Column.integer('is_pinned'),
    Column.integer('is_by_author'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_comments_post', [IndexedColumn('post_id')]),
    Index('idx_comments_user', [IndexedColumn('user_id')])
  ]),

  Table('follows', [
    Column.text('follower_id'),
    Column.text('following_id'),
    Column.text('status'),
    Column.text('relationship'),
    Column.text('notifications'), // JSONB
    Column.integer('show_in_feed'),
    Column.integer('feed_priority'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_follows_follower', [IndexedColumn('follower_id')]),
    Index('idx_follows_following', [IndexedColumn('following_id')])
  ]),

  Table('saves', [
    Column.text('user_id'),
    Column.text('post_id'),
    Column.text('collection_name'),
    Column.text('note'),
    Column.text('created_at')
  ], indexes: [
    Index('idx_saves_user', [IndexedColumn('user_id')]),
    Index('idx_saves_post', [IndexedColumn('post_id')])
  ]),

  Table('post_views', [
    Column.text('post_id'),
    Column.text('user_id'),
    Column.text('view_date'),
    Column.text('view_source'),
    Column.integer('view_duration_seconds'),
    Column.integer('view_percent'),
    Column.integer('completed'),
    Column.integer('clicked_cta'),
    Column.text('device_type'),
    Column.text('platform'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_post_views_post', [IndexedColumn('post_id')]),
    Index('idx_post_views_user', [IndexedColumn('user_id')])
  ]),

  Table('notifications', [
    Column.text('user_id'),
    Column.text('notification_info'), // JSONB
    Column.integer('is_read'),
    Column.text('read_at'),
    Column.text('metadata'),   // JSONB
    Column.text('created_at')
  ], indexes: [
    Index('idx_notifications_user', [IndexedColumn('user_id')]),
    Index('idx_notifications_created', [IndexedColumn('created_at')])
  ]),

  // --- CHAT TABLES ---

  Table('chats', [
    Column.text('type'),
    Column.text('name'),
    Column.text('avatar'),
    Column.text('description'),
    Column.text('visibility'),
    Column.text('who_can_send'),
    Column.text('who_can_add_members'),
    Column.integer('disappearing_messages'),
    Column.integer('disappearing_duration'),
    Column.integer('total_members'),
    Column.text('last_message_at'),
    Column.text('metadata'), // JSONB
    Column.text('created_by'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_chats_type', [IndexedColumn('type')]),
    Index('idx_chats_creator', [IndexedColumn('created_by')]),
    Index('idx_chats_last_msg', [IndexedColumn('last_message_at')])
  ]),

  Table('chat_members', [
    Column.text('chat_id'),
    Column.text('user_id'),
    Column.text('role'),
    Column.integer('is_pinned'),
    Column.integer('is_muted'),
    Column.text('mute_until'),
    Column.integer('is_archived'),
    Column.integer('is_blocked'),
    Column.text('last_read_message_id'),
    Column.text('last_read_at'),
    Column.integer('unread_count'),
    Column.integer('unread_mentions'),
    Column.integer('is_active'),
    Column.text('joined_at'),
    Column.text('invited_by'),
    Column.text('settings'), // JSONB
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_chat_members_user', [IndexedColumn('user_id')]),
    Index('idx_chat_members_chat', [IndexedColumn('chat_id')])
  ]),

  Table('chat_messages', [
    Column.text('chat_id'),
    Column.text('sender_id'),
    Column.text('type'),
    Column.text('text_content'),
    Column.text('metadata'), // JSONB
    Column.text('reply_to_id'),
    Column.text('forwarded_from_message_id'),
    Column.integer('forward_count'),
    Column.text('shared_content_type'),
    Column.text('shared_content_id'), 
    Column.text('shared_content_mode'), 
    Column.text('shared_content_snapshot'), 
    Column.text('system_event_type'),
    Column.text('system_event_data'), // JSONB
    Column.text('reactions'),         // JSONB
    Column.text('mentioned_user_ids'), // JSONB
    Column.integer('is_edited'),
    Column.integer('is_deleted'),
    Column.integer('is_pinned'),
    Column.text('pinned_at'),
    Column.text('pinned_by'),
    Column.text('status'),
    Column.text('sent_at'),
    Column.text('edited_at'),
    Column.text('expires_at'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_chat_messages_chat', [IndexedColumn('chat_id')]),
    Index('idx_chat_messages_sender', [IndexedColumn('sender_id')]),
    Index('idx_chat_messages_sent', [IndexedColumn('sent_at')])
  ]),

  Table('chat_message_attachments', [
    Column.text('message_id'),
    Column.text('chat_id'),
    Column.text('type'),
    Column.text('url'),
    Column.text('thumbnail_url'),
    Column.text('file_name'),
    Column.integer('file_size'),
    Column.text('mime_type'),
    Column.integer('width'),
    Column.integer('height'),
    Column.integer('duration'),
    Column.integer('sort_order'),
    Column.text('created_at')
  ], indexes: [
    Index('idx_chat_attachments_msg', [IndexedColumn('message_id')]),
    Index('idx_chat_attachments_chat', [IndexedColumn('chat_id')])
  ]),

  Table('chat_invites', [
    Column.text('chat_id'),
    Column.text('code'),
    Column.text('created_by'),
    Column.integer('max_uses'),
    Column.integer('uses_count'),
    Column.text('expires_at'),
    Column.text('invited_role'),
    Column.integer('is_active'),
    Column.integer('is_revoked'),
    Column.text('revoked_by'),
    Column.text('revoked_at'),
    Column.text('created_at')
  ], indexes: [
    Index('idx_chat_invites_chat', [IndexedColumn('chat_id')]),
    Index('idx_chat_invites_code', [IndexedColumn('code')])
  ]),

  // --- ANALYTICS & COMPETITION TABLES ---

  Table('performance_analytics', [
    Column.text('user_id'),
    Column.text('overview'),         // JSONB
    Column.text('today'),            // JSONB
    Column.text('active_items'),     // JSONB
    Column.text('progress_history'), // JSONB
    Column.text('weekly_history'),   // JSONB
    Column.text('category_stats'),   // JSONB
    Column.text('rewards'),          // JSONB
    Column.text('mood'),             // JSONB
    Column.text('streaks'),          // JSONB
    Column.text('recent_activity'),  // JSONB
    Column.text('snapshot_at'),
    Column.text('updated_at'),
    Column.text('created_at')
  ], indexes: [
    Index('idx_pa_user_id', [IndexedColumn('user_id')]),
    Index('idx_pa_updated_at', [IndexedColumn('updated_at')])
  ]),

  Table('battle_challenges', [
    Column.text('user_id'),
    Column.text('title'),
    Column.text('description'),
    Column.text('status'),
    Column.text('starts_at'),
    Column.text('ends_at'),
    Column.text('member1_id'),
    Column.text('member2_id'),
    Column.text('member3_id'),
    Column.text('member4_id'),
    Column.text('member5_id'),
    Column.text('user_stats'), // JSONB
    Column.text('member1_stats'), // JSONB
    Column.text('member2_stats'), // JSONB
    Column.text('member3_stats'), // JSONB
    Column.text('member4_stats'), // JSONB
    Column.text('member5_stats'), // JSONB
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_bc_user', [IndexedColumn('user_id')]),
    Index('idx_bc_status', [IndexedColumn('status')])
  ]),

  Table('mentorship_connections', [
    Column.text('owner_id'),
    Column.text('mentor_id'),
    Column.text('request_type'),
    Column.text('request_status'),
    Column.text('request_message'),
    Column.text('response_message'),
    Column.text('requested_at'),
    Column.text('responded_at'),
    Column.text('relationship_type'),
    Column.text('relationship_label'),
    Column.text('allowed_screens'), // JSONB
    Column.text('permissions'),     // JSONB
    Column.text('duration'),
    Column.text('starts_at'),
    Column.text('expires_at'),
    Column.text('access_status'),
    Column.integer('is_live_enabled'),
    Column.integer('view_count'),
    Column.text('last_viewed_at'),
    Column.text('last_viewed_screen'),
    Column.text('cached_snapshot'), // JSONB
    Column.text('snapshot_captured_at'),
    Column.integer('notify_owner_on_view'),
    Column.integer('notify_mentor_on_update'),
    Column.integer('notify_mentor_on_inactive'),
    Column.integer('inactive_threshold_days'),
    Column.text('last_encouragement_at'),
    Column.text('last_encouragement_type'),
    Column.text('last_encouragement_message'),
    Column.integer('encouragement_count'),
    Column.text('created_at'),
    Column.text('updated_at')
  ], indexes: [
    Index('idx_mentorship_owner', [IndexedColumn('owner_id')]),
    Index('idx_mentorship_mentor', [IndexedColumn('mentor_id')]),
    Index('idx_mentorship_status', [IndexedColumn('access_status')])
  ]),

  // --- LOCAL ONLY TABLES (Not Synced) ---

  Table.localOnly('media_sync_queue', [
    Column.text('local_path'),
    Column.text('bucket_name'),
    Column.text('storage_path'),
    Column.text('status'),
    Column.integer('retry_count'),
    Column.text('created_at'),
  ]),

  Table.localOnly('local_sync_exclusions', [
    Column.text('excluded_id'),
    Column.text('table_name'),
    Column.text('created_at'),
  ]),

  Table.localOnly('media_cache_index', [
    Column.text('storage_path'),
    Column.text('bucket_name'),
    Column.text('local_path'),
    Column.text('public_url'),
    Column.text('signed_url'),
    Column.text('signed_url_expires_at'),
    Column.text('created_at'),
    Column.text('last_accessed'),
  ], indexes: [
    Index('idx_media_cache_path', [IndexedColumn('storage_path')])
  ]),
]);
