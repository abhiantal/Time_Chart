// ================================================================
// FILE: lib/user_profile/profile_onboarding.dart
// Single file for profile creation AND editing
// Features: Multi-step flow, validation, offline support, animations
// ================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../media_utility/media_picker.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/bar_progress_indicator.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/logger.dart';
import 'profile_models.dart';
import 'profile_provider.dart';
import 'profile_widgets.dart';

// ================================================================
// ONBOARDING MODE ENUM
// ================================================================

enum ProfileOnboardingMode { create, edit }

// ================================================================
// MAIN ONBOARDING SCREEN
// ================================================================

class ProfileOnboardingScreen extends StatefulWidget {
  /// Mode: create new profile or edit existing
  final ProfileOnboardingMode mode;

  /// Existing profile for editing (optional)
  final UserProfile? existingProfile;

  /// Initial step to show (for deep linking)
  final int initialStep;

  /// Callback when onboarding completes
  final VoidCallback? onComplete;

  const ProfileOnboardingScreen({
    super.key,
    this.mode = ProfileOnboardingMode.create,
    this.existingProfile,
    this.initialStep = 0,
    this.onComplete,
  });

  /// Create mode constructor
  factory ProfileOnboardingScreen.create({
    int initialStep = 0,
    VoidCallback? onComplete,
  }) {
    return ProfileOnboardingScreen(
      mode: ProfileOnboardingMode.create,
      initialStep: initialStep,
      onComplete: onComplete,
    );
  }

  /// Edit mode constructor
  factory ProfileOnboardingScreen.edit({
    required UserProfile profile,
    int initialStep = 0,
    VoidCallback? onComplete,
  }) {
    return ProfileOnboardingScreen(
      mode: ProfileOnboardingMode.edit,
      existingProfile: profile,
      initialStep: initialStep,
      onComplete: onComplete,
    );
  }

  @override
  State<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen>
    with TickerProviderStateMixin {
  // ================================================================
  // CONTROLLERS
  // ================================================================

  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _orgLocationController = TextEditingController();
  final _orgRoleController = TextEditingController();
  final _influencerCategoryController = TextEditingController();
  final _messageForFollowerController = TextEditingController();
  final _customGoalController = TextEditingController();
  final _customWeaknessController = TextEditingController();
  final _customStrengthController = TextEditingController();

  // ================================================================
  // STATE
  // ================================================================

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;

  // Profile Data
  XFile? _selectedImage;
  String? _existingImageUrl;
  String? _primaryGoal;
  List<String> _weaknesses = [];
  List<String> _strengths = [];
  bool _isInfluencer = false;
  bool _isProfilePublic = true;
  bool _openToChat = true;
  String _subscriptionTier = 'free';

  // Steps configuration
  late List<_OnboardingStep> _steps;

  // ================================================================
  // GETTERS
  // ================================================================

  bool get _isCreateMode => widget.mode == ProfileOnboardingMode.create;
  bool get _isEditMode => widget.mode == ProfileOnboardingMode.edit;
  bool get _isLastStep => _currentStep == _steps.length - 1;
  bool get _isFirstStep => _currentStep == 0;

  double get _progress => (_currentStep + 1) / _steps.length;

  String get _nextButtonText {
    if (_isLastStep) {
      return _isEditMode ? 'Save Changes' : 'Complete';
    }
    return 'Continue';
  }

  // ================================================================
  // LIFECYCLE
  // ================================================================

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    _initializeControllers();
    _loadExistingProfile();
  }

  void _initializeSteps() {
    if (_isCreateMode) {
      _steps = [
        _OnboardingStep(
          title: 'Welcome',
          subtitle: 'Let\'s get started',
          icon: Icons.waving_hand_rounded,
        ),
        _OnboardingStep(
          title: 'Basic Info',
          subtitle: 'Tell us about yourself',
          icon: Icons.person_rounded,
        ),
        _OnboardingStep(
          title: 'Profile Picture',
          subtitle: 'Add a photo',
          icon: Icons.camera_alt_rounded,
        ),
        _OnboardingStep(
          title: 'Goals',
          subtitle: 'What drives you?',
          icon: Icons.flag_rounded,
        ),
        _OnboardingStep(
          title: 'Settings',
          subtitle: 'Final touches',
          icon: Icons.settings_rounded,
        ),
      ];
    } else {
      // Edit mode - skip welcome
      _steps = [
        _OnboardingStep(
          title: 'Basic Info',
          subtitle: 'Your details',
          icon: Icons.person_rounded,
        ),
        _OnboardingStep(
          title: 'Profile Picture',
          subtitle: 'Your photo',
          icon: Icons.camera_alt_rounded,
        ),
        _OnboardingStep(
          title: 'Goals',
          subtitle: 'Your aspirations',
          icon: Icons.flag_rounded,
        ),
        _OnboardingStep(
          title: 'Settings',
          subtitle: 'Preferences',
          icon: Icons.settings_rounded,
        ),
      ];
    }
  }

