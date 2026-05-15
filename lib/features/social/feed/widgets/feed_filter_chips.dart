import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/feed_screen.dart';

class FeedFilterChips extends StatelessWidget {
  final String currentUserId;
  final FeedType selectedType;
  final Function(FeedType) onTypeSelected;

  const FeedFilterChips({
    super.key,
    required this.currentUserId,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final List<_FilterChipData> _chips = const [
    _FilterChipData(
      type: FeedType.home,
      label: 'For You',
      icon: Icons.explore,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    _FilterChipData(
      type: FeedType.following,
      label: 'Following',
      icon: Icons.people,
      gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    ),
    _FilterChipData(
      type: FeedType.trending,
      label: 'Trending',
      icon: Icons.trending_up,
      gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
    _FilterChipData(
      type: FeedType.live,
      label: 'Live',
      icon: Icons.sensors,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    _FilterChipData(
      type: FeedType.media,
      label: 'Media',
      icon: Icons.video_library,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        itemBuilder: (context, index) {
          final chip = _chips[index];
          final isSelected = chip.type == selectedType;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTypeSelected(chip.type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: chip.gradient)
                      : null,
                  color: isSelected
                      ? null
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: chip.gradient.first.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chip.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChipData {
  final FeedType type;
  final String label;
  final IconData icon;
  final List<Color> gradient;

  const _FilterChipData({
    required this.type,
    required this.label,
    required this.icon,
    required this.gradient,
  });
}
