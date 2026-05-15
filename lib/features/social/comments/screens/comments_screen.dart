import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/comment_section.dart';
import '../providers/comment_provider.dart';

class CommentsScreen extends StatefulWidget {
  final String targetType; // 'post' or 'story' or 'reel'
  final String targetId;
  final String currentUserId;

  const CommentsScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.currentUserId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  bool _isPostAuthor = false;

  @override
  void initState() {
    super.initState();
    _checkIfPostAuthor();
  }

  Future<void> _checkIfPostAuthor() async {
    // You can get this from your post provider or pass it directly
    // For now, assume false - will be enhanced when integrated
    setState(() {
      _isPostAuthor = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentProvider(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CommentSection(
          postId: widget.targetId,
          currentUserId: widget.currentUserId,
          isPostAuthor: _isPostAuthor,
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
