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
import '../../widgets/members/member_picker_grid.dart';
import '../profile/member_picker_screen.dart';
import 'widgets/create_chat_ui_helper.dart';

class CreateGroupScreen extends StatefulWidget {
  final ChatModel? existingGroup;
  const CreateGroupScreen({super.key, this.existingGroup});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<ContactItem> _selectedMembers = [];
  bool _isCreating = false;
  File? _groupAvatarFile;
  String? _groupAvatarPath;

  bool get _isEditing => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.existingGroup != null) {
      _groupNameController.text = widget.existingGroup!.displayName;
      _descriptionController.text = widget.existingGroup!.description ?? '';
      _groupAvatarPath = widget.existingGroup!.avatar;
      
      // Load existing members if needed? 
      // Usually handled by a separate members load if there are many.
    }
  }

  Future<void> _pickGroupAvatar() async {
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
    setState(() => _groupAvatarFile = result.first);
    
    final uploadedPath = await UniversalMediaService().uploadAvatar(result.first);
    if (uploadedPath != null && mounted) {
      setState(() => _groupAvatarPath = uploadedPath);
    }
  }

  Future<void> _openMemberPicker() async {
    final result = await Navigator.push<List<ContactItem>>(
      context,
      MaterialPageRoute(
        builder: (context) => MemberPickerScreen(
          initialSelectedIds: _selectedMembers.map((m) => m.id).toList(),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedMembers.clear();
        _selectedMembers.addAll(result);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_groupNameController.text.trim().isEmpty) {
      AppSnackbar.error('Group name is required');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final provider = context.read<ChatProvider>();
      if (_isEditing) {
        await provider.updateChatInfo(
          chatId: widget.existingGroup!.id,
          name: _groupNameController.text.trim(),
          description: _descriptionController.text.trim(),
          avatar: _groupAvatarPath,
        );
        AppSnackbar.success('Group updated');
        if (mounted) context.pop();
      } else {
        final result = await provider.createGroupChat(
          name: _groupNameController.text.trim(),
          memberUserIds: _selectedMembers.map((m) => m.id).toList(),
          avatar: _groupAvatarPath,
          description: _descriptionController.text.trim(),
        );
        if (result.success) {
          AppSnackbar.success('Group created!');
          if (mounted) context.pop();
        } else {
          AppSnackbar.error('Failed to create group');
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context),
                  const SizedBox(height: 32),
                  
                  CreateChatUIHelper.buildSectionHeader(context, 'Group Details'),
                  CreateChatUIHelper.buildContainer(
                    context: context,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _groupNameController,
                              label: 'Group Name',
                              hint: 'e.g. Project X Team',
                              prefixIcon: Icons.groups_rounded,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField.multiline(
                              controller: _descriptionController,
                              label: 'Description',
                              hint: 'Goal of this group...',
                              prefixIcon: Icons.notes_rounded,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  CreateChatUIHelper.buildSectionHeader(context, 'Participants'),
                  CreateChatUIHelper.buildContainer(
                    context: context,
                    children: [
                      CreateChatUIHelper.buildSettingsTile(
                        context,
                        icon: Icons.person_add_rounded,
                        label: _isEditing ? 'Manage Members' : 'Add Members',
                        subtitle: _selectedMembers.isEmpty ? 'Invite friends to this group' : '${_selectedMembers.length} active selections',
                        iconColor: Colors.blue,
                        onTap: _openMemberPicker,
                      ),
                      if (_selectedMembers.isNotEmpty) ...[
                        CreateChatUIHelper.buildMenuDivider(context),
                        Container(
                          height: 110,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _selectedMembers.length,
                            itemBuilder: (context, index) {
                              final member = _selectedMembers[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        UserAvatarCached(
                                          imageUrl: member.avatar,
                                          name: member.name,
                                          size: 52,
                                        ),
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: GestureDetector(
                                            onTap: () => setState(() => _selectedMembers.removeAt(index)),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.error,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: colorScheme.surface, width: 2),
                                              ),
                                              child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        member.name.split(' ').first,
                                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 120),
                ],
              ),
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
            : Icon(_isEditing ? Icons.check_rounded : Icons.group_add_rounded),
          label: Text(_isEditing ? 'Save Changes' : 'Create Group'),
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
        _isEditing ? 'Edit Group' : 'New Group',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickGroupAvatar,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05), width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: _groupAvatarFile != null
                      ? ClipOval(child: Image.file(_groupAvatarFile!, fit: BoxFit.cover))
                      : _groupAvatarPath != null
                          ? UserAvatarCached(imageUrl: _groupAvatarPath, name: _groupNameController.text, size: 100)
                          : Center(child: Icon(Icons.groups_rounded, size: 48, color: colorScheme.primary)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.surface, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _groupNameController.text.isEmpty ? 'Set Group Photo' : _groupNameController.text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
