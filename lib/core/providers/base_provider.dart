// ================================================================
// FILE: lib/core/providers/base_provider.dart
// Base class for all providers (Clean, DRY & Safe)
// ================================================================

import 'package:flutter/foundation.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/logger.dart';
import '../../widgets/error_handler.dart';

/// BaseProvider provides common reactive state management for all providers.
/// It handles loading states, error handling, and structured async execution.
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  /// Whether the provider is currently performing a task
  bool get isLoading => _isLoading;

  /// The last error message (if any)
  String? get error => _error;

  /// Convenience getter to check if there's an error
  bool get hasError => _error != null;

  /// Controls whether debug logs are printed
  final bool debugLog = !kReleaseMode;

  // ================================================================
  // CORE STATE METHODS
  // ================================================================

  /// Update loading state
  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    _safeNotifyListeners();
  }

  /// Set an error message
  void setError(String? error) {
    if (_isDisposed) return;
    _error = error;
    _safeNotifyListeners();
  }

  /// Clear the current error
  void clearError() {
    if (_isDisposed) return;
    _error = null;
    _safeNotifyListeners();
  }

  /// Reset provider to default state
  void reset() {
    if (_isDisposed) return;
    _isLoading = false;
    _error = null;
    _safeNotifyListeners();
  }

  /// Safe notify listeners (prevents errors after dispose)
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ================================================================
  // SAFE ASYNC EXECUTION
  // ================================================================

  /// Executes [action] with built-in loading/error handling.
  ///
  /// Example:
  /// ```dart
  /// await executeWithLoading(() async {
  ///   await repository.loadUserData();
  /// });
  /// ```
  ///
  /// You can also use optional callbacks for onSuccess/onError.
  Future<T?> executeWithLoading<T>(
    Future<T> Function() action, {
    String? errorMessage,
    void Function(T result)? onSuccess,
    void Function(Object error)? onError,
    bool showSuccessSnackbar = false,
    String? successMessage,
    bool showErrorSnackbar = true,
  }) async {
    try {
      setLoading(true);
      clearError();

      final T result = await action();

      setLoading(false);

      if (onSuccess != null) onSuccess(result);

      if (showSuccessSnackbar && successMessage != null) {
        snackbarService.showSuccess(successMessage);
      }

      if (debugLog) logI('✅ Action executed successfully');
      return result;
    } catch (error, stackTrace) {
      setLoading(false);

      final errorMsg = errorMessage ?? error.toString();
      setError(errorMsg);

      if (debugLog) {
        logE('⛔ Provider error', error: error, stackTrace: stackTrace);
      }

      if (showErrorSnackbar) {
        snackbarService.showError(
          'Error',
          description: _getReadableError(errorMsg),
        );
      }

      onError?.call(error);
      return null;
    }
  }

  /// Execute action without loading state (silent execution)
  Future<T?> executeSilently<T>(
    Future<T> Function() action, {
    void Function(T result)? onSuccess,
    void Function(Object error)? onError,
  }) async {
    try {
      clearError();

      final T result = await action();

      if (onSuccess != null) onSuccess(result);

      if (debugLog) logI('✅ Silent action executed');
      return result;
    } catch (error, stackTrace) {
      setError(error.toString());

      if (debugLog) {
        logE('⛔ Silent action error', error: error, stackTrace: stackTrace);
      }

      onError?.call(error);
      return null;
    }
  }

  /// Execute multiple actions in sequence
  Future<bool> executeSequence(
    List<Future<void> Function()> actions, {
    String? errorMessage,
    bool stopOnError = true,
    bool showErrorSnackbar = true,
  }) async {
    try {
      setLoading(true);
      clearError();

      for (final action in actions) {
        try {
          await action();
        } catch (e) {
          if (stopOnError) {
            rethrow;
          } else {
            logW('⚠️ Sequence step failed, continuing...', error: e);
          }
        }
      }

      setLoading(false);
      if (debugLog) logI('✅ Sequence executed successfully');
      return true;
    } catch (error, stackTrace) {
      setLoading(false);

      final errorMsg = errorMessage ?? error.toString();
      setError(errorMsg);

      if (debugLog) {
        logE('⛔ Sequence error', error: error, stackTrace: stackTrace);
      }

      if (showErrorSnackbar) {
        snackbarService.showError(
          'Error',
          description: _getReadableError(errorMsg),
        );
      }

      return false;
    }
  }

  // ================================================================
  // ERROR HANDLING HELPERS
  // ================================================================

  /// Convert technical error messages to user-friendly messages using centralized ErrorHandler
  String _getReadableError(String error) {
    return ErrorHandler.formatErrorMessage(error);
  }

  // ================================================================
  // LIFECYCLE
  // ================================================================

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
    if (debugLog) logI('🗑️ Provider disposed');
  }
}
