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
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await widget.onAddComment(text);
      _commentController.clear();
      _focusNode.unfocus();
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
        // Comments count
        if (hasComments) ...[
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _isExpanded 
                    ? 'Hide comments'
                    : 'View all ${widget.comments.length} comments',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Comments list
          ...displayedComments.map((comment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: comment.userPhotoUrl != null
                      ? CachedNetworkImageProvider(comment.userPhotoUrl!)
                      : null,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: comment.userPhotoUrl == null
                      ? Text(
                          comment.userName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: comment.userName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: comment.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(comment.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
        
        // Add comment field
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _commentController.text.trim().isEmpty
                    ? Colors.grey[300]
                    : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _submitComment,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            size: 20,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}