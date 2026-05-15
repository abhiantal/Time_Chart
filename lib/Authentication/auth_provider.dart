// ================================================================
// FILE: lib/providers/auth_provider.dart
// Authentication Provider for State Management
// ================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/providers/base_provider.dart';
import '../widgets/logger.dart';

class AuthProvider extends BaseProvider {
  User? _currentUser;
  bool _isAuthenticating = false;
  GoogleSignIn? _googleSignInInstance;

  User? get currentUser => _currentUser;
  bool get isAuthenticating => _isAuthenticating;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  // Lazy initialization of GoogleSignIn
  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      scopes: <String>[
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ],
    );
    return _googleSignInInstance!;
  }

  void _initializeAuth() {
    _currentUser = Supabase.instance.client.auth.currentUser;

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (authState) {
        final event = authState.event;
        final session = authState.session;

        logI('Auth state changed event: $event');

        if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.userDeleted) {
          _currentUser = null;
          logI('User explicitly signed out or deleted');
          notifyListeners();
        } else if (session != null) {
          _currentUser = session.user;
          logI('User authenticated: ${_currentUser?.id}');
          notifyListeners();
        } else {
          // If session is null but it's NOT a signedOut or userDeleted event,
          // do NOT immediately log out if we already have a current user.
          // Check if Supabase client really has no session anymore.
          final currentSession = Supabase.instance.client.auth.currentSession;
          if (currentSession == null) {
            _currentUser = null;
            logI('Session is genuinely null, signing out');
            notifyListeners();
          } else {
            logW('Received null session event ($event) but currentSession is still present. Ignoring.');
          }
        }
      },
      onError: (error) {
        final errorStr = error.toString();
        if (errorStr.contains('Failed host lookup') ||
            errorStr.contains('SocketException') ||
            errorStr.contains('AuthRetryableFetchException') ||
            errorStr.contains('ClientException') ||
            error is SocketException) {
          logW('Network error in auth provider - waiting for connection...');
        } else {
          logE('Auth provider listener error', error: error);
        }
      },
    );
  }

  /// Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    // 1. Pre-check username availability
    if (await _isUsernameTaken(username)) {
      _isAuthenticating = false;
      setError('Username already taken. Please choose another.');
      notifyListeners();
      return null;
    }

    try {
      logI('Attempting signup for: $email');

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': username,
          'display_name': username,
        },
      );

      final user = response.user;

      if (user != null) {
        _currentUser = user;
        _isAuthenticating = false;
        notifyListeners();
        return user;
      } else {
        _isAuthenticating =
            false; // logic was using _isLoading which is undefined
        notifyListeners();
        return null;
      }
    } on AuthException catch (error) {
      _isAuthenticating =
          false; // logic was using _isLoading which is undefined
      notifyListeners();

      String errorMessage = error.message;
      final status = error.statusCode;

      // Check for known "Database error saving new user" (500)
      // Note: statusCode can be String or Int depending on the exception subclass in some versions
      final isDatabaseError =
          status == '500' ||
          status == 500 ||
          error.message.contains('Database error saving new user');

      if (isDatabaseError) {
        // Known error case: likely collision. Log as info only.
        logI(
          'Signup caught expected concurrency/duplicate error (500): ${error.message}',
        );
        errorMessage =
            'Username or email might already be taken, or there is a temporary server issue.';
      } else {
        // Unknown error: Log as warning/error
        logW('Signup AuthException: $status - ${error.message}');

        if (status == '422' || status == 422) {
          if (error.message.contains('already registered')) {
            errorMessage = 'This email is already registered. Please sign in.';
          }
        } else {
          // Try to parse JSON message if it looks like one: {"code":..., "message":"..."}
          try {
            if (errorMessage.startsWith('{') &&
                errorMessage.contains('"message":')) {
              // Simple regex extract to avoid full json decode overhead if simpler
              final match = RegExp(
                r'"message":"([^"]+)"',
              ).firstMatch(errorMessage);
              if (match != null) {
                errorMessage = match.group(1) ?? errorMessage;
              }
            }
          } catch (_) {}
        }
      }

      setError(errorMessage);
      return null;
    } catch (error, stackTrace) {
      _isAuthenticating = false;

      // extensive check for the specific type name if standard catch failed
      if (error.runtimeType.toString().contains(
            'AuthRetryableFetchException',
          ) ||
          error.toString().contains('Database error saving new user')) {
        // This specific error should be fixed by valid trigger logic, but keeping as fallback
        logW('Supabase 500 error caught. Check if trigger failed: $error');
        setError('Service temporarily unavailable. Please try again.');
      } else {
        setError('An unexpected error occurred. Please try again.');
        logE('Unexpected signup error', error: error, stackTrace: stackTrace);
      }

      notifyListeners();
      return null;
    }
  }

  // ================================================================
  // VALIDATION HELPERS
  // ================================================================

  /// Validates an email address
  static bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.+_-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+").hasMatch(email);
  }

  /// Validates a password
  static bool validatePassword(String password) {
    return password.length >= 6;
  }

  /// Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      logI('Attempting signin for: $email');

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        logI('✓ Signin successful: ${response.user!.id}');
      }

      _isAuthenticating = false;
      _currentUser = response.user;
      notifyListeners();

      return response.user;
    } on AuthException catch (error) {
      _isAuthenticating = false;
      setError(_handleAuthException(error));
      logE('Signin error', error: error);
      notifyListeners();
      return null;
    } catch (error, stackTrace) {
      _isAuthenticating = false;
      setError('An unexpected error occurred. Please try again.');
      logE('Unexpected signin error', error: error, stackTrace: stackTrace);
      notifyListeners();
      return null;
    }
  }

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      logI('Attempting Google sign-in');

      // Ensure we're signed out first
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        logI('Google sign-in cancelled by user');
        _isAuthenticating = false;
        notifyListeners();
        return null;
      }

      logI('Google user obtained: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw 'Failed to get Google ID token';
      }

      logI('Google tokens obtained, signing in to Supabase...');

      // Sign in to Supabase with Google credentials
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        logI('✓ Google signin successful: ${response.user!.id}');
      }

      _isAuthenticating = false;
      _currentUser = response.user;
      notifyListeners();

      return response.user;
    } on AuthException catch (error) {
      _isAuthenticating = false;
      setError(_handleAuthException(error));
      logE('Supabase auth error during Google sign-in', error: error);
      notifyListeners();
      return null;
    } catch (error, stackTrace) {
      _isAuthenticating = false;

      String errorMsg = 'Failed to sign in with Google. Please try again.';
      if (error.toString().contains('cancelled') ||
          error.toString().contains('CANCELED') ||
          error.toString().contains('cancel')) {
        errorMsg = 'Google sign-in was cancelled';
      } else if (error.toString().contains('network')) {
        errorMsg = 'Network error. Please check your connection and try again.';
      }

      setError(errorMsg);
      logE('Google signin error', error: error, stackTrace: stackTrace);
      notifyListeners();
      return null;
    }
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    try {
      logI('Sending password reset email to: $email');
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      logI('✓ Password reset email sent');
    } on AuthException catch (error) {
      logE('Reset password error', error: error);
      throw _handleAuthException(error);
    } catch (error, stackTrace) {
      logE(
        'Unexpected reset password error',
        error: error,
        stackTrace: stackTrace,
      );
      throw 'Failed to send reset email. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      logI('Signing out user session');

      // Sign out from Google first if signed in
      if (_googleSignInInstance != null && await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }

      await Supabase.instance.client.auth.signOut();
      _currentUser = null;
      logI('✓ User signed out');
      notifyListeners();
    } catch (error, stackTrace) {
      logE('Signout error', error: error, stackTrace: stackTrace);
      throw 'Failed to sign out. Please try again.';
    }
  }

  // ================================================================
  // HELPER METHODS
  // ================================================================

  /// Checks if a username is already taken in the public profiles table
  Future<bool> _isUsernameTaken(String username) async {
    try {
      // Query public user_profiles. RLS 'anon' role should allow reading this if configured correctly.
      // If RLS blocks it, this might throw or return empty.
      final result = await Supabase.instance.client
          .from('user_profiles')
          .select('username')
          .ilike('username', username)
          .limit(1)
          .maybeSingle();

      return result != null;
    } catch (e) {
      logW('Username availability check failed: $e');
      // If check fails (e.g. network or RLS), allow signup to proceed and let backend validations persist.
      return false;
    }
  }

  /// Handle Supabase auth exceptions
  String _handleAuthException(AuthException error) {
    switch (error.statusCode) {
      case '400':
        if (error.message.contains('already registered')) {
          return 'This email is already registered. Please sign in instead.';
        }
        return 'Invalid request. Please check your input.';
      case '401':
        return 'Invalid email or password. Please try again.';
      case '422':
        if (error.message.contains('email')) {
          return 'Invalid email format.';
        }
        if (error.message.contains('password')) {
          return 'Password must be at least 6 characters.';
        }
        return 'Please check your input and try again.';
      case '429':
        return 'Too many attempts. Please try again later.';
      case '500':
        if (error.message.contains('Database error saving new user')) {
          return 'Failed to create your profile. Please try signing in again.';
        }
        return 'Internal server error. Please try again later.';
      default:
        // Try to parse JSON from the message
        try {
          if (error.message.startsWith('{') &&
              error.message.contains('"message":')) {
            final Map<String, dynamic> jsonError = jsonDecode(error.message);
            return jsonError['message'] ?? error.message;
          }
        } catch (_) {}
        return error.message;
    }
  }
}
