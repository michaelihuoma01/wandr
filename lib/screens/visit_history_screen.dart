// lib/screens/visit_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visit_models.dart';
import '../services/visit_service.dart';
import '../widgets/visit_card.dart';
import '../widgets/visit_filter_sheet.dart';
import 'visit_map_screen.dart';
import 'visit_timeline_screen.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> 
    with SingleTickerProviderStateMixin {
  final VisitService _visitService = VisitService();
  late TabController _tabController;
  
  VisitFilter _currentFilter = VisitFilter();
  ViewMode _viewMode = ViewMode.list;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VisitFilterSheet(
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
        },
      ),
    );
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Journey'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == ViewMode.list ? Icons.grid_view : Icons.view_list,
            ),
            onPressed: _toggleViewMode,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
              ),
              if (_currentFilter.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'List'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            Tab(icon: Icon(Icons.map), text: 'Map'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(),
          VisitTimelineScreen(filter: _currentFilter),
          VisitMapScreen(filter: _currentFilter),
        ],
      ),
      floatingActionButton: _buildStatsButton(),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        if (_currentFilter.hasActiveFilters) _buildActiveFilters(),
        Expanded(
          child: StreamBuilder<List<PlaceVisit>>(
            stream: _visitService.getVisitHistory(filter: _currentFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final visits = snapshot.data ?? [];

              if (visits.isEmpty) {
                return _buildEmptyState();
              }

              if (_viewMode == ViewMode.list) {
                return _buildListLayout(visits);
              } else {
                return _buildGridLayout(visits);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_currentFilter.categories.isNotEmpty)
            ..._currentFilter.categories.map((category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('${category.emoji} ${category.displayName}'),
                onDeleted: () {
                  setState(() {
                    final newCategories = Set<PlaceCategory>.from(_currentFilter.categories);
                    newCategories.remove(category);
                    _currentFilter = _currentFilter.copyWith(categories: newCategories);
                  });
                },
              ),
            )),
          if (_currentFilter.vibes.isNotEmpty)
            ..._currentFilter.vibes.map((vibeId) {
              final vibe = VibeConstants.getVibeById(vibeId);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('${vibe?.icon ?? ''} ${vibe?.name ?? vibeId}'),
                  onDeleted: () {
                    setState(() {
                      final newVibes = Set<String>.from(_currentFilter.vibes);
                      newVibes.remove(vibeId);
                      _currentFilter = _currentFilter.copyWith(vibes: newVibes);
                    });
                  },
                ),
              );
            }),
          if (_currentFilter.startDate != null || _currentFilter.endDate != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_getDateRangeText()),
                onDeleted: () {
                  setState(() {
                    _currentFilter = _currentFilter.copyWith(
                      startDate: null,
                      endDate: null,
                    );
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getDateRangeText() {
    final formatter = DateFormat('MMM d');
    if (_currentFilter.startDate != null && _currentFilter.endDate != null) {
      return '${formatter.format(_currentFilter.startDate!)} - ${formatter.format(_currentFilter.endDate!)}';
    } else if (_currentFilter.startDate != null) {
      return 'From ${formatter.format(_currentFilter.startDate!)}';
    } else if (_currentFilter.endDate != null) {
      return 'Until ${formatter.format(_currentFilter.endDate!)}';
    }
    return '';
  }

  Widget _buildListLayout(List<PlaceVisit> visits) {
    // Group visits by date
    final Map<String, List<PlaceVisit>> groupedVisits = {};
    
    for (final visit in visits) {
      final dateKey = DateFormat('MMMM d, yyyy').format(visit.visitTime);
      groupedVisits[dateKey] ??= [];
      groupedVisits[dateKey]!.add(visit);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: groupedVisits.length,
      itemBuilder: (context, index) {
        final dateKey = groupedVisits.keys.elementAt(index);
        final dayVisits = groupedVisits[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ...dayVisits.map((visit) => VisitCard(
              visit: visit,
              onTap: () => _showVisitDetails(visit),
              onDelete: () => _deleteVisit(visit),
            )),
          ],
        );
      },
    );
  }

  Widget _buildGridLayout(List<PlaceVisit> visits) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        return VisitCard(
          visit: visits[index],
          isGridView: true,
          onTap: () => _showVisitDetails(visits[index]),
          onDelete: () => _deleteVisit(visits[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            _currentFilter.hasActiveFilters 
              ? 'No visits match your filters'
              : 'No places visited yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentFilter.hasActiveFilters
              ? 'Try adjusting your filters'
              : 'Start exploring and check in to places!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          if (_currentFilter.hasActiveFilters) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentFilter = VisitFilter();
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsButton() {
    return FloatingActionButton.extended(
      onPressed: _showStats,
      icon: const Icon(Icons.analytics),
      label: const Text('Stats'),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  void _showVisitDetails(PlaceVisit visit) {
    // Navigate to visit details screen
    // TODO: Implement visit details screen
  }

  void _deleteVisit(PlaceVisit visit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visit'),
        content: Text('Remove "${visit.placeName}" from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _visitService.deleteVisit(visit.id);
    }
  }

  void _showStats() async {
    final stats = await _visitService.getVisitStats();
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => _buildStatsSheet(stats),
    );
  }

  Widget _buildStatsSheet(VisitStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journey Stats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Visits', stats.totalVisits.toString()),
              _buildStatItem('Unique Places', stats.uniquePlaces.toString()),
              _buildStatItem('Check-ins', stats.manualCheckIns.toString()),
            ],
          ),
          const SizedBox(height: 20),
          if (stats.categoryBreakdown.isNotEmpty) ...[
            Text(
              'Top Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...stats.categoryBreakdown.entries
                .take(3)
                .map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${entry.key.emoji} ${entry.key.displayName}'),
                      const Spacer(),
                      Text('${entry.value} visits'),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

enum ViewMode { list, grid }