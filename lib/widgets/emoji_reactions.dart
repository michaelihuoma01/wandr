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
  
  static const List<Map<String, String>> availableReactions = [
    {'emoji': '❤️', 'name': 'Love'},
    {'emoji': '👍', 'name': 'Like'},
    {'emoji': '😂', 'name': 'Haha'},
    {'emoji': '😮', 'name': 'Wow'},
    {'emoji': '😢', 'name': 'Sad'},
    {'emoji': '🔥', 'name': 'Fire'},
    {'emoji': '🎉', 'name': 'Celebrate'},
    {'emoji': '😋', 'name': 'Yum'},
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

  int get _totalReactionCount {
    return widget.reactions.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    final userReaction = _getUserReaction();
    final hasReacted = userReaction != null;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Reaction summary
        if (_totalReactionCount > 0) ...[
          Wrap(
            spacing: 4,
            children: widget.reactions.entries
                .where((entry) => entry.value.isNotEmpty)
                .take(3)
                .map((entry) => Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16),
                    ))
                .toList(),
          ),
          const SizedBox(width: 4),
          Text(
            '$_totalReactionCount',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Add reaction button
        InkWell(
          onTap: () {
            setState(() => _showReactionPicker = !_showReactionPicker);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Icon(
              hasReacted ? Icons.emoji_emotions : Icons.add_reaction_outlined,
              size: 20,
              color: hasReacted ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
          ),
        ),
        
        // Reaction picker popup
        if (_showReactionPicker)
          Positioned(
            bottom: 30,
            left: 0,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: availableReactions.map((reaction) {
                    final isSelected = userReaction == reaction['emoji'];
                    return InkWell(
                      onTap: () => _handleReaction(reaction['emoji']!),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reaction['emoji']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reaction['name']!,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}