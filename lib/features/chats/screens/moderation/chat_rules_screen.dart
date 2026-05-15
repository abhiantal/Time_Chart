import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/error_handler.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../repositories/chat_repository.dart';

class ChatRulesScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final bool isCommunity;

  const ChatRulesScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isCommunity = false,
  });

  @override
  State<ChatRulesScreen> createState() => _ChatRulesScreenState();
}

class _ChatRulesScreenState extends State<ChatRulesScreen> {
  late List<String> _rules = [];
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isAdmin = false;
  final List<TextEditingController> _ruleControllers = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    for (final controller in _ruleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final repo = context.read<ChatRepository>();
      final rules = await repo.getChatRules(widget.chatId);
      final isAdmin = await repo.isCurrentUserAdmin(widget.chatId);
      if (mounted) {
        setState(() {
          _rules = rules;
          _isAdmin = isAdmin;
        });
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ChatRulesScreen.loadInitial');
    }
  }

  void _toggleEdit() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _ruleControllers.clear();
        for (final rule in _rules) {
          _ruleControllers.add(TextEditingController(text: rule));
        }
        if (_ruleControllers.isEmpty) {
          _ruleControllers.add(TextEditingController());
        }
      }
    });
  }

  void _addRule() {
    setState(() {
      _ruleControllers.add(TextEditingController());
    });
  }

  void _removeRule(int index) {
    setState(() {
      _ruleControllers[index].dispose();
      _ruleControllers.removeAt(index);
    });
  }

  Future<void> _saveRules() async {
    final newRules = _ruleControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);
    try {
      final repo = context.read<ChatRepository>();
      await repo.setChatRules(widget.chatId, newRules);
      if (mounted) {
        setState(() {
          _rules = newRules;
          _isEditing = false;
          _isSaving = false;
        });
        HapticFeedback.lightImpact();
        AppSnackbar.success('Rules updated');
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, st, 'ChatRulesScreen.saveRules');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurfaceVariant),
          ),
          title: Text(
            '${widget.chatName} Rules',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_isAdmin)
              IconButton(
                onPressed: _isEditing ? _saveRules : _toggleEdit,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, color: colorScheme.primary),
              ),
          ],
        ),
        body: _isEditing ? _buildEditMode(colorScheme) : _buildViewMode(theme, colorScheme),
      ),
    );
  }

  Widget _buildViewMode(ThemeData theme, ColorScheme colorScheme) {
    if (_rules.isEmpty && !_isEditing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_rounded, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No rules yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (_isAdmin) ...[
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: _toggleEdit, icon: const Icon(Icons.add_rounded), label: const Text('Add Rules')),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _rules.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
            child: Center(child: Text('${index + 1}', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12))),
          ),
          title: Text(_rules[index], style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        );
      },
    );
  }

  Widget _buildEditMode(ColorScheme colorScheme) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _ruleControllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
                      child: Center(child: Text('${index + 1}', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _ruleControllers[index],
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Enter a rule...',
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    if (_ruleControllers.length > 1)
                      IconButton(onPressed: () => _removeRule(index), icon: Icon(Icons.close_rounded, color: colorScheme.error)),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: OutlinedButton.icon(
            onPressed: _addRule,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Rule'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    );
  }
}

class ChatRulesSummary extends StatelessWidget {
  final List<String> rules;
  final VoidCallback? onTap;
  final int maxPreview;

  const ChatRulesSummary({
    super.key,
    required this.rules,
    this.onTap,
    this.maxPreview = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
        child: Icon(Icons.gavel_rounded, color: colorScheme.onPrimaryContainer, size: 20),
      ),
      title: const Text('Rules & Guidelines'),
      subtitle: rules.isEmpty
          ? const Text('No rules added yet')
          : Text('${rules.length} rules defined', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
