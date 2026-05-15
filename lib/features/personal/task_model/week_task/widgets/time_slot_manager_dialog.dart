// lib/features/personal/post_shared/task_model/day_tasks/message_bubbles/time_slot_manager.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../../../widgets/app_snackbar.dart';
import '../../../../../../widgets/logger.dart';

// ================================================================
// TIME SLOT MODEL
// ================================================================
class TimeSlot {
  final String startTime;
  final String endTime;

  TimeSlot({required this.startTime, required this.endTime});

  Map<String, dynamic> toJson() => {'startTime': startTime, 'endTime': endTime};

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
  );

  @override
  String toString() => '$startTime - $endTime';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

// ================================================================
// TIME SLOT PREFERENCES HELPER
// ================================================================
class TimeSlotPreferences {
  static const String _key = 'time_slots';

  static Future<List<TimeSlot>> loadTimeSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSlots = prefs.getString(_key);

      if (savedSlots != null && savedSlots.isNotEmpty) {
        final List<dynamic> decodedSlots = jsonDecode(savedSlots);
        final slots = decodedSlots
            .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
            .toList();

        return _sortSlots(slots);
      }
    } catch (e) {
      logE('Error loading time slots', error: e);
    }

    return _getDefaultTimeSlots();
  }

  static List<TimeSlot> _sortSlots(List<TimeSlot> slots) {
    slots.sort((a, b) {
      try {
        final timeA = _parseTimeToMinutes(a.startTime);
        final timeB = _parseTimeToMinutes(b.startTime);
        return timeA.compareTo(timeB);
      } catch (e) {
        return 0;
      }
    });
    return slots;
  }

  static int _parseTimeToMinutes(String time) {
    try {
      final format = DateFormat("h:mm a");
      final parsed = format.parse(time.toUpperCase());
      return parsed.hour * 60 + parsed.minute;
    } catch (e) {
      return 0;
    }
  }

  static List<TimeSlot> _getDefaultTimeSlots() {
    return [
      TimeSlot(startTime: '5:00 AM', endTime: '6:00 AM'),
      TimeSlot(startTime: '7:00 AM', endTime: '9:00 AM'),
    ];
  }

  static Future<bool> saveTimeSlots(List<TimeSlot> slots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortedSlots = _sortSlots(List.from(slots));
      final slotsJson = jsonEncode(
        sortedSlots.map((slot) => slot.toJson()).toList(),
      );
      return await prefs.setString(_key, slotsJson);
    } catch (e) {
      logE('Error saving time slots', error: e);
      return false;
    }
  }

  static Future<bool> clearTimeSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e) {
      logE('Error clearing time slots', error: e);
      return false;
    }
  }

  static Future<bool> hasTimeSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_key);
    } catch (e) {
      return false;
    }
  }
}

// ================================================================
// TIME SLOT VALIDATION HELPER
// ================================================================
class TimeSlotValidator {
  /// Parse time string to minutes from midnight
  static int parseTimeToMinutes(String time) {
    try {
      final cleanTime = time.trim().toUpperCase();

      // Try multiple formats to handle different time string formats
      final formats = [
        DateFormat("h:mm a"),
        DateFormat("hh:mm a"),
        DateFormat("H:mm"),
        DateFormat("HH:mm"),
      ];

      for (final format in formats) {
        try {
          final parsed = format.parse(cleanTime);
          return parsed.hour * 60 + parsed.minute;
        } catch (_) {
          continue;
        }
      }

      // Manual parsing as fallback
      final regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = regex.firstMatch(cleanTime);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return hour * 60 + minute;
      }

      logW('Error parsing time: $time');
      return -1;
    } catch (e) {
      logE('Error parsing time: $time', error: e);
      return -1;
    }
  }

  /// Check if a new slot overlaps with existing slots
  static bool isOverlapping(
    TimeSlot newSlot,
    List<TimeSlot> existingSlots, {
    int? ignoreIndex,
  }) {
    final newStart = parseTimeToMinutes(newSlot.startTime);
    final newEnd = parseTimeToMinutes(newSlot.endTime);

    if (newStart == -1 || newEnd == -1) return false;

    for (int i = 0; i < existingSlots.length; i++) {
      if (ignoreIndex != null && i == ignoreIndex) continue;

      final slot = existingSlots[i];
      final existingStart = parseTimeToMinutes(slot.startTime);
      final existingEnd = parseTimeToMinutes(slot.endTime);

      if (existingStart == -1 || existingEnd == -1) continue;

      // Check overlap: slots overlap if one starts before the other ends
      // and ends after the other starts
      if (newStart < existingEnd && newEnd > existingStart) {
        return true;
      }
    }

    return false;
  }

  /// Get the specific slot that overlaps with the new slot
  static TimeSlot? getOverlappingSlot(
    TimeSlot newSlot,
    List<TimeSlot> existingSlots, {
    int? ignoreIndex,
  }) {
    final newStart = parseTimeToMinutes(newSlot.startTime);
    final newEnd = parseTimeToMinutes(newSlot.endTime);

    debugPrint(
      'Checking overlap for: ${newSlot.startTime} ($newStart min) - ${newSlot.endTime} ($newEnd min)',
    );

    if (newStart == -1 || newEnd == -1) {
      logW('Invalid time format for new slot');
      return null;
    }

    for (int i = 0; i < existingSlots.length; i++) {
      if (ignoreIndex != null && i == ignoreIndex) continue;

      final slot = existingSlots[i];
      final existingStart = parseTimeToMinutes(slot.startTime);
      final existingEnd = parseTimeToMinutes(slot.endTime);

      debugPrint(
        'Comparing with slot $i: ${slot.startTime} ($existingStart min) - ${slot.endTime} ($existingEnd min)',
      );

      if (existingStart == -1 || existingEnd == -1) continue;

      if (newStart < existingEnd && newEnd > existingStart) {
        logI('Overlap found!');
        return slot;
      }
    }

    logI('No overlap found');
    return null;
  }

  /// Validate that end time is after start time
  static bool isValidTimeRange(String startTime, String endTime) {
    final start = parseTimeToMinutes(startTime);
    final end = parseTimeToMinutes(endTime);

    if (start == -1 || end == -1) return false;
    return end > start;
  }

  /// Check if time format is valid
  static bool isValidTimeFormat(String time) {
    return parseTimeToMinutes(time) != -1;
  }
}

