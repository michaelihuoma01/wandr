// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../widgets/search_history_item.dart';

class HistoryScreen extends StatefulWidget {
  final Function(String) onSearchSelected;
  
  const HistoryScreen({
    super.key,
    required this.onSearchSelected,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SearchService _searchService = SearchService();
  List<SearchHistory> _searchHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _searchService.getSearchHistory();
    setState(() {
      _searchHistory = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all search history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _searchService.clearHistory();
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search History'),
        actions: [
          if (_searchHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchHistory.isEmpty
              ? _buildEmptyState()
              : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No search history',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your search history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        return SearchHistoryItem(
          history: _searchHistory[index],
          onTap: () => widget.onSearchSelected(_searchHistory[index].query),
        );
      },
    );
  }
}