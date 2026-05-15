// ================================================================
// FILE: lib/core/error/error_handler.dart
// Centralized error handling for the entire app
// Integrated with custom snackbar service
// ================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/logger.dart';
import 'app_snackbar.dart';

/// Global Error Handler with custom snackbar integration
class ErrorHandler {
  // ================================================================
  // ERROR LOGGING
  // ================================================================

  /// Log error to console and crash reporting service
  static void handleError(
    dynamic error, [
    StackTrace? stackTrace,
    String? context,
  ]) {
    final errorMessage = context != null
        ? '🔴 Error in $context: $error'
        : '🔴 Error: $error';

    // Check for network/offline errors
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('AuthRetryableFetchException') ||
        errorStr.contains('ClientException') ||
        errorStr.contains('NetworkException') ||
        errorStr.contains('Failed host lookup')) {
      // Log as Warning only, no stack trace needed for offline issues
      logW(
        '⚠️ Network/Offline issue in ${context ?? "app"}: ${formatErrorMessage(error)}',
      );
      return;
    }

    logE(errorMessage, error: error, stackTrace: stackTrace);

    // TODO: Send to crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // CrashlyticsService.recordError(error, stackTrace);
  }

  /// Log error without showing to user
  static void logError(String message, [dynamic error]) {
    logW('⚠️ $message: $error');
  }

  // ================================================================
  // USER-FACING ERROR DISPLAY (Using Custom Snackbar)
  // ================================================================

  /// Show error snackbar (non-blocking)
  static void showErrorSnackbar(
    String message, {
    BuildContext? context,
    String? title,
  }) {
    AppSnackbar.error(
      title ?? 'Error',
      description: message,
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(
    String message, {
    BuildContext? context,
    String? title,
  }) {
    snackbarService.showSuccess(title ?? 'Success', description: message);
  }

  /// Show info snackbar
  static void showInfoSnackbar(
    String message, {
    BuildContext? context,
    String? title,
  }) {
    snackbarService.showInfo(title ?? 'Info', description: message);
  }

  /// Show warning snackbar
  static void showWarningSnackbar(
    String message, {
    BuildContext? context,
    String? title,
  }) {
    snackbarService.showWarning(title ?? 'Warning', description: message);
  }

  // ================================================================
  // ERROR DIALOG (Blocking)
  // ================================================================

  /// Show error dialog (blocking - use for critical errors)
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message, style: const TextStyle(fontSize: 15)),
        ),
        actions: [
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction();
              },
              child: Text(actionLabel),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  static Future<void> showSuccessDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CONFIRMATION DIALOG
  // ================================================================

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isDangerous ? Icons.warning_amber_rounded : Icons.help_outline,
              color: isDangerous
                  ? Colors.orange
                  : Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDangerous
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? Colors.red : null,
              foregroundColor: isDangerous ? Colors.white : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ================================================================
  // ERROR MESSAGE FORMATTING
  // ================================================================

  /// Convert technical error messages to user-friendly messages
  static String formatErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('SocketException') ||
        errorString.contains('NetworkException') ||
        errorString.contains('Failed host lookup') ||
        errorString.contains('ClientException')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorString.contains('TimeoutException')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (errorString.contains('FormatException')) {
      return 'Invalid data format. Please try again.';
    }

    if (errorString.contains('Unauthorized') || errorString.contains('401')) {
      return 'Your session has expired. Please login again.';
    }

    if (errorString.contains('Forbidden') || errorString.contains('403')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorString.contains('Not Found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('Internal Server Error') ||
        errorString.contains('500')) {
      return 'Server error occurred. Please try again later.';
    }

    if (errorString.contains('Service Unavailable') ||
        errorString.contains('503')) {
      return 'Service temporarily unavailable. Please try again later.';
    }

    // Handle JSON technical error strings (e.g. {"code":..., "message":...})
    try {
      if (errorString.contains('"message":')) {
        // Try to find the JSON part if it's wrapped in other text
        final startIndex = errorString.indexOf('{');
        final endIndex = errorString.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
          final jsonPart = errorString.substring(startIndex, endIndex + 1);
          final Map<String, dynamic> jsonError = jsonDecode(jsonPart);
          if (jsonError.containsKey('message')) {
            final String msg = jsonError['message'];
            if (msg.contains('Database error saving new user')) {
              return 'Service temporarily busy. Please try signing in again.';
            }
            return msg;
          }
        }
      }
    } catch (_) {}

    // Return original error if no pattern matches (truncate if too long)
    return errorString.length > 150
        ? '${errorString.substring(0, 150)}...'
        : errorString;
  }

  // ================================================================
  // LOADING INDICATORS
  // ================================================================

  /// Show loading snackbar
  static void showLoading(String message) {
    snackbarService.showLoading(message);
  }

  /// Hide loading snackbar
  static void hideLoading() {
    snackbarService.hideLoading();
  }

  /// Hide all snackbars
  static void hideAllSnackbars() {
    snackbarService.hideAll();
  }
}
