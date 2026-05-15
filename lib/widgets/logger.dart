import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Custom logger configuration for the app
class AppLogger {
  static Logger? _instance;

  static Logger get instance {
    if (_instance != null) return _instance!;
    
    _instance = Logger(
      level: kDebugMode ? Level.debug : Level.error,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
    return _instance!;
  }
}

/// Initialize here main global [Logger] instance.
Logger _logger = AppLogger.instance;

/// Log error method that used for printing out the error.
void logE(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  _logger.e(
    message,
    time: time ?? DateTime.now(),
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log warning that used for printing warning/important messages
/// to pay developer attention on it, rather than using logI method.
void logW(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  _logger.w(
    message,
    time: time ?? DateTime.now(),
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log info method that used for printing info message.
void logI(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  _logger.i(
    message,
    time: time ?? DateTime.now(),
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log debug method to illustrate that the message is in debug mode
void logD(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  _logger.d(
    message,
    time: time ?? DateTime.now(),
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log trace method for very detailed debugging
void logT(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  _logger.t(
    message,
    time: time ?? DateTime.now(),
    error: error,
    stackTrace: stackTrace,
  );
}

/// Log fatal method for critical errors that might crash the app
void logF(
  dynamic message, {
  DateTime? time,
  Object? error,
  StackTrace? stackTrace,
}) {
  _logger.f(
    message,
    time: time ?? DateTime.now(),
    error: error,
    stackTrace: stackTrace,
  );
}

/// Extension methods for easier logging
extension LoggerExtension on Object {
  void logError([Object? error, StackTrace? stackTrace]) {
    logE(toString(), error: error, stackTrace: stackTrace);
  }

  void logWarning([Object? error, StackTrace? stackTrace]) {
    logW(toString(), error: error, stackTrace: stackTrace);
  }

  void logInfo([Object? error, StackTrace? stackTrace]) {
    logI(toString(), error: error, stackTrace: stackTrace);
  }

  void logDebug([Object? error, StackTrace? stackTrace]) {
    logD(toString(), error: error, stackTrace: stackTrace);
  }
}
