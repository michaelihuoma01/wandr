// lib/widgets/activity_comments_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/circle_models.dart';
import '../services/auth_service.dart';
import '../services/circle_service.dart';

class ActivityCommentsWidget extends StatefulWidget {
  final String activityId;
  final String circleId;
  final List<ActivityComment> comments;
  final Function(String) onAddComment;

  const ActivityCommentsWidget({
    super.key,
    required this.activityId,
    required this.circleId,
    required this.comments,
    required this.onAddComment,
  });

  @override
  State<ActivityCommentsWidget> createState() => _ActivityCommentsWidgetState();
}

class _ActivityCommentsWidgetState extends State<ActivityCommentsWidget> {
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  bool _isExpanded = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await widget.onAddComment(_commentController.text.trim());
      _commentController.clear();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasComments = widget.comments.isNotEmpty;
    final displayedComments = _isExpanded 
        ? widget.comments 
        : widget.comments.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments section
        if (hasComments) ...[
          ...displayedComments.map((comment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Text(
                    comment.userName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(comment.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          
          // View more comments button
          if (widget.comments.length > 2 && !_isExpanded) ...[
            InkWell(
              onTap: () => setState(() => _isExpanded = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'View ${widget.comments.length - 2} more comment${widget.comments.length - 2 > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          
          if (_isExpanded && widget.comments.length > 2) ...[
            InkWell(
              onTap: () => setState(() => _isExpanded = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Show less',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
        
        // Add comment field
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: _authService.currentUser?.photoURL != null
                  ? CachedNetworkImageProvider(_authService.currentUser!.photoURL!)
                  : null,
              child: _authService.currentUser?.photoURL == null
                  ? Text(
                      (_authService.currentUser?.displayName?[0] ?? 'U').toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  isDense: true,
                  suffixIcon: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: _submitComment,
                        ),
                ),
                style: const TextStyle(fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}