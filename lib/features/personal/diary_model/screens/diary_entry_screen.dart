// lib/features/diary/screens_widgets/diary_entry_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../widgets/error_handler.dart';
import '../../../../../widgets/app_snackbar.dart';
import '../../../../../widgets/logger.dart';
import '../../../../media_utility/media_display.dart';
import '../../../../media_utility/media_picker.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../../../../widgets/custom_text_field.dart';
import '../providers/diary_ai_provider.dart';
import '../repositories/diary_repository.dart';
import '../models/diary_entry_model.dart';

// Import other feature repositories
import '../../task_model/long_goal/repositories/long_goals_repository.dart';
import '../../task_model/day_tasks/repositories/day_task_repository.dart';
import '../../task_model/week_task/repositories/week_task_repository.dart';
import '../../bucket_model/repositories/bucket_repository.dart';

class DiaryEntryScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const DiaryEntryScreen({super.key, this.selectedDate});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _diaryRepo = DiaryRepository();
  final _mediaService = UniversalMediaService();
  final _scrollController = ScrollController();

  // State variables
  late DateTime _entryDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<DiaryQnA> _questions = [];
  DiaryMood? _mood;
  String? _generatedSummary;
  bool _isLoading = false;
  bool _isGeneratingQuestions = false;

  // Media management
  final List<EnhancedMediaFile> _selectedMedia = [];
  List<EnhancedMediaFile> _existingMedia = [];
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;

  // UI state
  bool _showScrollToTop = false;

  // Question answer controllers map
  final Map<int, TextEditingController> _answerControllers = {};

  @override
  void initState() {
    super.initState();
    logI('📝 Initializing DiaryEntryScreen');

    _entryDate = widget.selectedDate ?? DateTime.now();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _scrollController.addListener(_onScroll);

    logD('Generating new questions for date: ${_entryDate.toIso8601String()}');
    _generateQuestions();
  }

  void _onScroll() {
    final showButton = _scrollController.offset > 200;
    if (showButton != _showScrollToTop) {
      setState(() => _showScrollToTop = showButton);
    }
  }

  // ================================================================
  // 📸 MEDIA PICKER METHODS
  // ================================================================
  Future<void> _pickMedia() async {
    try {
      final config = MediaPickerConfig(
        allowCamera: true,
        allowGallery: true,
        allowImage: true,
        allowVideo: true,
        allowAudio: true,
        allowDocument: false,
        autoCompress: true,
        imageQuality: 70,
        maxFileSizeMB: 30,
      );

      final pickedFile = await EnhancedMediaPicker.pickMedia(
        context,
        config: config,
      );

      if (pickedFile != null) {
        final mediaFile = EnhancedMediaFile.fromFile(
          file: File(pickedFile.path),
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        );

        setState(() {
          _selectedMedia.add(mediaFile);
        });

        HapticFeedback.lightImpact();
        snackbarService.showSuccess(
          'Media Added',
          description: 'File added successfully',
        );
      }
    } catch (e) {
      logE('Error picking media', error: e);
      ErrorHandler.showErrorSnackbar('Failed to pick media');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final config = MediaPickerConfig(
        allowImage: true,
        autoCompress: true,
        imageQuality: 70,
        maxFileSizeMB: 30,
      );

      final pickedFiles = await EnhancedMediaPicker.pickMultipleMedia(
        context,
        config: config,
        maxFiles: 10,
      );

      if (pickedFiles.isNotEmpty) {
        final mediaFiles = pickedFiles.map((xFile) {
          return EnhancedMediaFile.fromFile(
            file: File(xFile.path),
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${xFile.name}',
          );
        }).toList();

        setState(() {
          _selectedMedia.addAll(mediaFiles);
        });

        HapticFeedback.lightImpact();
        snackbarService.showSuccess(
          'Images Added',
          description: '${pickedFiles.length} image(s) selected',
        );
      }
    } catch (e) {
      logE('Error picking multiple images', error: e);
      ErrorHandler.showErrorSnackbar('Failed to pick images');
    }
  }

  void _removeMedia(String mediaId) {
    setState(() {
      _selectedMedia.removeWhere((m) => m.id == mediaId);
      _existingMedia.removeWhere((m) => m.id == mediaId);
    });
    HapticFeedback.mediumImpact();
    snackbarService.showInfo('Media removed');
  }

  // ================================================================
  // 📝 GENERATE QUESTIONS
  // ================================================================
  Future<void> _generateQuestions() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final aiProvider = context.read<DiaryAIProvider>();

    setState(() => _isGeneratingQuestions = true);

    try {
      logD('Fetching linked goals and tasks for context');
      final linkedGoals = await _fetchUserGoals(userId);
      final linkedTasks = await _fetchUserTasks(userId);

      logI('🤖 Starting AI question generation...');
      final questionsMap = await aiProvider.generateDailyQuestions(
        userId: userId,
        linkedGoals: linkedGoals,
        linkedTasks: linkedTasks,
        entryDate: _entryDate,
        showLoadingIndicator: true,
      );

      // Convert Map<String, String> to DiaryQnA
      final questions = questionsMap.map((q) {
        return DiaryQnA(
          qnaNumber: q['qna_number'] ?? '0',
          type: q['type'] ?? 'short_answer',
          question: q['question'] ?? '',
          options: q['options'],
          answer: q['answer'] ?? '',
        );
      }).toList();

      // Initialize answer controllers
      _answerControllers.clear();
      for (int i = 0; i < questions.length; i++) {
        _answerControllers[i] = TextEditingController(
          text: questions[i].answer,
        );
      }

      setState(() {
        _questions = questions;
        _isGeneratingQuestions = false;
      });

      logI('✅ Generated ${questions.length} diary questions');
    } catch (e, stackTrace) {
      logE('❌ Error generating questions', error: e, stackTrace: stackTrace);
      setState(() => _isGeneratingQuestions = false);
      ErrorHandler.showErrorSnackbar('Failed to generate questions');
    }
  }

  // ================================================================
  // 💾 SAVE ENTRY
  // ================================================================
  Future<void> _saveEntry() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ErrorHandler.showErrorSnackbar('Please sign in to save entry');
      return;
    }
    final userId = user.id;

    // Update questions with current answers from controllers
    for (int i = 0; i < _questions.length; i++) {
      if (_answerControllers.containsKey(i)) {
        _questions[i] = DiaryQnA(
          qnaNumber: _questions[i].qnaNumber,
          type: _questions[i].type,
          question: _questions[i].question,
          options: _questions[i].options,
          answer: _answerControllers[i]!.text,
        );
      }
    }

    if (_contentController.text.trim().isEmpty &&
        _questions.every((q) => q.answer.trim().isEmpty) &&
        _selectedMedia.isEmpty &&
        _existingMedia.isEmpty) {
      logW('⚠️ No content provided for entry');
      ErrorHandler.showWarningSnackbar(
        'Please add some content, answer questions, or attach media',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      logI('💾 Saving diary entry...');

      List<DiaryAttachment> allAttachments = [];

      // Convert existing media
      allAttachments.addAll(
        _existingMedia.map((m) => DiaryAttachment.fromMediaFile(m)),
      );

      // Upload new media files
      if (_selectedMedia.isNotEmpty) {
        setState(() => _isUploadingMedia = true);

        final localFiles = _selectedMedia
            .where((m) => m.isLocal)
            .map((m) => File(m.url))
            .toList();

        if (localFiles.isNotEmpty) {
          final uploadedUrls = await _mediaService.uploadMultiple(
            files: localFiles,
            bucket: MediaBucket.diaryMedia,
            customPath: 'diary/${_entryDate.year}/${_entryDate.month}',
            autoCompress: true,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );

          logI('✅ Uploaded ${uploadedUrls.length} media files');

          for (int i = 0; i < uploadedUrls.length; i++) {
            final url = uploadedUrls[i];
            final media = _selectedMedia[i];

            allAttachments.add(
              DiaryAttachment(
                id: 'att_${DateTime.now().millisecondsSinceEpoch}_\$i',
                type: _mediaTypeToString(media.type),
                url: url,
              ),
            );
          }
        }

        setState(() => _isUploadingMedia = false);
      }

      logD('Creating new entry for date: ${_entryDate.toIso8601String()}');
      final savedEntry = await _diaryRepo.createEntry(
        userId: userId,
        entryDate: _entryDate,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        mood: _mood,
        shotQna: _questions,
        attachments: allAttachments,
        linkedItems: DiaryLinkedItems(
          longGoals: (await _fetchUserGoals(userId)).map((e) => LinkedItem.fromJson(e)).toList(),
          dayTasks: (await _fetchUserTasks(userId)).map((e) => LinkedItem.fromJson(e)).toList(),
          weeklyTasks: (await _fetchWeeklyTasks(userId)).map((e) => LinkedItem.fromJson(e)).toList(),
          bucketItems: (await _fetchBucketItems(userId)).map((e) => LinkedItem.fromJson(e)).toList(),
        ),
      );

      if (savedEntry == null) {
        // Validation failed, snackbar already shown by repository
        setState(() {
          _isLoading = false;
          _isUploadingMedia = false;
        });
        return;
      }

      await _generateSummary(savedEntry);

      setState(() => _isLoading = false);

      if (mounted) {
        logI('✅ Diary entry saved successfully!');
        snackbarService.showSuccess(
          'Entry Saved',
          description: 'Ready for reward!',
        );
        context.pop(true);
      }
    } catch (e, stackTrace) {
      logE('❌ Error saving entry', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
        _isUploadingMedia = false;
      });
      if (mounted) {
        ErrorHandler.showErrorSnackbar('Failed to save entry');
      }
    }
  }

  String _mediaTypeToString(MediaFileType type) {
    switch (type) {
      case MediaFileType.image:
        return 'image';
      case MediaFileType.video:
        return 'video';
      case MediaFileType.audio:
        return 'audio';
      case MediaFileType.document:
        return 'document';
    }
  }

  // ================================================================
  // 🤖 GENERATE SUMMARY
  // ================================================================
  Future<void> _generateSummary(DiaryEntryModel entry) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final userId = user.id;
    final aiProvider = context.read<DiaryAIProvider>();

    try {
      logI('🤖 Starting AI summary generation...');

      final linkedGoals = await _fetchUserGoals(userId);
      final linkedTasks = await _fetchUserTasks(userId);

      // Convert DiaryMood to Map for AI provider
      Map<String, dynamic>? moodMap;
      if (entry.mood != null) {
        moodMap = entry.mood!.toJson();
      }

      // Convert DiaryQnA list to List<Map<String, dynamic>> for AI provider
      List<Map<String, dynamic>>? qnaList;
      if (entry.shotQna != null) {
        qnaList = entry.shotQna!.map((q) => q.toJson()).toList();
      }

      final summary = await aiProvider.generateDiarySummary(
        entryId: entry.id,
        userId: userId,
        content: entry.content ?? '',
        title: entry.title,
        mood: moodMap,
        qnaAnswers: qnaList,
        linkedGoals: linkedGoals,
        linkedTasks: linkedTasks,
        showLoadingIndicator: true,
      );

      if (summary != null) {
        await _diaryRepo.updateAISummary(entryId: entry.id, summary: summary);

        setState(() {
          _generatedSummary = summary;
        });

        logI('✅ AI summary generated');
      }
    } catch (e, stackTrace) {
      logE('❌ Error generating summary', error: e, stackTrace: stackTrace);
    }
  }

  // ================================================================
  // 🎨 MAIN BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildBackgroundGradient(colorScheme),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(colorScheme),
              SliverToBoxAdapter(
                child: _isLoading && !_isUploadingMedia
                    ? _buildLoadingState(colorScheme)
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            120 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateCard(colorScheme),
                              const SizedBox(height: 20),
                              _buildProgressCard(colorScheme),
                              const SizedBox(height: 20),
                              _buildTitleCard(colorScheme),
                              const SizedBox(height: 20),
                              _buildMoodCard(colorScheme),
                              const SizedBox(height: 20),
                              _buildContentCard(colorScheme),
                              const SizedBox(height: 20),
                              _buildMediaCard(colorScheme),
                              const SizedBox(height: 20),
                              _buildQuestionsCard(colorScheme),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: _buildSaveButton(colorScheme),
          ),
          if (_showScrollToTop)
            Positioned(
              bottom: 100,
              right: 20,
              child: _buildScrollToTopButton(colorScheme),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // 🎨 BACKGROUND GRADIENT
  // ================================================================
  Widget _buildBackgroundGradient(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.1),
            colorScheme.surface,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
    );
  }

  // ================================================================
  // 📱 SLIVER APP BAR
  // ================================================================
  Widget _buildSliverAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface.withOpacity(0.95),
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        title: Text(
          '📝 New Entry',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.4),
                colorScheme.secondaryContainer.withOpacity(0.2),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.secondary.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_generatedSummary != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _showSummary,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              tooltip: 'View AI Summary',
            ),
          ),
      ],
    );
  }

  // ================================================================
  // 🔄 LOADING STATE
  // ================================================================
  Widget _buildLoadingState(ColorScheme colorScheme) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '✨ Saving your memories...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will only take a moment',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // 📅 DATE CARD
  // ================================================================
  Widget _buildDateCard(ColorScheme colorScheme) {
    final isToday = _isToday(_entryDate);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${_entryDate.day}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    height: 1,
                  ),
                ),
                Text(
                  _getMonthName(_entryDate.month).substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayOfWeek(_entryDate.weekday),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getTimeOfDayIcon(_entryDate),
                      size: 16,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${_getMonthName(_entryDate.month)} ${_entryDate.year} • ${_getTimeOfDay(_entryDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onPrimaryContainer.withOpacity(
                            0.7,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wb_sunny_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Today',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // 📊 PROGRESS CARD
  // ================================================================
  Widget _buildProgressCard(ColorScheme colorScheme) {
    final progress = _calculateEntryProgress();
    final progressColor = _getProgressColor(progress);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: progressColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entry Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getProgressMessage(progress),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [progressColor, progressColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${progress.toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: 12,
                  width:
                      (MediaQuery.of(context).size.width - 72) *
                      (progress / 100),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [progressColor, progressColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressItem(
                Icons.title_rounded,
                'Title',
                _titleController.text.isNotEmpty,
                colorScheme,
              ),
              _buildProgressItem(
                Icons.mood_rounded,
                'Mood',
                _mood != null,
                colorScheme,
              ),
              _buildProgressItem(
                Icons.article_rounded,
                'Content',
                _contentController.text.length >= 50,
                colorScheme,
              ),
              _buildProgressItem(
                Icons.photo_library_rounded,
                'Media',
                _selectedMedia.isNotEmpty || _existingMedia.isNotEmpty,
                colorScheme,
              ),
              _buildProgressItem(
                Icons.quiz_rounded,
                'Q&A',
                _questions.any((q) => q.answer.isNotEmpty),
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    IconData icon,
    String label,
    bool isCompleted,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withOpacity(0.1)
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            size: 20,
            color: isCompleted ? Colors.green : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
            color: isCompleted ? Colors.green : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // 📝 TITLE CARD
  // ================================================================
  Widget _buildTitleCard(ColorScheme colorScheme) {
    return _buildSectionCard(
      colorScheme: colorScheme,
      icon: Icons.title_rounded,
      iconColor: Colors.indigo,
      title: 'Title',
      subtitle: 'Give your day a memorable title',
      child: CustomTextField(
        controller: _titleController,
        hint: 'e.g., A productive Monday ✨',
        prefixIcon: Icons.edit_note_rounded,
        maxLines: 1,
        borderRadius: BorderRadius.circular(16),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  // ================================================================
  // 😊 MOOD CARD
  // ================================================================
  Widget _buildMoodCard(ColorScheme colorScheme) {
    return _buildSectionCard(
      colorScheme: colorScheme,
      icon: Icons.mood_rounded,
      iconColor: Colors.amber,
      title: 'How are you feeling?',
      subtitle: 'Track your emotional wellbeing',
      trailing: _mood != null
          ? IconButton(
              onPressed: () {
                setState(() => _mood = null);
                HapticFeedback.lightImpact();
              },
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildMoodOption(
                  '😄',
                  'Amazing',
                  10,
                  const Color(0xFF4CAF50),
                  colorScheme,
                ),
                const SizedBox(width: 10),
                _buildMoodOption(
                  '😊',
                  'Good',
                  8,
                  const Color(0xFF8BC34A),
                  colorScheme,
                ),
                const SizedBox(width: 10),
                _buildMoodOption(
                  '😐',
                  'Okay',
                  6,
                  const Color(0xFFFFC107),
                  colorScheme,
                ),
                const SizedBox(width: 10),
                _buildMoodOption(
                  '😔',
                  'Sad',
                  4,
                  const Color(0xFFFF9800),
                  colorScheme,
                ),
                const SizedBox(width: 10),
                _buildMoodOption(
                  '😢',
                  'Rough',
                  2,
                  const Color(0xFFF44336),
                  colorScheme,
                ),
              ],
            ),
          ),
          if (_mood != null) ...[
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getMoodColor(_mood!.rating).withOpacity(0.15),
                    _getMoodColor(_mood!.rating).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getMoodColor(_mood!.rating).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _mood!.emoji ?? '😊',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Feeling ${_mood!.label ?? "Good"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 16,
                              color: _getMoodColor(_mood!.rating),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Mood Score: ${_mood!.rating}/10',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodOption(
    String emoji,
    String label,
    int rating,
    Color color,
    ColorScheme colorScheme,
  ) {
    final isSelected = _mood?.label == label;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _mood = DiaryMood(
            rating: rating,
            label: label,
            score: rating.toDouble(),
            emoji: emoji,
          );
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                emoji,
                style: TextStyle(fontSize: isSelected ? 36 : 28),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: isSelected ? 13 : 11,
                color: isSelected ? color : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // 📝 CONTENT CARD
  // ================================================================
  Widget _buildContentCard(ColorScheme colorScheme) {
    final wordCount = _contentController.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final charCount = _contentController.text.length;

    return _buildSectionCard(
      colorScheme: colorScheme,
      icon: Icons.article_rounded,
      iconColor: Colors.blue,
      title: "What's on your mind?",
      subtitle: 'Write about your day, thoughts, or feelings',
      trailing: charCount >= 500
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Great!',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: Column(
        children: [
          CustomTextField.multiline(
            controller: _contentController,
            hint:
                'Today I...\n\nI felt grateful for...\n\nSomething I learned...',
            maxLines: 10,
            maxLength: 5000,
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatChip(
                    Icons.text_fields_rounded,
                    '$charCount chars',
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    Icons.short_text_rounded,
                    '$wordCount words',
                    Colors.purple,
                  ),
                ],
              ),
              if (charCount > 0 && charCount < 50)
                Text(
                  '${50 - charCount} chars left',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // 📷 MEDIA CARD
  // ================================================================
  Widget _buildMediaCard(ColorScheme colorScheme) {
    final allMedia = [..._existingMedia, ..._selectedMedia];

    return _buildSectionCard(
      colorScheme: colorScheme,
      icon: Icons.photo_library_rounded,
      iconColor: Colors.purple,
      title: 'Media Attachments',
      subtitle: 'Add photos, videos, or audio',
      trailing: allMedia.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${allMedia.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.blue,
                  onTap: _pickMultipleImages,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMediaButton(
                  icon: Icons.add_a_photo_rounded,
                  label: 'Camera',
                  color: Colors.purple,
                  onTap: _pickMedia,
                ),
              ),
            ],
          ),
          if (_isUploadingMedia) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Uploading... ${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (allMedia.isNotEmpty) ...[
            const SizedBox(height: 20),
            EnhancedMediaDisplay(
              mediaFiles: allMedia,
              config: const MediaDisplayConfig(
                layoutMode: MediaLayoutMode.grid,
                gridColumns: 3,
                mediaBucket: MediaBucket.diaryMedia,
                borderRadius: 16,
                spacing: 10,
                allowDelete: true,
                allowFullScreen: true,
                showFileName: false,
                showFileSize: false,
                showDate: false,
              ),
              onDelete: _removeMedia,
              emptyMessage: 'No media attached',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // 🤖 QUESTIONS CARD
  // ================================================================
  Widget _buildQuestionsCard(ColorScheme colorScheme) {
    final answeredCount = _questions.where((q) => q.answer.isNotEmpty).length;

    return _buildSectionCard(
      colorScheme: colorScheme,
      icon: Icons.psychology_rounded,
      iconColor: Colors.teal,
      title: 'AI Reflections',
      subtitle: 'Answer personalized questions',
      trailing: _isGeneratingQuestions
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.teal,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_questions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$answeredCount/${_questions.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: _generateQuestions,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Colors.teal,
                    ),
                  ),
                  tooltip: 'Generate new questions',
                ),
              ],
            ),
      child: _questions.isEmpty
          ? Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 48,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Generating personalized questions...',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI is crafting questions just for you',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: _questions.asMap().entries.map((entry) {
                return _buildQuestionItem(entry.key, entry.value, colorScheme);
              }).toList(),
            ),
    );
  }

  Widget _buildQuestionItem(
    int index,
    DiaryQnA question,
    ColorScheme colorScheme,
  ) {
    final isMCQ = question.isMCQ;
    final isAnswered = question.isAnswered;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isAnswered
            ? colorScheme.primaryContainer.withOpacity(0.2)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnswered
              ? colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isAnswered
                          ? [Colors.green, Colors.green.shade700]
                          : [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.7),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isAnswered ? Colors.green : colorScheme.primary)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isAnswered
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 1.4,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isAnswered) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Answered',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMCQ)
              ..._buildMCQOptions(index, question, colorScheme)
            else
              _buildShortAnswerInput(index, question, colorScheme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMCQOptions(
    int index,
    DiaryQnA question,
    ColorScheme colorScheme,
  ) {
    final options = question.optionsList;
    final currentAnswer = question.answer;

    return options.map((option) {
      final isSelected = currentAnswer == option;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _questions[index] = DiaryQnA(
                  qnaNumber: question.qnaNumber,
                  type: question.type,
                  question: question.question,
                  options: question.options,
                  answer: option,
                );
                _answerControllers[index]?.text = option;
              });
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.white : colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildShortAnswerInput(
    int index,
    DiaryQnA question,
    ColorScheme colorScheme,
  ) {
    // Ensure controller exists
    _answerControllers[index] ??= TextEditingController(text: question.answer);

    return CustomTextField.multiline(
      controller: _answerControllers[index],
      hint: 'Share your thoughts...',
      maxLines: 4,
      onChanged: (value) {
        setState(() {
          _questions[index] = DiaryQnA(
            qnaNumber: question.qnaNumber,
            type: question.type,
            question: question.question,
            options: question.options,
            answer: value,
          );
        });
      },
    );
  }

  // ================================================================
  // 💾 SAVE BUTTON
  // ================================================================
  Widget _buildSaveButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading || _isUploadingMedia ? null : _saveEntry,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLoading || _isUploadingMedia
                    ? [Colors.grey, Colors.grey.shade600]
                    : [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading || _isUploadingMedia)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  _isUploadingMedia
                      ? 'Uploading...'
                      : _isLoading
                      ? 'Saving...'
                      : 'Save Entry',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ⬆️ SCROLL TO TOP BUTTON
  // ================================================================
  Widget _buildScrollToTopButton(ColorScheme colorScheme) {
    return FloatingActionButton.small(
      heroTag: 'diary_entry_scroll_to_top_fab',
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      },
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.primary,
      child: const Icon(Icons.arrow_upward_rounded),
    );
  }

  // ================================================================
  // 🏗️ SECTION CARD BUILDER
  // ================================================================
  Widget _buildSectionCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  // ================================================================
  // 📖 SUMMARY DIALOG
  // ================================================================
  void _showSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Generated from your entry',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _generatedSummary ?? 'No summary available',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // 🔧 HELPER METHODS
  // ================================================================
  Future<List<Map<String, dynamic>>> _fetchUserGoals(String userId) async {
    try {
      logD('Fetching real user goals for userId: $userId');
      final repo = LongGoalsRepository();
      final goals = await repo.getUserGoals(userId: userId);
      return goals.map((g) => {
        'id': g.id,
        'title': g.title,
      }).toList();
    } catch (e) {
      logE('Error fetching goals', error: e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserTasks(String userId) async {
    try {
      logD('Fetching real user day tasks for userId: $userId');
      final repo = DayTaskRepository();
      final tasks = await repo.getUserTasks(userId, date: _entryDate);
      return tasks.map((t) => {
        'id': t.id,
        'title': t.aboutTask.taskName,
      }).toList();
    } catch (e) {
      logE('Error fetching tasks', error: e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchWeeklyTasks(String userId) async {
    try {
      logD('Fetching real weekly tasks for userId: $userId');
      final repo = WeekTaskRepository();
      final tasks = await repo.getTasksForDate(userId, _entryDate);
      return tasks.map((t) => {
        'id': t.id,
        'title': t.aboutTask.taskName,
      }).toList();
    } catch (e) {
      logE('Error fetching weekly tasks', error: e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBucketItems(String userId) async {
    try {
      logD('Fetching real bucket items for userId: $userId');
      final repo = BucketRepository();
      final buckets = await repo.getUserBuckets(userId);
      return buckets.map((b) => {
        'id': b.id,
        'title': b.details.description,
      }).toList();
    } catch (e) {
      logE('Error fetching buckets', error: e);
      return [];
    }
  }

  double _calculateEntryProgress() {
    double progress = 0;

    if (_titleController.text.trim().isNotEmpty) progress += 15;
    if (_mood != null) progress += 15;

    final contentLength = _contentController.text.length;
    if (contentLength > 0) {
      progress += (contentLength / 500 * 30).clamp(0, 30);
    }

    if (_selectedMedia.isNotEmpty || _existingMedia.isNotEmpty) {
      progress += 20;
    }

    if (_questions.isNotEmpty) {
      final answeredQuestions = _questions
          .where((q) => q.answer.trim().isNotEmpty)
          .length;
      progress += (answeredQuestions / _questions.length * 20).clamp(0, 20);
    }

    return progress.clamp(0, 100).toDouble();
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 50) return Colors.orange;
    return Colors.blue;
  }

  String _getProgressMessage(double progress) {
    if (progress >= 80) return 'Almost there! Great job! 🎉';
    if (progress >= 50) return 'Good progress! Keep going! 💪';
    if (progress >= 25) return 'Nice start! Add more details ✨';
    return 'Start writing your entry 📝';
  }

  Color _getMoodColor(int rating) {
    if (rating >= 9) return const Color(0xFF4CAF50);
    if (rating >= 7) return const Color(0xFF8BC34A);
    if (rating >= 5) return const Color(0xFFFFC107);
    if (rating >= 3) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  IconData _getTimeOfDayIcon(DateTime date) {
    final hour = date.hour;
    if (hour < 6) return Icons.nightlight_rounded;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    if (hour < 21) return Icons.nights_stay_rounded;
    return Icons.nightlight_rounded;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  @override
  void dispose() {
    logD('🗑️ Disposing DiaryEntryScreen');
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    // Dispose all answer controllers
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
