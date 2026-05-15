import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RulesEditorScreen extends StatefulWidget {
  final List<String> initialRules;
  final String title;

  const RulesEditorScreen({
    super.key,
    this.initialRules = const [],
    this.title = 'Rules & Guidelines',
  });

  @override
  State<RulesEditorScreen> createState() => _RulesEditorScreenState();
}

class _RulesEditorScreenState extends State<RulesEditorScreen> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialRules.isEmpty) {
      _controllers.add(TextEditingController());
    } else {
      for (final rule in widget.initialRules) {
        _controllers.add(TextEditingController(text: rule));
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addRule() {
    HapticFeedback.lightImpact();
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeRule(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      if (_controllers.isEmpty) {
        _controllers.add(TextEditingController());
      }
    });
  }

  void _handleSave() {
    final rules = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    Navigator.pop(context, rules);
  }

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
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controllers.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _controllers.removeAt(oldIndex);
                  _controllers.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return _buildRuleItem(index, colorScheme, theme);
              },
            ),
          ),
          _buildAddButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildRuleItem(int index, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      key: ValueKey(_controllers[index]),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(Icons.drag_indicator_rounded, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controllers[index],
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Enter a community rule...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          IconButton(
            onPressed: () => _removeRule(index),
            icon: Icon(Icons.remove_circle_outline_rounded, color: colorScheme.error, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: _addRule,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Rule'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