// ================================================================
// TIME FORMAT HELPER
// ================================================================
class TimeFormatHelper {
  /// Format TimeOfDay to string like "9:00 AM" or "12:30 PM"
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Parse time string to TimeOfDay
  static TimeOfDay parseTimeString(String time) {
    try {
      final cleanTime = time.trim().toUpperCase();

      // Try parsing with intl
      final formats = [DateFormat("h:mm a"), DateFormat("hh:mm a")];

      for (final format in formats) {
        try {
          final parsed = format.parse(cleanTime);
          return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
        } catch (_) {
          continue;
        }
      }

      // Manual parsing as fallback
      final regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(cleanTime);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)!.toUpperCase();

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      logE('Error parsing time: $time', error: e);
    }

    return const TimeOfDay(hour: 9, minute: 0);
  }
}

// ================================================================
// TIME SLOT MANAGER DIALOG
// ================================================================
class TimeSlotManagerDialog extends StatefulWidget {
  final List<TimeSlot> timeSlots;
  final Function(List<TimeSlot>) onSave;

  const TimeSlotManagerDialog({
    super.key,
    required this.timeSlots,
    required this.onSave,
  });

  @override
  State<TimeSlotManagerDialog> createState() => _TimeSlotManagerDialogState();
}

class _TimeSlotManagerDialogState extends State<TimeSlotManagerDialog> {
  late List<TimeSlot> _slots;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedTimeSlots();
  }

  Future<void> _loadSavedTimeSlots() async {
    try {
      final hasSlots = await TimeSlotPreferences.hasTimeSlots();

      if (hasSlots) {
        final slots = await TimeSlotPreferences.loadTimeSlots();
        _slots = slots;
      } else {
        _slots = widget.timeSlots.isNotEmpty
            ? List.from(widget.timeSlots)
            : await TimeSlotPreferences.loadTimeSlots();
      }
    } catch (e) {
      logE('Error in _loadSavedTimeSlots', error: e);
      _slots = widget.timeSlots.isNotEmpty
          ? List.from(widget.timeSlots)
          : await TimeSlotPreferences.loadTimeSlots();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TimeSlot> _sortSlotsByStartTime(List<TimeSlot> slots) {
    List<TimeSlot> sorted = List.from(slots);
    sorted.sort((a, b) {
      final timeA = TimeSlotValidator.parseTimeToMinutes(a.startTime);
      final timeB = TimeSlotValidator.parseTimeToMinutes(b.startTime);
      return timeA.compareTo(timeB);
    });
    return sorted;
  }

  Future<void> _saveTimeSlots() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final success = await TimeSlotPreferences.saveTimeSlots(_slots);

      if (success) {
        widget.onSave(_slots);

        if (mounted) {
          Navigator.pop(context);
          snackbarService.showSuccess(
            'Time slots saved',
            description: '${_slots.length} time slots saved successfully',
          );
        }
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      logE('Error saving time slots', error: e);
      if (mounted) {
        snackbarService.showError(
          'Save failed',
          description: 'Failed to save your time slots',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addNewSlot() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => _TimeSlotAddDialog(
        existingSlots: _slots,
        onAdd: (newSlot) {
          setState(() {
            _slots = _sortSlotsByStartTime([..._slots, newSlot]);
          });
          snackbarService.showSuccess(
            'Time slot added',
            description: '${newSlot.startTime} - ${newSlot.endTime}',
          );
        },
      ),
    );
  }

  void _editSlot(int index) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => _TimeSlotEditDialog(
        slot: _slots[index],
        slotIndex: index,
        existingSlots: _slots,
        onSave: (newSlot) {
          setState(() {
            _slots[index] = newSlot;
            _slots = _sortSlotsByStartTime(_slots);
          });
          snackbarService.showSuccess(
            'Time slot updated',
            description: '${newSlot.startTime} - ${newSlot.endTime}',
          );
        },
      ),
    );
  }

  void _deleteSlot(int index) {
    HapticFeedback.lightImpact();

    if (_slots.length <= 1) {
      snackbarService.showWarning(
        'Cannot delete',
        description: 'You must have at least one time slot',
      );
      return;
    }

    final slotToDelete = _slots[index];

    showDialog(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(
        slot: slotToDelete,
        onConfirm: () {
          setState(() {
            _slots.removeAt(index);
          });
          snackbarService.showInfo(
            'Time slot deleted',
            description: '${slotToDelete.startTime} - ${slotToDelete.endTime}',
          );
        },
      ),
    );
  }

  void _resetToDefault() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.restore, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Flexible(child: Text('Reset to Default')),
          ],
        ),
        content: const Text(
          'This will reset all time slots to default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await TimeSlotPreferences.clearTimeSlots();
              final defaultSlots = await TimeSlotPreferences.loadTimeSlots();
              setState(() {
                _slots = defaultSlots;
              });
              snackbarService.showSuccess(
                'Reset complete',
                description: 'Time slots restored to default',
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading time slots...',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colorScheme),
            const SizedBox(height: 12),
            _buildSlotCountBadge(colorScheme),
            const SizedBox(height: 12),
            Flexible(child: _buildSlotsList(colorScheme)),
            const SizedBox(height: 12),
            _buildActionButtons(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Configure your schedule',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _resetToDefault,
              icon: Icon(
                Icons.restore,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              tooltip: 'Reset',
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              tooltip: 'Close',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotCountBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '${_slots.length} slot${_slots.length != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsList(ColorScheme colorScheme) {
    if (_slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No time slots yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your first time slot below',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _slots.length,
      itemBuilder: (context, index) {
        return _buildTimeSlotItem(_slots[index], index, colorScheme);
      },
    );
  }

  Widget _buildTimeSlotItem(TimeSlot slot, int index, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editSlot(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Index Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.8),
                        colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Time Display
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimeChip(
                          slot.startTime,
                          colorScheme,
                          isStart: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                        _buildTimeChip(
                          slot.endTime,
                          colorScheme,
                          isStart: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconButton(
                      icon: Icons.edit_rounded,
                      color: colorScheme.primary,
                      onTap: () => _editSlot(index),
                      tooltip: 'Edit',
                    ),
                    _buildIconButton(
                      icon: Icons.delete_outline_rounded,
                      color: colorScheme.error,
                      onTap: () => _deleteSlot(index),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(
    String time,
    ColorScheme colorScheme, {
    required bool isStart,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isStart
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: isStart ? colorScheme.primary : colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _addNewSlot,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveTimeSlots,
            icon: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: const TextStyle(fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// ADD TIME SLOT DIALOG
// ================================================================
class _TimeSlotAddDialog extends StatefulWidget {
  final List<TimeSlot> existingSlots;
  final Function(TimeSlot) onAdd;

  const _TimeSlotAddDialog({required this.existingSlots, required this.onAdd});

  @override
  State<_TimeSlotAddDialog> createState() => _TimeSlotAddDialogState();
}

class _TimeSlotAddDialogState extends State<_TimeSlotAddDialog> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _errorMessage;

  void _validateAndAdd() {
    setState(() => _errorMessage = null);

    if (_startTime == null || _endTime == null) {
      setState(() => _errorMessage = 'Please select both start and end times');
      HapticFeedback.heavyImpact();
      return;
    }

    final startTimeStr = TimeFormatHelper.formatTimeOfDay(_startTime!);
    final endTimeStr = TimeFormatHelper.formatTimeOfDay(_endTime!);

    debugPrint('Adding new slot: $startTimeStr - $endTimeStr');
    debugPrint(
      'Existing slots: ${widget.existingSlots.map((s) => '${s.startTime} - ${s.endTime}').toList()}',
    );

    // Validate time range - end must be after start
    if (!TimeSlotValidator.isValidTimeRange(startTimeStr, endTimeStr)) {
      setState(() => _errorMessage = 'End time must be after start time');
      HapticFeedback.heavyImpact();
      return;
    }

    final newSlot = TimeSlot(startTime: startTimeStr, endTime: endTimeStr);

    // Check for overlap with existing slots
    final overlappingSlot = TimeSlotValidator.getOverlappingSlot(
      newSlot,
      widget.existingSlots,
    );

    if (overlappingSlot != null) {
      setState(() {
        _errorMessage =
            'Overlaps with: ${overlappingSlot.startTime} - ${overlappingSlot.endTime}';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    // All validations passed
    HapticFeedback.lightImpact();
    widget.onAdd(newSlot);
    Navigator.pop(context);
  }

  Future<void> _selectTime(bool isStartTime) async {
    final initialTime = isStartTime
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 10, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _errorMessage = null;
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_alarm, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text('Add Time Slot', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    context,
                    label: 'Start',
                    time: _startTime,
                    onTap: () => _selectTime(true),
                    colorScheme: colorScheme,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: _buildTimeSelector(
                    context,
                    label: 'End',
                    time: _endTime,
                    onTap: () => _selectTime(false),
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Time slots cannot overlap',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
        ),
        FilledButton.icon(
          onPressed: _validateAndAdd,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    BuildContext context, {
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: time != null
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: time != null
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time != null
                        ? TimeFormatHelper.formatTimeOfDay(time)
                        : 'Select',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: time != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// EDIT TIME SLOT DIALOG
// ================================================================
class _TimeSlotEditDialog extends StatefulWidget {
  final TimeSlot slot;
  final int slotIndex;
  final List<TimeSlot> existingSlots;
  final Function(TimeSlot) onSave;

  const _TimeSlotEditDialog({
    required this.slot,
    required this.slotIndex,
    required this.existingSlots,
    required this.onSave,
  });

  @override
  State<_TimeSlotEditDialog> createState() => _TimeSlotEditDialogState();
}

class _TimeSlotEditDialogState extends State<_TimeSlotEditDialog> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTime = TimeFormatHelper.parseTimeString(widget.slot.startTime);
    _endTime = TimeFormatHelper.parseTimeString(widget.slot.endTime);
  }

  void _validateAndSave() {
    setState(() => _errorMessage = null);

    final startTimeStr = TimeFormatHelper.formatTimeOfDay(_startTime);
    final endTimeStr = TimeFormatHelper.formatTimeOfDay(_endTime);

    debugPrint('Editing slot: $startTimeStr - $endTimeStr');

    if (!TimeSlotValidator.isValidTimeRange(startTimeStr, endTimeStr)) {
      setState(() => _errorMessage = 'End time must be after start time');
      HapticFeedback.heavyImpact();
      return;
    }

    final updatedSlot = TimeSlot(startTime: startTimeStr, endTime: endTimeStr);

    final overlappingSlot = TimeSlotValidator.getOverlappingSlot(
      updatedSlot,
      widget.existingSlots,
      ignoreIndex: widget.slotIndex,
    );

    if (overlappingSlot != null) {
      setState(() {
        _errorMessage =
            'Overlaps with: ${overlappingSlot.startTime} - ${overlappingSlot.endTime}';
      });
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.lightImpact();
    widget.onSave(updatedSlot);
    Navigator.pop(context);
  }

  Future<void> _selectTime(bool isStartTime) async {
    final initialTime = isStartTime ? _startTime : _endTime;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _errorMessage = null;
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_calendar,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text('Edit Time Slot', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Current: ',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '${widget.slot.startTime} - ${widget.slot.endTime}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    context,
                    label: 'Start',
                    time: _startTime,
                    onTap: () => _selectTime(true),
                    colorScheme: colorScheme,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: _buildTimeSelector(
                    context,
                    label: 'End',
                    time: _endTime,
                    onTap: () => _selectTime(false),
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
        ),
        FilledButton.icon(
          onPressed: _validateAndSave,
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Save', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    TimeFormatHelper.formatTimeOfDay(time),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DELETE CONFIRMATION DIALOG
// ================================================================
class _DeleteConfirmationDialog extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({
    required this.slot,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.delete_outline,
              color: colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text('Delete Time Slot', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delete this time slot?',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: colorScheme.error, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${slot.startTime} - ${slot.endTime}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontSize: 13)),
        ),
        FilledButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            onConfirm();
          },
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          child: const Text('Delete', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
