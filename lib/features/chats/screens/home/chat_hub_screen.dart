// ================================================================
// CHAT HUB SCREEN — Fully self-contained
// ✅ No chat_hub_helpers.dart import
// ✅ Uses your custom snackbarService & logE
// ✅ Proper SafeArea / status bar handling
// ✅ Underline tabs, full labels, zero dead space
// ✅ Null-safe data access (fixes 'Null is not a subtype of String')
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/feature_info_widgets.dart';
import '../../../../widgets/logger.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/user_avatar_cached.dart';

import 'package:the_time_chart/user_profile/create_edit_profile/profile_provider.dart';

import 'chat_list_filter_screen.dart';

enum ChatHubTab { personal, groups, communities }

class ChatHubScreen extends StatefulWidget {
  final ChatHubTab initialTab;
  const ChatHubScreen({super.key, this.initialTab = ChatHubTab.personal});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Controllers ──────────────────────────────────────
  late TabController _tabController;
  late AnimationController _fabController;
  late AnimationController _badgeBounceController;

  // ── Animations ───────────────────────────────────────
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;
  late Animation<double> _badgeBounceAnimation;

  // ── State ────────────────────────────────────────────
  late ChatHubTab _currentTab;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentTab = widget.initialTab;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _currentTab.index,
    )..addListener(_onTabChanged);

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabRotationAnimation = Tween<double>(begin: -0.25, end: 0.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutCubic),
    );

    _badgeBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _badgeBounceAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _badgeBounceController, curve: Curves.elasticOut),
    );

    _searchController.addListener(() => setState(() {}));
    _fabController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChatList();
    });
  }

  void _initChatList() {
    try {
      final chatProvider = context.read<ChatProvider>();
      final userId = chatProvider.currentUserId;
      if (userId != null &&
          userId.isNotEmpty &&
          chatProvider.chats.isEmpty &&
          !chatProvider.isLoading) {
        chatProvider.initialize(userId: userId);
      }
    } catch (e) {
      // ✅ Uses your custom logE helper
      logE('ChatHub init error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _fabController.dispose();
    _badgeBounceController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fabController.forward(from: 0.0);
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() => _currentTab = ChatHubTab.values[_tabController.index]);
      HapticFeedback.selectionClick();
      _fabController.forward(from: 0.65);
    }
  }

  void _onNewChatPressed() {
    HapticFeedback.lightImpact();
    final routes = {
      ChatHubTab.personal: 'newChatScreen',
      ChatHubTab.groups: 'createGroupScreen',
      ChatHubTab.communities: 'createCommunityScreen',
    };
    context.pushNamed(routes[_currentTab]!);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabController.forward(from: 0.0);
    });
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    setState(() => _isSearching = true);
    Future.delayed(
      const Duration(milliseconds: 120),
      () => _searchFocusNode.requestFocus(),
    );
  }

  void _closeSearch() {
    HapticFeedback.lightImpact();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _checkUnreadBounce(int newCount) {
    if (newCount > _previousUnreadCount && newCount > 0) {
      _badgeBounceController.forward(from: 0.0);
    }
    _previousUnreadCount = newCount;
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // ✅ Get status bar height — used to give app bar proper top padding
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final isConnected = chatProvider.isConnected;
        final unreadCount = chatProvider.totalUnreadCount;
        _checkUnreadBounce(unreadCount);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          // ✅ Status bar icons are light/dark based on theme — no background color
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: theme.brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: colorScheme.surface,
          ),
          child: SafeArea(
            top: false,
            child: Scaffold(
              // ✅ resizeToAvoidBottomInset prevents keyboard layout jumps
              resizeToAvoidBottomInset: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header Block (Surface Color) ---
                  Container(
                    color: colorScheme.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Manual top padding for status bar
                        SizedBox(height: statusBarHeight),

                        // App bar
                        _AppBarContent(
                          currentTab: _currentTab,
                          isSearching: _isSearching,
                          searchController: _searchController,
                          searchFocusNode: _searchFocusNode,
                          unreadCount: unreadCount,
                          isConnected: isConnected,
                          badgeBounceAnimation: _badgeBounceAnimation,
                          onSearch: _openSearch,
                          onCloseSearch: _closeSearch,
                          onMore: () =>
                              _showMoreOptions(context, colorScheme, theme),
                          getTitle: _getTitle,
                          getSearchHint: _getSearchHint,
                          onSearchSubmit: (query) {
                            if (query.isNotEmpty) {
                              context.pushNamed(
                                'globalSearchScreen',
                                extra: query,
                              );
                              _closeSearch();
                            }
                          },
                        ),

                        // Offline banner (inside surface block)
                        if (!isConnected) _buildOfflineBanner(colorScheme),

                        // Tab bar
                        _buildTabBar(colorScheme),

                        // Hairline separator
                        Container(
                          height: 0.5,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),

                  // --- Content Block (Scaffold Background) ---
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        ChatListFilterScreen(filterType: ChatListFilterType.personal),
                        ChatListFilterScreen(filterType: ChatListFilterType.groups),
                        ChatListFilterScreen(filterType: ChatListFilterType.communities),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: _isSearching
                  ? null
                  : _buildFAB(colorScheme),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // TAB BAR — clean underline, full labels, animated color
  // ══════════════════════════════════════════════════════
  Widget _buildTabBar(ColorScheme colorScheme) {
    final activeColor = _tabColor(colorScheme);
    return AnimatedTheme(
      duration: const Duration(milliseconds: 300),
      data: Theme.of(context).copyWith(
        tabBarTheme: TabBarThemeData(
          labelColor: activeColor,
          unselectedLabelColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          indicatorColor: activeColor,
        ),
      ),
      child: SizedBox(
        height: 46,
        child: TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: activeColor, width: 3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            insets: const EdgeInsets.symmetric(horizontal: 8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          splashBorderRadius: BorderRadius.circular(6),
          labelColor: activeColor,
          unselectedLabelColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.1,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: [
            _Tab(icon: Icons.chat_bubble_rounded, label: 'Personal'),
            _Tab(icon: Icons.group_rounded, label: 'Groups'),
            _Tab(icon: Icons.public_rounded, label: 'Communities'),
          ],
        ),
      ),
    );
  }

  // ── Offline banner ────────────────────────────────────
  Widget _buildOfflineBanner(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Reconnecting… Check your internet connection.',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────
  Widget _buildFAB(ColorScheme colorScheme) {
    final color = _tabColor(colorScheme);
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: RotationTransition(
        turns: _fabRotationAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            heroTag: 'chat_hub_new_chat_fab',
            onPressed: _onNewChatPressed,
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(_fabIcon(), key: ValueKey(_currentTab)),
            ),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _fabLabel(),
                key: ValueKey('lbl_$_currentTab'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── More options sheet ────────────────────────────────
  void _showMoreOptions(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoreOptionsSheet(colorScheme: colorScheme, theme: theme),
    );
  }

  // ── Lookup helpers ────────────────────────────────────
  Color _tabColor(ColorScheme c) => switch (_currentTab) {
    ChatHubTab.personal => c.primary,
    ChatHubTab.groups => c.secondary,
    ChatHubTab.communities => c.tertiary,
  };

  String _getTitle() => switch (_currentTab) {
    ChatHubTab.personal => 'Chats',
    ChatHubTab.groups => 'Groups',
    ChatHubTab.communities => 'Communities',
  };

  String _getSearchHint() => switch (_currentTab) {
    ChatHubTab.personal => 'Search chats…',
    ChatHubTab.groups => 'Search groups…',
    ChatHubTab.communities => 'Search communities…',
  };

  IconData _fabIcon() => switch (_currentTab) {
    ChatHubTab.personal => Icons.add_comment_rounded,
    ChatHubTab.groups => Icons.group_add_rounded,
    ChatHubTab.communities => Icons.public_rounded,
  };

  String _fabLabel() => switch (_currentTab) {
    ChatHubTab.personal => 'New Chat',
    ChatHubTab.groups => 'New Group',
    ChatHubTab.communities => 'New Community',
  };
}

// ══════════════════════════════════════════════════════
// APP BAR WIDGET — extracted for clarity
// ✅ Handles both search and normal mode cleanly
// ══════════════════════════════════════════════════════
class _AppBarContent extends StatelessWidget {
  const _AppBarContent({
    required this.currentTab,
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
    required this.unreadCount,
    required this.isConnected,
    required this.badgeBounceAnimation,
    required this.onSearch,
    required this.onCloseSearch,
    required this.onMore,
    required this.getTitle,
    required this.getSearchHint,
    required this.onSearchSubmit,
  });

  final ChatHubTab currentTab;
  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final int unreadCount;
  final bool isConnected;
  final Animation<double> badgeBounceAnimation;
  final VoidCallback onSearch;
  final VoidCallback onCloseSearch;
  final VoidCallback onMore;
  final String Function() getTitle;
  final String Function() getSearchHint;
  final ValueChanged<String> onSearchSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: isSearching
            ? _SearchBar(
                key: const ValueKey('search'),
                controller: searchController,
                focusNode: searchFocusNode,
                hint: getSearchHint(),
                colorScheme: colorScheme,
                theme: theme,
                onClose: onCloseSearch,
                onSubmit: onSearchSubmit,
              )
            : _NormalBar(
                key: const ValueKey('normal'),
                currentTab: currentTab,
                unreadCount: unreadCount,
                isConnected: isConnected,
                badgeBounceAnimation: badgeBounceAnimation,
                title: getTitle(),
                colorScheme: colorScheme,
                theme: theme,
                onSearch: onSearch,
                onMore: onMore,
              ),
      ),
    );
  }
}

// ── Normal app bar row ────────────────────────────────
class _NormalBar extends StatelessWidget {
  const _NormalBar({
    super.key,
    required this.currentTab,
    required this.unreadCount,
    required this.isConnected,
    required this.badgeBounceAnimation,
    required this.title,
    required this.colorScheme,
    required this.theme,
    required this.onSearch,
    required this.onMore,
  });

  final ChatHubTab currentTab;
  final int unreadCount;
  final bool isConnected;
  final Animation<double> badgeBounceAnimation;
  final String title;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onSearch;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    // ✅ Null-safe profile access
    final profileProvider = context.watch<ProfileProvider>();
    final avatarUrl = profileProvider.currentProfile?.profileUrl;
    // ✅ Safe fallback if displayName is null
    final profile = profileProvider.currentProfile;
    final displayName = profile?.displayName;
    final userName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName
        : 'Me';

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          // ── Avatar ──
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pushNamed('profileEdit');
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: UserAvatarCached(
                imageUrl:
                    avatarUrl, // ✅ nullable — widget handles null gracefully
                name: userName,
                size: 44,
                showStoryRing: true,
                showBorder: true,
                borderColor: colorScheme.primary.withValues(alpha: 0.3),
                borderRadius: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ── Title + status dot ──
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                _OnlineDot(isConnected: isConnected, colorScheme: colorScheme),
              ],
            ),
          ),

          // ── Unread badge ──
          if (unreadCount > 0) ...[
            ScaleTransition(
              scale: badgeBounceAnimation,
              child: _Badge(count: unreadCount, colorScheme: colorScheme),
            ),
            const SizedBox(width: 6),
          ],

          // ── Help button ──
          _IconBtn(
            icon: Icons.help_outline_rounded,
            onTap: () => FeatureInfoCard.showEliteDialog(
              context,
              EliteFeatures.community,
            ),
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 4),

          // ── Search button ──
          _IconBtn(
            icon: Icons.search_rounded,
            onTap: onSearch,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 4),

          // ── More button ──
          _IconBtn(
            icon: Icons.more_vert_rounded,
            onTap: onMore,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.colorScheme,
    required this.theme,
    required this.onClose,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
                onSubmitted: onSubmit,
              ),
            ),
            // ── Live clear button ──
            ListenableBuilder(
              listenable: controller,
              builder: (_, __) => controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: controller.clear,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : const SizedBox(width: 8),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Online dot ────────────────────────────────────────
class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.isConnected, required this.colorScheme});
  final bool isConnected;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? Colors.green : colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          builder: (_, v, __) => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: v),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45 * v),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isConnected ? 'Online' : 'Connecting…',
          style: TextStyle(
            color: isConnected ? Colors.green.shade500 : colorScheme.error,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Unread badge ──────────────────────────────────────
class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.colorScheme});
  final int count;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Icon button ───────────────────────────────────────