  void _initializeControllers() {
    _currentStep = widget.initialStep.clamp(0, _steps.length - 1);
    _pageController = PageController(initialPage: _currentStep);

    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _progressAnimation = Tween<double>(begin: 0, end: _progress).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _progressAnimationController.forward();
  }

  void _loadExistingProfile() {
    final provider = context.read<ProfileProvider>();
    final profile = widget.existingProfile ?? provider.currentProfile;

    if (profile != null) {
      _usernameController.text = profile.username;
      _displayNameController.text = profile.displayName;
      _addressController.text = profile.address ?? '';
      _orgNameController.text = profile.organizationName ?? '';
      _orgLocationController.text = profile.organizationLocation ?? '';
      _orgRoleController.text = profile.organizationRole ?? '';
      _influencerCategoryController.text = profile.influencerCategory ?? '';
      _messageForFollowerController.text = profile.messageForFollower ?? '';

      _existingImageUrl =
          (profile.profileUrl != null &&
              !UserProfile.isLocalPath(profile.profileUrl!))
          ? profile.profileUrl
          : null;
      _primaryGoal = profile.primaryGoal;
      _weaknesses = List.from(profile.weaknesses);
      _strengths = List.from(profile.strengths);
      _isInfluencer = profile.isInfluencer;
      _isProfilePublic = profile.isProfilePublic;
      _openToChat = profile.openToChat;
      _subscriptionTier = profile.subscriptionTier;
    } else {
      // Fallback to auth metadata for initial pre-fill
      _usernameController.text = provider.authUsername;
      _displayNameController.text = provider.authDisplayName;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _addressController.dispose();
    _orgNameController.dispose();
    _orgLocationController.dispose();
    _orgRoleController.dispose();
    _influencerCategoryController.dispose();
    _messageForFollowerController.dispose();
    _customGoalController.dispose();
    _customWeaknessController.dispose();
    _customStrengthController.dispose();
    super.dispose();
  }

  // ================================================================
  // NAVIGATION
  // ================================================================

  void _nextStep() {
    if (_isLoading || _isSaving) return;

    // Validate current step
    if (!_validateCurrentStep()) return;

    if (_isLastStep) {
      _saveProfile();
    } else {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_isLoading || _isSaving) return;

    if (_isFirstStep) {
      _handleBack();
    } else {
      _goToStep(_currentStep - 1);
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _steps.length) return;

    setState(() => _currentStep = step);

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );

    // Animate progress
    _progressAnimation =
        Tween<double>(
          begin: _progressAnimation.value,
          end: (step + 1) / _steps.length,
        ).animate(
          CurvedAnimation(
            parent: _progressAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _progressAnimationController.forward(from: 0);
  }

  void _handleBack() {
    if (_isEditMode) {
      context.pop();
    } else {
      // Show confirmation for create mode
      _showExitConfirmation();
    }
  }

  Future<void> _showExitConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Exit Setup?'),
          ],
        ),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      context.pop();
    }
  }

  // ================================================================
  // CUSTOM INPUT HARVESTER
  // ================================================================

  /// Automatically harvests any typed but unsubmitted custom entries in Goals step
  void _harvestCustomInputs() {
    final customGoal = _customGoalController.text.trim();
    final customWeakness = _customWeaknessController.text.trim();
    final customStrength = _customStrengthController.text.trim();

    if (customGoal.isNotEmpty || customWeakness.isNotEmpty || customStrength.isNotEmpty) {
      setState(() {
        if (customGoal.isNotEmpty) {
          _primaryGoal = customGoal;
          _customGoalController.clear();
        }
        if (customWeakness.isNotEmpty && !_weaknesses.contains(customWeakness)) {
          if (_weaknesses.length < 5) {
            _weaknesses.add(customWeakness);
            _customWeaknessController.clear();
          }
        }
        if (customStrength.isNotEmpty && !_strengths.contains(customStrength)) {
          if (_strengths.length < 5) {
            _strengths.add(customStrength);
            _customStrengthController.clear();
          }
        }
      });
    }
  }

  // ================================================================
  // VALIDATION
  // ================================================================

  bool _validateCurrentStep() {
    final stepIndex = _isCreateMode ? _currentStep : _currentStep + 1;

    switch (stepIndex) {
      case 0: // Welcome (create mode only)
        return true;

      case 1: // Basic Info
        return _validateBasicInfo();

      case 2: // Profile Picture
        return true; // Optional

      case 3: // Goals
        _harvestCustomInputs();
        return true; // Optional

      case 4: // Settings
        return true;

      default:
        return true;
    }
  }

  bool _validateBasicInfo() {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();

    if (displayName.isEmpty) {
      AppSnackbar.error('Please enter a display name');
      return false;
    }

    if (username.isEmpty) {
      AppSnackbar.error('Please enter a username');
      return false;
    }

    if (username.length < ProfileConstants.minUsernameLength) {
      AppSnackbar.error(
        'Username too short',
        description:
            'Must be at least ${ProfileConstants.minUsernameLength} characters',
      );
      return false;
    }

    if (username.length > ProfileConstants.maxUsernameLength) {
      AppSnackbar.error(
        'Username too long',
        description:
            'Must be at most ${ProfileConstants.maxUsernameLength} characters',
      );
      return false;
    }

    if (!ProfileConstants.usernamePattern.hasMatch(username)) {
      AppSnackbar.error(
        'Invalid username',
        description: 'Only letters, numbers, and underscores allowed',
      );
      return false;
    }

    return true;
  }

  // ================================================================
  // SAVE PROFILE
  // ================================================================

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    // Harvest any leftover custom text values before saving
    _harvestCustomInputs();

    setState(() => _isSaving = true);
    AppSnackbar.loading(
      title: _isEditMode ? 'Saving changes...' : 'Completing setup...',
    );

    try {
      final provider = context.read<ProfileProvider>();

      final Map<String, dynamic> profileData = {
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'organization_name': _orgNameController.text.trim().isNotEmpty
            ? _orgNameController.text.trim()
            : null,
        'organization_location': _orgLocationController.text.trim().isNotEmpty
            ? _orgLocationController.text.trim()
            : null,
        'organization_role': _orgRoleController.text.trim().isNotEmpty
            ? _orgRoleController.text.trim()
            : null,
        'is_influencer': _isInfluencer,
        'influencer_category':
            _isInfluencer &&
                _influencerCategoryController.text.trim().isNotEmpty
            ? _influencerCategoryController.text.trim()
            : null,
        'message_for_follower':
            _isInfluencer &&
                _messageForFollowerController.text.trim().isNotEmpty
            ? _messageForFollowerController.text.trim()
            : null,
        'primary_goal': _primaryGoal,
        'weaknesses': _weaknesses,
        'strengths': _strengths,
        'is_profile_public': _isProfilePublic,
        'open_to_chat': _openToChat,
        'subscription_tier': _subscriptionTier,
        'onboarding_completed': true,
      };

      bool success;

      if (_isCreateMode) {
        // Fast parallel creation (Avatar + Metadata)
        success = await provider.createProfileWithAvatar(
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
          avatarFile: _selectedImage,
          additionalData: profileData,
        );
      } else {
        // Update mode - handle avatar if changed
        if (_selectedImage != null) {
          await provider.uploadAvatar(_selectedImage!);
        }

        success = await provider.updateProfile(
          ProfileUpdateDto(
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
            address: profileData['address'],
            orgName: profileData['organization_name'],
            orgLocation: profileData['organization_location'],
            orgRole: profileData['organization_role'],
            isInfluencer: _isInfluencer,
            influencerCategory: profileData['influencer_category'],
            messageForFollower: profileData['message_for_follower'],
            primaryGoal: _primaryGoal,
            weaknesses: _weaknesses,
            strengths: _strengths,
            isProfilePublic: _isProfilePublic,
            openToChat: _openToChat,
            subscriptionTier: _subscriptionTier,
            onboardingCompleted: true,
          ),
        );
      }

      AppSnackbar.hideLoading();

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        AppSnackbar.success(
          _isEditMode ? 'Profile updated! ✨' : 'Welcome aboard! 🎉',
        );

        if (widget.onComplete != null) {
          widget.onComplete!();
        } else if (_isEditMode) {
          context.pop();
        } else {
          context.goNamed('home');
        }
      }
    } catch (e, s) {
      logE('Failed to save profile', error: e, stackTrace: s);
      AppSnackbar.hideLoading();
      AppSnackbar.error('Failed to save profile', description: e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ================================================================
  // IMAGE PICKER
  // ================================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image = await EnhancedMediaPicker.pickMedia(
        context,
        config: const MediaPickerConfig(
          allowVideo: false,
          allowImage: true,
          allowCamera: true,
          allowGallery: true,
          autoCompress: true,
          imageQuality: 85,
          maxFileSizeMB: 5,
        ),
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() => _selectedImage = image);
          HapticFeedback.lightImpact();
          AppSnackbar.success('Photo selected!');
        }
      }
    } catch (e) {
      logE('Failed to pick image', error: e);
      AppSnackbar.error('Failed to select photo');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
    HapticFeedback.lightImpact();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _isEditMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isCreateMode) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme),

              // Progress
              _buildProgress(theme),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: _buildStepPages(),
                ),
              ),

              // Bottom Navigation
              _buildBottomNavigation(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: _previousStep,
            icon: Icon(
              _isFirstStep ? Icons.close_rounded : Icons.arrow_back_rounded,
            ),
            tooltip: _isFirstStep ? 'Exit' : 'Back',
          ),

          // Title
          Expanded(
            child: Column(
              children: [
                Text(
                  _steps[_currentStep].title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _steps[_currentStep].subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentStep + 1}/${_steps.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ================================================================
  // PROGRESS BAR
  // ================================================================

  Widget _buildProgress(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return CustomProgressIndicator(
            progress: _progressAnimation.value,
            orientation: ProgressOrientation.horizontal,
            width: double.infinity,
            baseHeight: 8,
            maxHeightIncrease: 4,
            gradientColors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            borderRadius: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            animated: false,
            progressBarName: '',
          );
        },
      ),
    );
  }

  // ================================================================
  // STEP PAGES
  // ================================================================

  List<Widget> _buildStepPages() {
    if (_isCreateMode) {
      return [
        _buildWelcomeStep(),
        _buildBasicInfoStep(),
        _buildProfilePictureStep(),
        _buildGoalsStep(),
        _buildSettingsStep(),
      ];
    } else {
      return [
        _buildBasicInfoStep(),
        _buildProfilePictureStep(),
        _buildGoalsStep(),
        _buildSettingsStep(),
      ];
    }
  }

  // ================================================================
  // STEP 1: WELCOME (Create mode only)
  // ================================================================

  Widget _buildWelcomeStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 40),

          Text(
            'Welcome to Time Chart!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Let\'s set up your profile in a few quick steps. '
            'This will help you connect with others and get the most out of the app.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Features
          FeatureItem(
            icon: Icons.groups_rounded,
            title: 'Connect',
            description: 'Find and connect with people in your organization',
            iconColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          FeatureItem(
            icon: Icons.trending_up_rounded,
            title: 'Grow',
            description: 'Track your goals and compete with others',
            iconColor: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          FeatureItem(
            icon: Icons.shield_rounded,
            title: 'Private',
            description: 'Your data is secure and always under your control',
            iconColor: theme.colorScheme.tertiary,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================================================================
  // STEP 2: BASIC INFO
  // ================================================================

  Widget _buildBasicInfoStep() {
    Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Section: Personal
            const SectionHeader(
              title: 'Personal Information',
              subtitle: 'Required fields are marked with *',
            ),
            const SizedBox(height: 20),

            // Display Name
            CustomTextField.singleline(
              controller: _displayNameController,
              label: 'Display Name',
              hint: 'Your Name or Nickname',
              prefixIcon: Icons.badge_rounded,
              required: true,
              maxLength: ProfileConstants.maxDisplayNameLength,
            ),

            const SizedBox(height: 20),

            // Username
            CustomTextField.singleline(
              controller: _usernameController,
              label: 'Username',
              hint: 'your_username',
              prefixIcon: Icons.alternate_email_rounded,
              required: true,
              maxLength: ProfileConstants.maxUsernameLength,
              helperText: 'Letters, numbers, and underscores only',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              ],
            ),

            const SizedBox(height: 20),

            // Address
            CustomTextField.multiline(
              controller: _addressController,
              label: 'Location',
              hint: 'City, State, Country',
              prefixIcon: Icons.location_on_rounded,
              maxLines: 2,
              maxLength: ProfileConstants.maxAddressLength,
            ),

            const SizedBox(height: 32),

            // Section: Organization
            const SectionHeader(
              title: 'Organization',
              subtitle: 'Where do you work or study?',
            ),
            const SizedBox(height: 20),

            // Organization Name
            CustomTextField.singleline(
              controller: _orgNameController,
              label: 'Organization Name',
              hint: 'Company, University, School...',
              prefixIcon: Icons.business_rounded,
              maxLength: ProfileConstants.maxOrgNameLength,
            ),

            const SizedBox(height: 16),

            // Org Location
            CustomTextField.singleline(
              controller: _orgLocationController,
              label: 'Organization Location',
              hint: 'City, Country',
              prefixIcon: Icons.location_on_rounded,
              maxLength: ProfileConstants.maxOrgLocationLength,
            ),

            const SizedBox(height: 16),

            // Role
            CustomTextField.singleline(
              controller: _orgRoleController,
              label: 'Your Role',
              hint: 'Student, Developer, Manager...',
              prefixIcon: Icons.badge_rounded,
              maxLength: ProfileConstants.maxOrgRoleLength,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // STEP 3: PROFILE PICTURE
  // ================================================================

  Widget _buildProfilePictureStep() {
    final theme = Theme.of(context);
    final hasImage =
        _selectedImage != null ||
        (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          Text(
            'Add a profile picture',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Help others recognize you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Avatar Preview
          GestureDetector(
            onTap: _pickImage,
            child: ProfileAvatar(
              imageUrl: _selectedImage?.path ?? _existingImageUrl,
              fallbackText: _usernameController.text,
              size: 180,
              showEditButton: true,
              onEditTap: _pickImage,
              borderWidth: 4,
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Upload Button
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(hasImage ? 'Change Photo' : 'Upload Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),

              // Remove Button
              if (hasImage) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Skip hint
          if (!hasImage)
            Text(
              'You can skip this step and add a photo later',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ================================================================
  // STEP 4: GOALS
  // ================================================================

  Widget _buildGoalsStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Progress Summary
          _buildGoalsProgress(theme),

          const SizedBox(height: 32),

          // Primary Goal
          SectionHeader(
            title: 'Primary Goal',
            subtitle: 'What\'s your main focus right now?',
          ),
          const SizedBox(height: 16),

          GoalSelector(
            goals: ProfileConstants.commonGoals,
            selectedGoal: _primaryGoal,
            onSelected: (goal) {
              setState(() => _primaryGoal = goal);
              HapticFeedback.selectionClick();
            },
            customController: _customGoalController,
          ),

          const SizedBox(height: 32),

          // Weaknesses
          SectionHeader(
            title: 'Areas to Improve',
            subtitle: 'What would you like to work on?',
          ),
          const SizedBox(height: 16),

          ChipSelector(
            options: ProfileConstants.commonWeaknesses,
            selected: _weaknesses,
            onChanged: (values) {
              setState(() => _weaknesses = values);
              HapticFeedback.selectionClick();
            },
            customInputHint: 'Add custom area...',
            customInputController: _customWeaknessController,
            maxSelection: 5,
          ),

          const SizedBox(height: 32),

          // Strengths
          SectionHeader(
            title: 'Your Strengths',
            subtitle: 'What are you good at?',
          ),
          const SizedBox(height: 16),

          ChipSelector(
            options: ProfileConstants.commonStrengths,
            selected: _strengths,
            onChanged: (values) {
              setState(() => _strengths = values);
              HapticFeedback.selectionClick();
            },
            customInputHint: 'Add custom strength...',
            customInputController: _customStrengthController,
            maxSelection: 5,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGoalsProgress(ThemeData theme) {
    int filled = 0;
    if (_primaryGoal != null && _primaryGoal!.isNotEmpty) filled++;
    if (_weaknesses.isNotEmpty) filled++;
    if (_strengths.isNotEmpty) filled++;

    final progress = filled / 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Goals Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$filled/3',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomProgressIndicator(
            progress: progress,
            orientation: ProgressOrientation.horizontal,
            width: double.infinity,
            baseHeight: 10,
            maxHeightIncrease: 4,
            gradientColors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
            borderRadius: 6,
            animated: true,
            progressBarName: '',
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STEP 5: SETTINGS
  // ================================================================

  Widget _buildSettingsStep() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Privacy Section
          SectionHeader(
            title: 'Privacy',
            subtitle: 'Control your profile visibility',
          ),
          const SizedBox(height: 16),

          ToggleCard(
            title: 'Public Profile',
            description: _isProfilePublic
                ? 'Anyone can view your profile'
                : 'Only you can see your profile',
            icon: _isProfilePublic ? Icons.public_rounded : Icons.lock_rounded,
            value: _isProfilePublic,
            onChanged: (value) {
              setState(() => _isProfilePublic = value);
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 16),

          ToggleCard(
            title: 'Open to Chat',
            description: _openToChat
                ? 'Allow others to start a chat with you'
                : 'Direct messages are disabled',
            icon: _openToChat ? Icons.chat_rounded : Icons.chat_bubble_outline_rounded,
            value: _openToChat,
            onChanged: (value) {
              setState(() => _openToChat = value);
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 16),

          ToggleCard(
            title: 'Influencer Mode',
            description: _isInfluencer
                ? 'Show as an influencer profile'
                : 'Standard user profile',
            icon: _isInfluencer
                ? Icons.verified_rounded
                : Icons.person_outline_rounded,
            value: _isInfluencer,
            onChanged: (value) {
              setState(() => _isInfluencer = value);
              HapticFeedback.selectionClick();
            },
          ),

          // Influencer Details
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _isInfluencer
                ? _buildInfluencerDetails(theme)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 32),

          // Subscription Section
          SectionHeader(
            title: 'Subscription',
            subtitle: 'Choose your plan (can upgrade later)',
          ),
          const SizedBox(height: 16),

          SubscriptionTierCard.free(
            isSelected: _subscriptionTier == 'free',
            onTap: () {
              setState(() => _subscriptionTier = 'free');
              HapticFeedback.selectionClick();
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfluencerDetails(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Influencer Details',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          DropdownButtonFormField<String>(
            value: _influencerCategoryController.text.isNotEmpty
                ? _influencerCategoryController.text
                : null,
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: const Icon(Icons.category_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ProfileConstants.influencerCategories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _influencerCategoryController.text = value ?? '';
              });
            },
          ),

          const SizedBox(height: 16),

          // Message for Followers
          CustomTextField.multiline(
            controller: _messageForFollowerController,
            label: 'Message for Followers',
            hint: 'Write something for your followers...',
            prefixIcon: Icons.message_rounded,
            maxLines: 3,
            maxLength: ProfileConstants.maxMessageForFollowerLength,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step Indicators
          Expanded(
            child: Row(
              children: List.generate(_steps.length, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;

                return Expanded(
                  child: GestureDetector(
                    onTap: isCompleted ? () => _goToStep(index) : null,
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary
                            : isCompleted
                            ? theme.colorScheme.primary.withOpacity(0.4)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 24),

          // Next/Complete Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: (_isLoading || _isSaving) ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: _isLastStep ? theme.colorScheme.primary : null,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _nextButtonText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (!_isLastStep) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                        if (_isLastStep) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_rounded, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ONBOARDING STEP DATA CLASS
// ================================================================

class _OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

// ================================================================
// EXTENSION FOR EASY NAVIGATION
// ================================================================

extension ProfileOnboardingNavigation on BuildContext {
  /// Navigate to profile creation
  void goToProfileCreate({VoidCallback? onComplete}) {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => ProfileOnboardingScreen.create(onComplete: onComplete),
      ),
    );
  }

  /// Navigate to profile editing
  void goToProfileEdit({
    required UserProfile profile,
    int initialStep = 0,
    VoidCallback? onComplete,
  }) {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => ProfileOnboardingScreen.edit(
          profile: profile,
          initialStep: initialStep,
          onComplete: onComplete,
        ),
      ),
    );
  }
}
