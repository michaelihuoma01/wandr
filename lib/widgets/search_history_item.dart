// lib/widgets/search_history_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/search_service.dart';

class SearchHistoryItem extends StatelessWidget {
  final SearchHistory history;
  final VoidCallback onTap;

  const SearchHistoryItem({
    super.key,
    required this.history,
    required this.onTap,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(history.timestamp);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.history,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        history.query,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '$timeAgo • ${history.resultCount} results',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.north_west, size: 16),
      onTap: onTap,
    );
  }
}