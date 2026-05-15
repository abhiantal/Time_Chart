// lib/features/settings/widgets/settings_widgets.dart

import 'package:flutter/material.dart';

// ============================================================
// SETTINGS SECTION HEADER
// ============================================================

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS CARD (Container for settings items)
// ============================================================

class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Color? color;
  final double borderRadius;

  const SettingsCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.padding = EdgeInsets.zero,
    this.color,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: Column(children: _buildDividedChildren(context)),
        ),
      ),
    );
  }

  List<Widget> _buildDividedChildren(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> dividedChildren = [];

    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 56,
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          ),
        );
      }
    }

    return dividedChildren;
  }
}

// ============================================================
// SETTINGS TILE (Basic clickable tile)
// ============================================================

class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showChevron;
  final bool isDestructive;
  final EdgeInsets contentPadding;

  const SettingsTile({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.showChevron = true,
    this.isDestructive = false,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveIconColor = isDestructive
        ? colorScheme.error
        : (iconColor ?? colorScheme.primary);

    final effectiveTitleColor = isDestructive
        ? colorScheme.error
        : (enabled
              ? colorScheme.onSurface
              : colorScheme.onSurface.withOpacity(0.5));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: contentPadding,
          child: Row(
            children: [
              if (icon != null) ...[
                _buildIconContainer(colorScheme, effectiveIconColor),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: effectiveTitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else if (showChevron && onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(ColorScheme colorScheme, Color iconColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconBackgroundColor ?? iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}

// ============================================================
// SETTINGS SWITCH TILE
// ============================================================

class SettingsSwitchTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final bool isLoading;

  const SettingsSwitchTile({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      enabled: enabled && !isLoading,
      showChevron: false,
      onTap: enabled && !isLoading ? () => onChanged?.call(!value) : null,
      trailing: isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          : Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: colorScheme.primary,
            ),
    );
  }
}

// ============================================================
// SETTINGS RADIO TILE
// ============================================================

class SettingsRadioTile<T> extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  const SettingsRadioTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      showChevron: false,
      onTap: enabled ? () => onChanged?.call(value) : null,
      trailing: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: enabled ? onChanged : null,
        activeColor: colorScheme.primary,
      ),
    );
  }
}

// ============================================================
// SETTINGS DROPDOWN TILE
// ============================================================

class SettingsDropdownTile<T> extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  const SettingsDropdownTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: enabled ? onChanged : null,
              underline: const SizedBox(),
              isDense: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS SLIDER TILE
// ============================================================

class SettingsSliderTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? valueLabel;
  final ValueChanged<double>? onChanged;
  final bool enabled;

  const SettingsSliderTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.valueLabel,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (valueLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    valueLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: enabled ? onChanged : null,
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS COLOR PICKER TILE
// ============================================================

class SettingsColorTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Color value;
  final List<Color> colors;
  final ValueChanged<Color>? onChanged;
  final bool enabled;

  const SettingsColorTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.colors,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              final isSelected = color.value == value.value;
              return GestureDetector(
                onTap: enabled ? () => onChanged?.call(color) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color:
                              ThemeData.estimateBrightnessForColor(color) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS TIME PICKER TILE
// ============================================================

class SettingsTimeTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay>? onChanged;
  final bool enabled;

  const SettingsTimeTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      showChevron: false,
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: value,
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                timePickerTheme: TimePickerThemeData(
                  backgroundColor: colorScheme.surface,
                  hourMinuteShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  dayPeriodShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (newTime != null) {
          onChanged?.call(newTime);
        }
      },
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _formatTime(value),
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS CHOICE CHIP GROUP
// ============================================================

class SettingsChoiceChips<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T value;
  final List<SettingsChoice<T>> choices;
  final ValueChanged<T>? onChanged;
  final bool enabled;
  final bool wrap;

  const SettingsChoiceChips({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.choices,
    this.onChanged,
    this.enabled = true,
    this.wrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (wrap)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: choices
                  .map((choice) => _buildChip(context, choice))
                  .toList(),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: choices
                    .map(
                      (choice) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildChip(context, choice),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, SettingsChoice<T> choice) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = choice.value == value;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (choice.icon != null) ...[
            Icon(
              choice.icon,
              size: 18,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
          ],
          Text(choice.label),
        ],
      ),
      selected: isSelected,
      onSelected: enabled ? (_) => onChanged?.call(choice.value) : null,
      selectedColor: colorScheme.primary,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
    );
  }
}

class SettingsChoice<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SettingsChoice({required this.value, required this.label, this.icon});
}

// ============================================================
// SETTINGS INFO BANNER
// ============================================================

class SettingsInfoBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Color? color;
  final VoidCallback? onAction;
  final String? actionLabel;

  const SettingsInfoBanner({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.color,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bannerColor = color ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: bannerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: bannerColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS BUTTON
// ============================================================

class SettingsButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isPrimary;
  final bool isLoading;
  final bool enabled;

  const SettingsButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color foregroundColor;

    if (isDestructive) {
      backgroundColor = colorScheme.error;
      foregroundColor = colorScheme.onError;
    } else if (isPrimary) {
      backgroundColor = colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      foregroundColor = colorScheme.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: backgroundColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS SEGMENTED CONTROL
// ============================================================

class SettingsSegmentedControl<T> extends StatelessWidget {
  final String? title;
  final T value;
  final Map<T, String> segments;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  const SettingsSegmentedControl({
    super.key,
    this.title,
    required this.value,
    required this.segments,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: segments.entries.map((entry) {
                final isSelected = entry.key == value;
                return Expanded(
                  child: GestureDetector(
                    onTap: enabled ? () => onChanged?.call(entry.key) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
