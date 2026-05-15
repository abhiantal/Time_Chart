import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ChatSharedContentScreen extends StatelessWidget {
  final String chatId;
  final String? chatName;

  const ChatSharedContentScreen({
    super.key,
    required this.chatId,
    this.chatName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          chatName != null ? '$chatName - Shared' : 'Shared Content',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildListDelegate([
                _buildCategoryCard(
                  context,
                  title: 'Media',
                  subtitle: 'Photos & Videos',
                  icon: Icons.photo_library_rounded,
                  color: Colors.blue,
                  onTap: () => context.pushNamed(
                    'chatMediaScreen',
                    pathParameters: {'chatId': chatId},
                  ),
                ),
                _buildCategoryCard(
                  context,
                  title: 'Documents',
                  subtitle: 'PDFs & Files',
                  icon: Icons.description_rounded,
                  color: Colors.orange,
                  onTap: () => context.pushNamed(
                    'chatDocumentsScreen',
                    pathParameters: {'chatId': chatId},
                  ),
                ),
                _buildCategoryCard(
                  context,
                  title: 'Links',
                  subtitle: 'Shared URLs',
                  icon: Icons.link_rounded,
                  color: Colors.teal,
                  onTap: () => context.pushNamed(
                    'chatLinksScreen',
                    pathParameters: {'chatId': chatId},
                  ),
                ),
                _buildCategoryCard(
                  context,
                  title: 'Tasks & Goals',
                  subtitle: 'Shared to-dos',
                  icon: Icons.task_alt_rounded,
                  color: Colors.purple,
                  onTap: () => context.pushNamed(
                    'chatSharedDayTasksScreen',
                    pathParameters: {'chatId': chatId},
                  ),
                ),
                _buildCategoryCard(
                  context,
                  title: 'Buckets',
                  subtitle: 'Adventures',
                  icon: Icons.explore_rounded,
                  color: Colors.red,
                  onTap: () => context.pushNamed(
                    'chatSharedBucketsScreen',
                    pathParameters: {'chatId': chatId},
                  ),
                ),
                _buildCategoryCard(
                  context,
                  title: 'Diaries',
                  subtitle: 'Daily logs',
                  icon: Icons.auto_stories_rounded,
                  color: Colors.amber,
                  onTap: () => context.pushNamed(
                    'chatSharedDiariesScreen',
                    pathParameters: {'chatId': chatId},
                  ),
                ),
                _buildCategoryCard(
                  context,
                  title: 'Posts',
                  subtitle: 'Articles & Updates',
                  icon: Icons.article_rounded,
                  color: Colors.indigo,
                  onTap: () => context.pushNamed(
                    'chatSharedPostsScreen',
                    pathParameters: {'chatId': chatId},
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
