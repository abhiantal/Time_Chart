// ================================================================
// FILE 4: lib/screens_widgets/auth/signup_screen.dart
// Professional Sign-Up Screen
// ================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/custom_text_field.dart';
import '../auth_navigation_helper.dart';
import '../auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _snackbar = SnackbarService();

  bool _agreedToTerms = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _snackbar.showWarning('Please agree to Terms & Conditions');
      return;
    }

    final authProvider = context.read<AuthProvider>();

    _snackbar.showLoading('Creating account...');

    final user = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim(),
    );

    _snackbar.hideLoading();

    if (user != null && mounted) {
      // User created successfully - use centralized navigation helper
      await AuthNavigationHelper.checkProfileAndNavigate(context);
    } else if (mounted) {
      _snackbar.showError('Sign up failed', description: authProvider.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _animController,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Join Time Chart',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Username
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Abhimanyu',
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Username is required';
                      if (value!.length < 2) return 'Username too short';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email
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

                  // Password field
                  CustomTextField.password(
                    controller: _passwordController,
                    required: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (!AuthProvider.validatePassword(value)) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  CustomTextField.password(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    required: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Terms & Conditions
                  CheckboxListTile(
                    value: _agreedToTerms,
                    onChanged: (value) =>
                        setState(() => _agreedToTerms = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Wrap(
                      children: [
                        const Text('I agree to the '),
                        GestureDetector(
                          onTap: () {
                            // Open terms
                          },
                          child: Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign Up Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return ElevatedButton(
                        onPressed: auth.isAuthenticating ? null : _handleSignUp,
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
                            : const Text('Create Account'),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
