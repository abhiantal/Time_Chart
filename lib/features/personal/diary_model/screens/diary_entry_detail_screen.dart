// lib/features/diary/screens_widgets/diary_entry_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../widgets/error_handler.dart';
import '../../../../../helpers/card_color_helper.dart';
import '../../../../../widgets/bar_progress_indicator.dart';
import '../../../../../widgets/circular_progress_indicator.dart';
import '../../../../../widgets/logger.dart';
import '../../../../media_utility/media_display.dart';
import '../../../../../widgets/metric_indicators.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../repositories/diary_repository.dart';
import '../models/diary_entry_model.dart';
import 'diary_options_menu.dart';

class DiaryEntryDetailScreen extends StatefulWidget {
  final String entryId;
  final DiaryEntryModel? entry;

  const DiaryEntryDetailScreen({super.key, required this.entryId, this.entry});

  @override
  State<DiaryEntryDetailScreen> createState() => _DiaryEntryDetailScreenState();
}

class _DiaryEntryDetailScreenState extends State<DiaryEntryDetailScreen>
    with TickerProviderStateMixin {
  final _diaryRepo = DiaryRepository();
  final _mediaService = UniversalMediaService();

  DiaryEntryModel? _entry;
  bool _isLoading = true;

  // Media related state
  List<EnhancedMediaFile> _mediaFiles = [];
  bool _isLoadingMedia = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    logI('📖 Initializing DiaryEntryDetailScreen for entry: ${widget.entryId}');

    _initAnimations();

    if (widget.entry != null) {
      _entry = widget.entry;
      _isLoading = false;
      _fadeController.forward();
      _slideController.forward();
      _loadMediaFiles();
    } else {
      _loadEntry();
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  Future<void> _loadEntry() async {
    try {
      logD('Loading entry: ${widget.entryId}');
      final entry = await _diaryRepo.getEntryById(widget.entryId);

      if (mounted) {
        setState(() {
          _entry = entry;
          _isLoading = false;
        });

        if (entry != null) {
          _fadeController.forward();
          _slideController.forward();
          _loadMediaFiles();
          logI('✅ Entry loaded successfully');
        } else {
          logW('⚠️ Entry not found');
        }
      }
    } catch (e, stackTrace) {
      logE('❌ Error loading entry', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackbar('Failed to load entry');
      }
    }
  }

  /// Load media files from attachments
  Future<void> _loadMediaFiles() async {
    if (_entry == null) return;

    // Check if entry has attachments
    if (!_entry!.hasAttachments ||
        _entry!.attachments == null ||
        _entry!.attachments!.isEmpty) {
      logD('No attachments to load');
      return;
    }

    setState(() => _isLoadingMedia = true);

    try {
      logD('Loading ${_entry!.attachments!.length} media files');

      final List<EnhancedMediaFile> loadedFiles = [];

      for (int i = 0; i < _entry!.attachments!.length; i++) {
        final attachment = _entry!.attachments![i];

        // Get valid signed URL if needed
        String validUrl = attachment.url;
        if (attachment.url.contains('supabase') ||
            attachment.url.contains('storage')) {
          final signedUrl = await _mediaService.getValidAvatarUrl(
            attachment.url,
          );
          if (signedUrl != null && signedUrl.isNotEmpty) {
            validUrl = signedUrl;
          }
        }

        if (validUrl.isNotEmpty) {
          // Convert DiaryAttachment to EnhancedMediaFile
          loadedFiles.add(attachment.toMediaFile());
        }
      }

      if (mounted) {
        setState(() {
          _mediaFiles = loadedFiles;
          _isLoadingMedia = false;
        });
        logI('✅ Loaded ${loadedFiles.length} media files');
      }
    } catch (e, stackTrace) {
      logE('❌ Error loading media files', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoadingMedia = false);
      }
    }
  }

  void _shareEntry() {
    if (_entry == null) return;

    final shareText =
        '''
📔 Diary Entry - ${DateFormat('MMMM d, yyyy').format(_entry!.entryDate)}

${_entry!.title != null ? '📝 ${_entry!.title}\n\n' : ''}${_entry!.content ?? ''}

${_entry!.hasMood ? '😊 Mood: ${_entry!.mood!.label} (${_entry!.mood!.rating}/10)' : ''}

${_entry!.aiSummary != null ? '\n🤖 AI Summary:\n${_entry!.aiSummary}' : ''}
    ''';

    Share.share(shareText, subject: 'My Diary Entry');
    logI('📤 Entry shared');
  }

  Future<void> _toggleFavorite() async {
    if (_entry == null) return;

    final newValue = !_entry!.isFavorite;
    final success = await _diaryRepo.toggleFavorite(widget.entryId, newValue);

    if (success && mounted) {
      setState(() {
        _entry = _entry!.copyWith(
          settings: _entry!.settings?.copyWith(isFavorite: newValue),
        );
      });
    }
  }

  Future<void> _togglePinned() async {
    if (_entry == null) return;

    final newValue = !_entry!.isPinned;
    final success = await _diaryRepo.togglePinned(widget.entryId, newValue);

    if (success && mounted) {
      setState(() {
        _entry = _entry!.copyWith(
          settings: _entry!.settings?.copyWith(isPinned: newValue),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entry == null
          ? _buildNotFoundView(theme)
          : _buildDetailView(theme),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build the Floating Action Button

  Widget _buildNotFoundView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book_outlined,
                size: 60,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Entry Not Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This diary entry may have been deleted.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(theme),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 100,
                ), // Added bottom padding for FAB
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(theme),
                    const SizedBox(height: 6),
                    if (_entry!.hasMood) ...[
                      _buildMoodSection(theme),
                      const SizedBox(height: 6),
                    ],
                    _buildContentSection(theme),
                    const SizedBox(height: 6),
                    // MEDIA SECTION
                    if (_entry!.hasAttachments) ...[
                      _buildMediaSection(theme),
                      const SizedBox(height: 6),
                    ],
                    if (_entry!.hasQnA) ...[
                      _buildQnASection(theme),
                      const SizedBox(height: 6),
                    ],
                    if (_entry!.aiSummary != null) ...[
                      _buildAISummarySection(theme),
                      const SizedBox(height: 6),
                    ],
                    if (_entry!.linkedItems?.hasLinks ?? false) ...[
                      _buildLinkedItemsSection(theme),
                      const SizedBox(height: 6),
                    ],
                    _buildMetadataSection(theme),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    final gradient = CardColorHelper.getDynamicGradient(
      context,
      recordId: _entry!.id,
      priority: _entry!.mood?.label,
      status: 'completed',
      progress: _calculateCompletionProgress(),
      rating: null,
      createdAt: null,
      dueDate: null,
    );

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      title: Text(
        _entry!.title ?? DateFormat('MMM d, yyyy').format(_entry!.entryDate),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PatternPainter(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _entry!.title ??
                          DateFormat('MMM d, yyyy').format(_entry!.entryDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(_entry!.entryDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _entry!.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
          ),
          onPressed: _toggleFavorite,
          tooltip: _entry!.isFavorite
              ? 'Remove from Favorites'
              : 'Add to Favorites',
        ),
        IconButton(
          icon: Icon(
            _entry!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: Colors.white,
          ),
          onPressed: _togglePinned,
          tooltip: _entry!.isPinned ? 'Unpin' : 'Pin',
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareEntry,
          tooltip: 'Share',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            if (_entry != null) {
              showDiaryOptionsMenu(
                context,
                _entry!,
                onStateChanged: () {
                  // Refresh entry to reflect changes (e.g. isPosted status)
                  _loadEntry();
                },
              );
            }
          },
          tooltip: 'More',
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    final wordCount = _entry!.wordCount;
    final qnaCount = _entry!.shotQna?.length ?? 0;
    final answeredCount =
        _entry!.shotQna?.where((q) => q.isAnswered).length ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            icon: Icons.text_fields,
            value: '$wordCount',
            label: 'Words',
          ),
          _buildVerticalDivider(theme),
          _buildStatItem(
            theme,
            icon: Icons.question_answer,
            value: '$answeredCount/$qnaCount',
            label: 'Questions',
          ),
          _buildVerticalDivider(theme),
          _buildStatItem(
            theme,
            icon: Icons.access_time,
            value: DateFormat('h:mm a').format(_entry!.createdAt),
            label: 'Created',
          ),
          _buildVerticalDivider(theme),
          Column(
            children: [
              AdvancedProgressIndicator(
                progress: _calculateCompletionProgress() / 100,
                size: 52,
                strokeWidth: 5,
                shape: ProgressShape.circular,
                labelStyle: ProgressLabelStyle.percentage,
                animated: true,
              ),
              const SizedBox(height: 6),
              Text(
                'Complete',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 26, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 50,
      width: 1,
      color: theme.colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildMoodSection(ThemeData theme) {
    final mood = _entry!.mood!;
    final moodRating = mood.rating.toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood, size: 26, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Mood',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getMoodColors(mood.label),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getMoodColors(mood.label)[0].withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      mood.emoji ?? '😊',
                      style: const TextStyle(fontSize: 45),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mood.label ?? 'Unknown',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TaskMetricIndicator(
                            type: TaskMetricType.rating,
                            value: moodRating / 2,
                            size: 26,
                            showLabel: false,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${mood.rating}/10',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomProgressIndicator(
                        progress: moodRating / 10,
                        progressBarName: '',
                        baseHeight: 10,
                        maxHeightIncrease: 0,
                        borderRadius: 5,
                        progressColor: _getMoodColors(mood.label)[0],
                        progressLabelDisplay: ProgressLabelDisplay.none,
                        nameLabelPosition: LabelPosition.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getMoodColors(String? label) {
    switch (label?.toLowerCase()) {
      case 'great':
      case 'excited':
      case 'motivated':
      case 'happy':
        return [Colors.green.shade400, Colors.green.shade700];
      case 'good':
      case 'content':
        return [Colors.lightGreen.shade400, Colors.lightGreen.shade700];
      case 'okay':
      case 'neutral':
        return [Colors.amber.shade400, Colors.amber.shade700];
      case 'bad':
      case 'sad':
        return [Colors.orange.shade400, Colors.orange.shade700];
      case 'terrible':
      case 'stressed':
      case 'anxious':
        return [Colors.red.shade400, Colors.red.shade700];
      default:
        return [Colors.grey.shade400, Colors.grey.shade700];
    }
  }

  Widget _buildContentSection(ThemeData theme) {
    if (_entry!.content == null || _entry!.content!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.article_outlined,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'No content written for this entry',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article, size: 26, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Journal Entry',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SelectableText(
              _entry!.content!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.8,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Media Section to display attachments
  Widget _buildMediaSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    size: 24,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_entry!.attachments?.length ?? 0} file${(_entry!.attachments?.length ?? 0) != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_entry!.attachments != null &&
                    _entry!.attachments!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_entry!.attachments!.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (_isLoadingMedia)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading media...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_mediaFiles.isNotEmpty)
              EnhancedMediaDisplay(
                mediaFiles: _mediaFiles,
                config: MediaDisplayConfig(
                  layoutMode: _mediaFiles.length == 1
                      ? MediaLayoutMode.single
                      : _mediaFiles.length <= 4
                      ? MediaLayoutMode.grid
                      : MediaLayoutMode.masonry,
                  mediaBucket: MediaBucket.diaryMedia,
                  borderRadius: 12,
                  spacing: 8,
                  showFileName: false,
                  showFileSize: false,
                  showDate: false,
                  allowDelete: false,
                  allowFullScreen: true,
                  gridColumns: _mediaFiles.length == 1 ? 1 : 2,
                  maxHeight: _mediaFiles.length == 1 ? 300 : 400,
                ),
                emptyMessage: 'No media files',
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No media to display',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQnASection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.question_answer,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Reflections',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_entry!.shotQna!.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...(_entry!.shotQna!.asMap().entries.map((entry) {
              final index = entry.key;
              final qna = entry.value;
              return _buildQnAItem(theme, index, qna);
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildQnAItem(ThemeData theme, int index, DiaryQnA qna) {
    final hasAnswer = qna.isAnswered;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAnswer
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAnswer
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: hasAnswer
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        )
                      : null,
                  color: hasAnswer
                      ? null
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: hasAnswer
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qna.question,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    if (qna.isMCQ) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: qna.optionsList.map((option) {
                          final isSelected = option == qna.answer;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.2)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline.withOpacity(
                                        0.3,
                                      ),
                              ),
                            ),
                            child: Text(
                              option,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasAnswer)
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
            ],
          ),
          if (hasAnswer && !qna.isMCQ) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 22,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      qna.answer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!hasAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 44),
              child: Text(
                'Not answered',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAISummarySection(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              _entry!.aiSummary!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.7,
                letterSpacing: 0.2,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedItemsSection(ThemeData theme) {
    final linkedItems = _entry!.linkedItems;
    if (linkedItems == null || !linkedItems.hasLinks) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, size: 26, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Linked Items',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${linkedItems.totalCount}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (linkedItems.longGoals.isNotEmpty) ...[
              _buildLinkedCategory(
                theme,
                title: 'Goals',
                icon: Icons.flag,
                items: linkedItems.longGoals,
                color: Colors.purple,
              ),
              const SizedBox(height: 12),
            ],
            if (linkedItems.dayTasks.isNotEmpty) ...[
              _buildLinkedCategory(
                theme,
                title: 'Day Tasks',
                icon: Icons.today,
                items: linkedItems.dayTasks,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
            ],
            if (linkedItems.weeklyTasks.isNotEmpty) ...[
              _buildLinkedCategory(
                theme,
                title: 'Weekly Tasks',
                icon: Icons.date_range,
                items: linkedItems.weeklyTasks,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
            ],
            if (linkedItems.bucketItems.isNotEmpty)
              _buildLinkedCategory(
                theme,
                title: 'Bucket List',
                icon: Icons.stars,
                items: linkedItems.bucketItems,
                color: Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedCategory(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<LinkedItem> items,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Chip(
                  label: Text(
                    item.title ?? item.id.substring(0, 8),
                    style: theme.textTheme.bodySmall,
                  ),
                  avatar: Icon(icon, size: 16, color: color),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Entry Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetadataRow(
              theme,
              icon: Icons.fingerprint,
              label: 'Entry ID',
              value: _entry!.id.length > 12
                  ? '${_entry!.id.substring(0, 12)}...'
                  : _entry!.id,
            ),
            _buildMetadataRow(
              theme,
              icon: Icons.create,
              label: 'Created',
              value: DateFormat(
                'MMM d, yyyy • h:mm a',
              ).format(_entry!.createdAt),
            ),
            _buildMetadataRow(
              theme,
              icon: Icons.update,
              label: 'Last Updated',
              value: DateFormat(
                'MMM d, yyyy • h:mm a',
              ).format(_entry!.updatedAt),
            ),
            _buildMetadataRow(
              theme,
              icon: Icons.text_snippet,
              label: 'Word Count',
              value: '${_entry!.wordCount} words',
            ),
            if (_entry!.hasAttachments)
              _buildMetadataRow(
                theme,
                icon: Icons.attach_file,
                label: 'Attachments',
                value: '${_entry!.attachments!.length} files',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCompletionProgress() {
    int progress = 0;

    if (_entry!.hasTitle) progress += 20;
    if (_entry!.hasMood) progress += 20;
    if ((_entry!.content?.length ?? 0) > 0) {
      progress += ((_entry!.content!.length / 500) * 40).clamp(0, 40).toInt();
    }
    if (_entry!.hasQnA) {
      final answered = _entry!.shotQna!.where((q) => q.isAnswered).length;
      progress += ((answered / _entry!.shotQna!.length) * 20).toInt();
    }
    return progress.clamp(0, 100);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

// Pattern Painter for App Bar Background
class _PatternPainter extends CustomPainter {
  final Color color;

  _PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 25.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
