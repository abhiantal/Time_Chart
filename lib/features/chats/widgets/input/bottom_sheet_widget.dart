// ================================================================
// 📁 BOTTOM SHEET WIDGET
// Handles: Action sheets, selection sheets, modal sheets,
// attachment picker, more options menu
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ================================================================
// ACTION TYPES
// ================================================================

enum ChatAttachmentType {
  camera,
  cameraVideo,
  gallery,
  document,
  audio,
  task,
  poll,
}
// ================================================================
// ATTACHMENT PICKER SHEET
// ================================================================

class AttachmentPickerSheet extends StatelessWidget {
  const AttachmentPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final attachments = [
      _AttachmentOption(
        type: ChatAttachmentType.camera,
        icon: Icons.camera_alt_rounded,
        label: 'Camera',
        color: const Color(0xFFEF4444),
      ),
      _AttachmentOption(
        type: ChatAttachmentType.cameraVideo,
        icon: Icons.videocam_rounded,
        label: 'Video',
        color: const Color(0xFFF43F5E),
      ),
      _AttachmentOption(
        type: ChatAttachmentType.gallery,
        icon: Icons.photo_library_rounded,
        label: 'Gallery',
        color: const Color(0xFF8B5CF6),
      ),
      _AttachmentOption(
        type: ChatAttachmentType.document,
        icon: Icons.insert_drive_file_rounded,
        label: 'Document',
        color: const Color(0xFF3B82F6),
      ),
      _AttachmentOption(
        type: ChatAttachmentType.audio,
        icon: Icons.headphones_rounded,
        label: 'Voice Note',
        color: const Color(0xFFF97316),
      ),
      _AttachmentOption(
        type: ChatAttachmentType.task,
        icon: Icons.task_alt_rounded,
        label: 'Task',
        color: const Color(0xFF10B981),
      ),
      _AttachmentOption(
        type: ChatAttachmentType.poll,
        icon: Icons.poll_rounded,
        label: 'Poll',
        color: const Color(0xFFF59E0B),
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Share content',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: attachments.length,
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  return _AttachmentButton(
                    attachment: attachment,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, attachment.type);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentOption {
  final ChatAttachmentType type;
  final IconData icon;
  final String label;
  final Color color;

  const _AttachmentOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.color,
  });
}

class _AttachmentButton extends StatelessWidget {
  final _AttachmentOption attachment;
  final VoidCallback onTap;

  const _AttachmentButton({required this.attachment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [attachment.color, attachment.color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: attachment.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(attachment.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            attachment.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