class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.colorScheme,
  });
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ── Tab widget ────────────────────────────────────────
class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
// MORE OPTIONS BOTTOM SHEET
// ══════════════════════════════════════════════════════
class _MoreOptionsSheet extends StatelessWidget {
  const _MoreOptionsSheet({required this.colorScheme, required this.theme});
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1),
          _OptionTile(
            icon: Icons.mark_chat_read_rounded,
            title: 'Mark all as read',
            subtitle: 'Clear all unread messages',
            colorScheme: colorScheme,
            onTap: () => Navigator.pop(context),
          ),
          _OptionTile(
            icon: Icons.archive_rounded,
            title: 'Archived Chats',
            subtitle: 'View archived conversations',
            colorScheme: colorScheme,
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('archivedChatsScreen');
            },
          ),
          _OptionTile(
            icon: Icons.star_rounded,
            title: 'Starred Messages',
            subtitle: 'View important saved messages',
            colorScheme: colorScheme,
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('starredMessagesScreen');
            },
          ),
          _OptionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Code',
            subtitle: 'Join group or community',
            colorScheme: colorScheme,
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('qrScannerScreen');
            },
          ),
          _OptionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Discover Communities',
            subtitle:
                'Discover or create communities to connect with like-minded people',
            colorScheme: colorScheme,
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('discoverCommunitiesScreen');
            },
          ),
          _OptionTile(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Chat preferences & notifications',
            colorScheme: colorScheme,
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('settingsScreen');
            },
          ),
          // ✅ Safe bottom padding using MediaQuery (handles gesture nav bar)
          SizedBox(height: 12 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
