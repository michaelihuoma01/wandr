// lib/widgets/emoji_reactions_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class EmojiReactionsWidget extends StatefulWidget {
  final String activityId;
  final String circleId;
  final Map<String, List<String>> reactions;
  final Function(String emoji) onReact;

  const EmojiReactionsWidget({
    super.key,
    required this.activityId,
    required this.circleId,
    required this.reactions,
    required this.onReact,
  });

  @override
  State<EmojiReactionsWidget> createState() => _EmojiReactionsWidgetState();
}

class _EmojiReactionsWidgetState extends State<EmojiReactionsWidget> {
  final AuthService _authService = AuthService();
  bool _showReactionPicker = false;
  
  static const List<String> availableEmojis = [
    '❤️', '👍', '😊', '😍', '🔥', '🎉', '😋', '🤩'
  ];

  String? _getUserReaction() {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return null;
    
    for (final entry in widget.reactions.entries) {
      if (entry.value.contains(userId)) {
        return entry.key;
      }
    }
    return null;
  }

  void _handleReaction(String emoji) {
    setState(() => _showReactionPicker = false);
    widget.onReact(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final userReaction = _getUserReaction();
    final hasReacted = userReaction != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reaction summary bar
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Show existing reactions
            ...widget.reactions.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) => _buildReactionChip(
                      emoji: entry.key,
                      count: entry.value.length,
                      isUserReaction: entry.key == userReaction,
                      context: context,
                    )),
            
            // Add reaction button
            InkWell(
              onTap: () {
                setState(() => _showReactionPicker = !_showReactionPicker);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasReacted ? Icons.emoji_emotions : Icons.add_reaction_outlined,
                      size: 20,
                      color: hasReacted ? Theme.of(context).primaryColor : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasReacted ? 'Change' : 'React',
                      style: TextStyle(
                        fontSize: 13,
                        color: hasReacted ? Theme.of(context).primaryColor : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Reaction picker
        if (_showReactionPicker) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: availableEmojis.map((emoji) {
                return InkWell(
                  onTap: () => _handleReaction(emoji),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReactionChip({
    required String emoji,
    required int count,
    required bool isUserReaction,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: () => _handleReaction(emoji),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isUserReaction 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUserReaction 
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 13,
                color: isUserReaction 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}