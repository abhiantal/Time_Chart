// lib/features/personal/bucket_model/screen/add_edit_bucket_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../../widgets/app_snackbar.dart';
import '../../../../../widgets/custom_text_field.dart';
import '../../../../../widgets/logger.dart';
import '../../../../media_utility/media_display.dart';
import '../../../../media_utility/media_picker.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../category_model/models/category_model.dart';
import '../../category_model/widgets/category_picker_popup.dart';
import '../../category_model/widgets/create_category_dialog.dart';
import '../../shared_widgets/task_form_widgets.dart';
import '../models/bucket_model.dart';
import '../providers/bucket_provider.dart';
import 'package:the_time_chart/Authentication/auth_provider.dart';

class AddEditBucketPage extends StatefulWidget {
  final String? bucketId;
  const AddEditBucketPage({super.key, this.bucketId});

  @override
  State<AddEditBucketPage> createState() => _AddEditBucketPageState();
}

class _AddEditBucketPageState extends State<AddEditBucketPage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _motivationController = TextEditingController();
  final _outcomeController = TextEditingController();

  BucketModel? _original;
  CategoryPickerResult? _category;
  List<String> _mediaUrls = [];
  List<ChecklistItem> _checklist = [];
  DateTime? _dueDate;
  String _priority = 'medium';
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.bucketId != null) _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _motivationController.dispose();
    _outcomeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final provider = context.read<BucketProvider>();
      _original = provider.buckets.firstWhere((b) => b.bucketId == widget.bucketId);
      final signedUrls = <String>[];
      for (final p in _original!.details.mediaUrl) {
        final s = await UniversalMediaService().getValidAvatarUrl(p);
        signedUrls.add(s ?? p);
      }
      if (!mounted) return;
      setState(() {
        _titleController.text = _original!.title;
        _descController.text = _original!.details.description;
        _motivationController.text = _original!.details.motivation;
        _outcomeController.text = _original!.details.outCome;
        _mediaUrls = signedUrls;
        _checklist = List.from(_original!.checklist);
        _dueDate = _original!.timeline.dueDate;
        _priority = _original!.metadata.priority;
      });
    } catch (e) {
      AppSnackbar.error('Failed to load bucket');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bucketId == null ? 'Create bucket' : 'Edit bucket'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: Text(widget.bucketId == null ? 'Create' : 'Save'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Category ─────────────────────────────────────────
              TaskFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TaskSectionHeader(
                        icon: Icons.category_rounded, title: 'Category'),
                    const SizedBox(height: 14),
                    TaskCategoryTile(
                      selected: _category,
                      categoryFor: CategoryForType.bucket,
                      onSelected: (r) => setState(() => _category = r),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _pickCustomCategory,
                      icon: const Icon(Icons.add),
                      label: const Text('Create custom category'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Basic info ────────────────────────────────────────
              TaskFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TaskSectionHeader(
                        icon: Icons.edit_note_rounded,
                        title: 'Basic info'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Give your bucket a name',
                      prefixIcon: Icons.title_rounded,
                      required: true,
                      maxLength: 100,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Title is required';
                        }
                        if (v.trim().length < 3) {
                          return 'Title must be at least 3 characters long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField.multiline(
                      controller: _descController,
                      label: 'Description',
                      hint: 'What do you want to achieve?',
                      maxLines: 3,
                      maxLength: 300,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField.multiline(
                      controller: _motivationController,
                      label: 'Motivation',
                      hint: 'Why is this important to you?',
                      maxLines: 3,
                      maxLength: 300,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField.multiline(
                      controller: _outcomeController,
                      label: 'Expected outcome',
                      hint: 'What will you achieve?',
                      maxLines: 3,
                      maxLength: 300,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Checklist ─────────────────────────────────────────
              TaskFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TaskSectionHeader(
                            icon: Icons.checklist_rounded,
                            title: 'Checklist'),
                        const Spacer(),
                        Chip(
                          label: Text('${_checklist.length} tasks'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_checklist.isEmpty)
                      _EmptyState(
                        icon: Icons.checklist_rounded,
                        message: 'No tasks yet — add some below',
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklist.length,
                        onReorder: (o, n) {
                          setState(() {
                            if (n > o) n--;
                            _checklist.insert(n, _checklist.removeAt(o));
                          });
                          HapticFeedback.mediumImpact();
                        },
                        itemBuilder: (_, i) => _ChecklistTile(
                          key: ValueKey(_checklist[i].id),
                          item: _checklist[i],
                          onEdit: () => _editItem(i),
                          onDelete: () =>
                              setState(() => _checklist.removeAt(i)),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_task_rounded),
                      label: const Text('Add task'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Timeline & priority ───────────────────────────────
              TaskFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TaskSectionHeader(
                        icon: Icons.schedule_rounded,
                        title: 'Timeline & priority'),
                    const SizedBox(height: 14),
                    TaskDateTile(
                      label: 'Due date',
                      date: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365 * 10)),
                      clearable: true,
                      onPicked: (d) => setState(
                              () => _dueDate = d.year == 0 ? null : d),
                    ),
                    const Divider(height: 20),
                    TaskPrioritySelector(
                      value: _priority,
                      onChanged: (v) => setState(() => _priority = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Media ─────────────────────────────────────────────
              TaskFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TaskSectionHeader(
                            icon: Icons.image_rounded,
                            title: 'Media'),
                        const Spacer(),
                        Chip(
                          label: Text('${_mediaUrls.length}/10'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_mediaUrls.isEmpty)
                      _EmptyState(
                          icon: Icons.add_photo_alternate_rounded,
                          message: 'No media added yet')
                    else
                      EnhancedMediaDisplay(
                        mediaFiles: _mediaUrls
                            .map((u) => EnhancedMediaFile(
                          id: u.hashCode.toString(),
                          fileName: u.split('/').last,
                          url: u,
                          type: _fileType(u),
                          isLocal: !u.startsWith('http'),
                        ))
                            .toList(),
                        config: const MediaDisplayConfig(
                          layoutMode: MediaLayoutMode.grid,
                          gridColumns: 3,
                          mediaBucket: MediaBucket.bucketMedia,
                          borderRadius: 12,
                          allowDelete: true,
                        ),
                        onDelete: (id) => setState(() => _mediaUrls
                            .removeWhere(
                                (u) => u.hashCode.toString() == id)),
                      ),
                    const SizedBox(height: 12),
                    if (_mediaUrls.length < 10)
                      OutlinedButton.icon(
                        onPressed: _pickMedia,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text('Add photos / videos'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Actions ───────────────────────────────────────────
              TaskPrimaryButton(
                label: widget.bucketId == null
                    ? 'Create bucket'
                    : 'Save changes',
                icon: widget.bucketId == null
                    ? Icons.rocket_launch_rounded
                    : Icons.save_rounded,
                loading: _saving,
                onTap: _save,
              ),
              if (widget.bucketId != null) ...[
                const SizedBox(height: 12),
                TaskDestructiveButton(
                    label: 'Delete bucket', onTap: _confirmDelete),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  MediaFileType _fileType(String url) {
    final ext = url.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext))
      return MediaFileType.image;
    if (['mp4', 'mov', 'avi'].contains(ext)) return MediaFileType.video;
    return MediaFileType.document;
  }

  Future<void> _pickCustomCategory() async {
    final result = await showDialog<Category>(
      context: context,
      builder: (_) =>
          CreateCategoryDialog(categoryFor: CategoryForType.bucket),
    );
    if (result != null) {
      setState(() => _category = CategoryPickerResult(
        category: result,
        subType: result.subTypes.isNotEmpty ? result.subTypes.first : null,
      ));
    }
  }

  void _addItem() => showDialog(
    context: context,
    builder: (_) => _ChecklistDialog(
      onSave: (t) => setState(() => _checklist.add(
        ChecklistItem(id: _uuid.v4(), task: t, done: false, points: 10),
      )),
    ),
  );

  void _editItem(int i) => showDialog(
    context: context,
    builder: (_) => _ChecklistDialog(
      initialTask: _checklist[i].task,
      onSave: (t) =>
          setState(() => _checklist[i] = _checklist[i].copyWith(task: t)),
    ),
  );

  Future<void> _pickMedia() async {
    try {
      final file = await EnhancedMediaPicker.pickMedia(context,
          config: const MediaPickerConfig(
              allowCamera: true,
              allowGallery: true,
              allowImage: true,
              allowVideo: true,
              autoCompress: true));
      if (file != null) setState(() => _mediaUrls.add(file.path));
    } catch (e) {
      AppSnackbar.error('Failed to pick media');
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      AppSnackbar.warning('Please select a category');
      return;
    }

    setState(() => _saving = true);
    try {
      final provider = context.read<BucketProvider>();
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // Upload any local files
      final localFiles = _mediaUrls
          .where((u) => !u.startsWith('http'))
          .map(File.new)
          .toList();
      if (localFiles.isNotEmpty) {
        final uploaded =
        await UniversalMediaService().uploadBucketMedia(localFiles);
        int idx = 0;
        for (int i = 0; i < _mediaUrls.length; i++) {
          if (!_mediaUrls[i].startsWith('http') && idx < uploaded.length) {
            _mediaUrls[i] = uploaded[idx++];
          }
        }
      }

      final bucket = BucketModel(
        id: widget.bucketId ?? _uuid.v4(),
        userId: userId,
        categoryId: _category!.categoryId,
        categoryType: _category!.categoryType,
        subTypes: _category!.subType,
        title: _titleController.text.trim(),
        details: BucketDetails(
          description: _descController.text.trim(),
          motivation: _motivationController.text.trim(),
          outCome: _outcomeController.text.trim(),
          mediaUrl: _mediaUrls,
        ),
        checklist: _checklist,
        timeline: BucketTimeline(
          isUnspecified: _dueDate == null,
          addedDate: _original?.timeline.addedDate ?? DateTime.now(),
          startDate: _original?.timeline.startDate,
          dueDate: _dueDate,
          completeDate: _original?.timeline.completeDate,
        ),
        metadata:
        (_original?.metadata ?? BucketMetadata()).copyWith(priority: _priority),
        socialInfo: _original?.socialInfo,
        shareInfo: _original?.shareInfo,
        createdAt: _original?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool ok;
      if (widget.bucketId == null) {
        ok = (await provider.createBucket(bucket)) != null;
      } else {
        ok = await provider.updateBucket(bucket);
      }

      if (ok && mounted) {
        AppSnackbar.success(
            widget.bucketId == null ? 'Bucket created!' : 'Bucket updated!');
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      logE('Save bucket error', error: e);
      AppSnackbar.error('Failed to save bucket');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmDelete() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete bucket?'),
      content: const Text(
          'This will permanently delete all data including tasks and progress.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(context);
            final ok = await context
                .read<BucketProvider>()
                .deleteBucket(widget.bucketId!);
            if (ok && mounted) {
              AppSnackbar.success('Bucket deleted');
              Navigator.pop(context, true);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ─── Private sub-widgets (file-local) ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ChecklistTile(
      {super.key,
        required this.item,
        required this.onEdit,
        required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.drag_indicator_rounded),
      title: Text(item.task),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18), onPressed: onEdit),
        IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: Colors.red),
            onPressed: onDelete),
      ]),
    );
  }
}

class _ChecklistDialog extends StatefulWidget {
  final String? initialTask;
  final ValueChanged<String> onSave;
  const _ChecklistDialog({this.initialTask, required this.onSave});

  @override
  State<_ChecklistDialog> createState() => _ChecklistDialogState();
}

class _ChecklistDialogState extends State<_ChecklistDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTask);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? 'Add task' : 'Edit task'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 3,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
            hintText: 'Describe the task', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final t = _ctrl.text.trim();
            if (t.isNotEmpty) {
              widget.onSave(t);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}