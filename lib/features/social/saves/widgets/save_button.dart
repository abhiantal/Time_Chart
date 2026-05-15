import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:the_time_chart/widgets/app_snackbar.dart';
import '../providers/save_provider.dart';
import '../models/saves_model.dart';
import 'collection_picker.dart';

class SaveButton extends StatefulWidget {
  final String postId;
  final bool initialSaved;
  final double size;
  final bool showLabel;
  final VoidCallback? onTap;
  final Function(bool)? onSavedChanged;

  const SaveButton({
    super.key,
    required this.postId,
    this.initialSaved = false,
    this.size = 24,
    this.showLabel = false,
    this.onTap,
    this.onSavedChanged,
  });

  @override
  State<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<SaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.initialSaved;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(SaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSaved != oldWidget.initialSaved) {
      setState(() {
        _isSaved = widget.initialSaved;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;

    HapticFeedback.lightImpact();
    _animationController.forward().then((_) => _animationController.reverse());

    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<SaveProvider>();

      if (_isSaved) {
        // Unsave
        final result = await provider.toggleSave(widget.postId);
        if (result != null && result.success && result.isUnsaved) {
          setState(() {
            _isSaved = false;
            _isLoading = false;
          });
          widget.onSavedChanged?.call(false);
        }
      } else {
        // Save - show collection picker first
        _showCollectionPicker();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCollectionPicker() async {
    final selectedCollection = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CollectionPicker(postId: widget.postId),
    );

    if (selectedCollection != null && mounted) {
      final provider = context.read<SaveProvider>();
      final result = await provider.saveToCollection(
        postId: widget.postId,
        collectionName: selectedCollection,
      );

      if (result != null && result.success) {
        setState(() {
          _isSaved = true;
          _isLoading = false;
        });
        widget.onSavedChanged?.call(true);

        if (selectedCollection != kDefaultCollectionName) {
          AppSnackbar.success('Saved to $selectedCollection');
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _isSaved ? activeColor.withOpacity(0.1) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: activeColor,
                  ),
                )
              else
                Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? activeColor : inactiveColor,
                  size: widget.size,
                ),
              if (widget.showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  _isSaved ? 'Saved' : 'Save',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _isSaved ? activeColor : inactiveColor,
                    fontWeight: _isSaved ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
