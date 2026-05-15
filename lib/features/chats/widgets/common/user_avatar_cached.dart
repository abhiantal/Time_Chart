import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../media_utility/universal_media_service.dart';

// ================================================================
// USER AVATAR - CORE WIDGET
// ================================================================

class UserAvatar extends StatefulWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool isGroup;
  final bool isCommunity;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.isGroup = false,
    this.isCommunity = false,
    this.onTap,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveUrl();
    }
  }

  Future<void> _resolveUrl() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      if (mounted) setState(() => _resolvedUrl = null);
      return;
    }

    try {
      final validUrl = await UniversalMediaService().getValidAvatarUrl(
        widget.imageUrl,
      );
      if (mounted) {
        setState(() {
          _resolvedUrl = validUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolvedUrl = widget.imageUrl; // Fallback
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color:
              Colors.primaries[(widget.name?.hashCode.abs() ?? 0) %
                  Colors.primaries.length],
          shape: BoxShape.circle,
        ),
        child: _resolvedUrl != null
            ? ClipOval(child: _buildImage())
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildImage() {
    if (_resolvedUrl == null || _resolvedUrl!.isEmpty)
      return _buildPlaceholder();

    if (_resolvedUrl!.startsWith('http') || _resolvedUrl!.startsWith('https')) {
      return CachedNetworkImage(
        imageUrl: _resolvedUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 200),
        memCacheHeight: (widget.size * 3).toInt(),
      );
    } else {
      final file = File(_resolvedUrl!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials() {
    if (widget.name == null || widget.name!.isEmpty) return '?';
    final name = widget.name!.trim();
    if (name.isEmpty) return '?';

    final words = name.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}

// ================================================================
// USER AVATAR CACHED - ENHANCED WRAPPER
// ================================================================

class UserAvatarCached extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isGroup;
  final bool isCommunity;
  final bool isOnline;
  final bool isTyping;
  final bool showOnlineStatus;
  final bool showStoryRing;
  final bool hasUnseenStory;
  final bool isUploadingStory;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? heroTag;
  final double borderRadius;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatarCached({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 40,
    this.isGroup = false,
    this.isCommunity = false,
    this.isOnline = false,
    this.isTyping = false,
    this.showOnlineStatus = false,
    this.showStoryRing = false,
    this.hasUnseenStory = false,
    this.isUploadingStory = false,
    this.onTap,
    this.onLongPress,
    this.heroTag,
    this.borderRadius = 0,
    this.showBorder = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determined border radius is not needed for circles

    Widget avatar = UserAvatar(
      imageUrl: imageUrl,
      name: name,
      size: size,
      isGroup: isGroup,
      isCommunity: isCommunity,
      onTap: onTap,
    );

    // Border
    if (showBorder) {
      avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: borderColor ?? colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: avatar,
      );
    }

    // Story ring
    if (showStoryRing) {
      avatar = Container(
        padding: EdgeInsets.all(hasUnseenStory ? 3 : 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasUnseenStory
              ? SweepGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                    colorScheme.tertiary,
                    colorScheme.primary,
                  ],
                )
              : null,
          color: hasUnseenStory ? null : Colors.grey.shade300,
        ),
        child: avatar,
      );
    }

    // Hero
    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    // Online/Typing status
    if (showOnlineStatus && (isOnline || isTyping)) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: isTyping ? colorScheme.primary : const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: size * 0.04,
                ),
              ),
              child: isTyping
                  ? Center(
                      child: SizedBox(
                        width: size * 0.1,
                        height: size * 0.1,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}
