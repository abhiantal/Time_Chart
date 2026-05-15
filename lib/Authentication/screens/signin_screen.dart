// ================================================================
// FILE 3: lib/screens_widgets/auth/signin_screen.dart
// Professional Sign-In Screen
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../user_profile/create_edit_profile/profile_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_text_field.dart';
import '../auth_navigation_helper.dart';
import '../auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _snackbar = SnackbarService();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    _snackbar.showLoading('Signing in...');

    final user = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    _snackbar.hideLoading();

    if (user == null) {
      if (mounted) {
        _snackbar.showError('Sign in failed', description: authProvider.error);
      }
      return;
    }

    // User authenticated successfully - use centralized navigation helper
    if (mounted) {
      await AuthNavigationHelper.checkProfileAndNavigate(context);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final profileProvider = context.read<ProfileProvider>();

    _snackbar.showLoading('Signing in with Google...');

    final user = await authProvider.signInWithGoogle();

    _snackbar.hideLoading();

    if (user == null) {
      if (mounted && authProvider.error != null) {
        _snackbar.showError(
          'Google sign-in failed',
          description: authProvider.error,
        );
      }
      return;
    }

    // User authenticated successfully - use centralized navigation helper
    if (mounted) {
      await AuthNavigationHelper.checkProfileAndNavigate(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.05),

                    Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Welcome Back',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Sign in to continue to Time Chart',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Email Field
                    CustomTextField.email(
                      controller: _emailController,
                      required: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Email is required';
                        if (!AuthProvider.isValidEmail(value!)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField.password(
                      controller: _passwordController,
                      required: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.pushNamed('forgotPassword');
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign In Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, child) {
                        return ElevatedButton(
                          onPressed: auth.isAuthenticating
                              ? null
                              : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: auth.isAuthenticating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Sign In'),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Sign-In Button
                    OutlinedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 24,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata),
                      ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            context.pushNamed('signUp');
                          },
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
