import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../../media_utility/universal_media_service.dart';
import '../../../../media_utility/gallery_picker_screen.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/app_snackbar.dart';
import 'package:the_time_chart/features/chats/model/chat_model.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/common/user_avatar_cached.dart';
import '../../../personal/category_model/providers/category_provider.dart';
import '../../../personal/category_model/models/category_model.dart' as cat_model;
import '../moderation/rules_editor_screen.dart';
import 'widgets/create_chat_ui_helper.dart';

class CreateCommunityScreen extends StatefulWidget {
  final ChatModel? existingCommunity;
  const CreateCommunityScreen({super.key, this.existingCommunity});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  cat_model.Category? _selectedCategory;
  
  bool _isCreating = false;
  bool _requireApproval = false;
  ChatVisibility _visibility = ChatVisibility.public;
  
  File? _avatarFile;
  String? _avatarPath;
  File? _bannerFile;
  String? _bannerPath;
  
  List<String> _rules = [];

  bool get _isEditing => widget.existingCommunity != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.existingCommunity != null) {
      final chat = widget.existingCommunity!;
      _nameController.text = chat.displayName;
      _descriptionController.text = chat.description ?? '';
      _avatarPath = chat.avatar;
      _bannerPath = chat.banner;
      _requireApproval = chat.metadata['require_approval'] == true;
      _visibility = chat.visibility;
      _rules = List<String>.from(chat.metadata['rules'] ?? []);
      
      final categoryId = chat.metadata['category_id']?.toString();
      if (categoryId != null) {
         // We'll resolve the category object in the PostFrameCallback
      }
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategoriesByType(cat_model.CategoryForType.community).then((_) {
        if (mounted) {
           final categories = context.read<CategoryProvider>().getCategoriesByType(cat_model.CategoryForType.community);
           if (_isEditing) {
              final catId = widget.existingCommunity?.metadata['category_id']?.toString();
              setState(() {
                _selectedCategory = categories.cast<cat_model.Category?>().firstWhere(
                  (c) => c?.id == catId, 
                  orElse: () => null,
                );
              });
           }
        }
      });
    });
  }

  Future<void> _pickImage({required bool isBanner}) async {
    final result = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (context) => const GalleryPickerScreen(
          allowMultiple: false,
          maxSelection: 1,
          allowedTypes: [AssetType.image],
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      if (isBanner) {
        _bannerFile = result.first;
      } else {
        _avatarFile = result.first;
      }
    });
    
    final uploadedPath = await UniversalMediaService().uploadAvatar(result.first);
    if (uploadedPath != null && mounted) {
      setState(() {
        if (isBanner) {
          _bannerPath = uploadedPath;
        } else {
          _avatarPath = uploadedPath;
        }
      });
    }
  }

  void _showCategoryPicker() {
    final provider = context.read<CategoryProvider>();
    final categories = provider.getCategoriesByType(cat_model.CategoryForType.community);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Community Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory?.id == cat.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(cat.icon, style: const TextStyle(fontSize: 18))),
                    title: Text(cat.categoryType, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRulesEditor() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => RulesEditorScreen(initialRules: _rules),
      ),
    );
    if (result != null) {
      setState(() => _rules = result);
    }
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      AppSnackbar.error('Community name is required');
      return;
    }
    if (_selectedCategory == null) {
      AppSnackbar.error('Please select a category');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final provider = context.read<ChatProvider>();
      if (_isEditing) {
        await provider.updateChatInfo(
          chatId: widget.existingCommunity!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          avatar: _avatarPath,
          banner: _bannerPath,
          visibility: _visibility,
        );
        
        final meta = Map<String, dynamic>.from(widget.existingCommunity!.metadata);
        meta['rules'] = _rules;
        meta['require_approval'] = _requireApproval;
        meta['category_id'] = _selectedCategory?.id;
        meta['category_name'] = _selectedCategory?.categoryType;
        await provider.updateChatMetadata(widget.existingCommunity!.id, meta);

        AppSnackbar.success('Community updated');
        if (mounted) context.pop();
      } else {
        final result = await provider.createCommunityChat(
          name: _nameController.text.trim(),
          categoryId: _selectedCategory!.id,
          avatar: _avatarPath,
          banner: _bannerPath,
          description: _descriptionController.text.trim(),
          requireApproval: _requireApproval,
          rules: _rules,
          visibility: _visibility,
        );
        if (result.success) {
          AppSnackbar.success('Community created!');
          if (mounted) context.pop();
        } else {
          AppSnackbar.error('Failed to create community');
        }
      }
    } catch (e) {
      AppSnackbar.error('Error: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CreateChatUIHelper.buildSectionHeader(context, 'Identity'),
                      CreateChatUIHelper.buildContainer(
                        context: context,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _nameController,
                                  label: 'Community Name',
                                  hint: 'e.g. Flutter Enthusiasts',
                                  prefixIcon: Icons.auto_awesome_rounded,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField.multiline(
                                  controller: _descriptionController,
                                  label: 'About Community',
                                  hint: 'Describe your community mission...',
                                  prefixIcon: Icons.info_outline_rounded,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      CreateChatUIHelper.buildSectionHeader(context, 'Discovery & Standards'),
                      CreateChatUIHelper.buildContainer(
                        context: context,
                        children: [
                          CreateChatUIHelper.buildSettingsTile(
                            context,
                            icon: Icons.category_rounded,
                            label: 'Category',
                            subtitle: _selectedCategory?.categoryType ?? 'What is this community about?',
                            iconColor: Colors.orange,
                            onTap: _showCategoryPicker,
                            trailing: _selectedCategory != null 
                              ? Text(_selectedCategory!.icon, style: const TextStyle(fontSize: 18))
                              : null,
                          ),
                          CreateChatUIHelper.buildMenuDivider(context),
                          CreateChatUIHelper.buildSettingsTile(
                            context,
                            icon: Icons.gavel_rounded,
                            label: 'Community Rules',
                            subtitle: _rules.isEmpty ? 'Set expectations for members' : '${_rules.length} rules defined',
                            iconColor: Colors.indigo,
                            onTap: _openRulesEditor,
                          ),
                        ],
                      ),

                      CreateChatUIHelper.buildSectionHeader(context, 'Privacy & Access'),
                      CreateChatUIHelper.buildContainer(
                        context: context,
                        children: [
                          CreateChatUIHelper.buildSettingsTile(
                            context,
                            icon: _visibility == ChatVisibility.public ? Icons.public_rounded : Icons.lock_person_rounded,
                            label: 'Private Community',
                            subtitle: _visibility == ChatVisibility.public ? 'Anyone can find and see this' : 'Hidden from discovery, invite only',
                            iconColor: Colors.teal,
                            onTap: () {
                              setState(() {
                                _visibility = _visibility == ChatVisibility.public ? ChatVisibility.private : ChatVisibility.public;
                              });
                            },
                            trailing: Switch.adaptive(
                              value: _visibility == ChatVisibility.private,
                              onChanged: (v) => setState(() => _visibility = v ? ChatVisibility.private : ChatVisibility.public),
                            ),
                          ),
                          CreateChatUIHelper.buildMenuDivider(context),
                          CreateChatUIHelper.buildSettingsTile(
                            context,
                            icon: Icons.verified_user_rounded,
                            label: 'Admin Approval',
                            subtitle: 'Required for new members to join',
                            iconColor: Colors.blue,
                            onTap: () => setState(() => _requireApproval = !_requireApproval),
                            trailing: Switch.adaptive(
                              value: _requireApproval,
                              onChanged: (v) => setState(() => _requireApproval = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
        ),
        child: FilledButton.icon(
          onPressed: _isCreating ? null : _handleSave,
          icon: _isCreating 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(_isEditing ? Icons.check_rounded : Icons.rocket_launch_rounded),
          label: Text(_isEditing ? 'Update Community' : 'Launch Community'),
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Text(
        _isEditing ? 'Settings' : 'Create Community',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    
    return SizedBox(
      height: 220,
      width: size.width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner
          GestureDetector(
            onTap: () => _pickImage(isBanner: true),
            child: Container(
              height: 180,
              width: size.width,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                image: _bannerFile != null
                    ? DecorationImage(image: FileImage(_bannerFile!), fit: BoxFit.cover)
                    : _bannerPath != null
                        ? DecorationImage(image: NetworkImage(_bannerPath!), fit: BoxFit.cover)
                        : null,
              ),
              child: (_bannerFile == null && _bannerPath == null)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: colorScheme.primary, size: 28),
                          const SizedBox(height: 8),
                          const Text('Add Cover Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          // Avatar Overlay
          Positioned(
            left: 20,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickImage(isBanner: false),
              child: Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: _avatarFile != null
                        ? ClipOval(child: Image.file(_avatarFile!, fit: BoxFit.cover))
                        : _avatarPath != null
                            ? UserAvatarCached(imageUrl: _avatarPath, name: _nameController.text, size: 88)
                            : Center(child: Icon(Icons.stars_rounded, size: 44, color: colorScheme.primary)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
