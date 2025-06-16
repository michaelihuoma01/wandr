// lib/screens/circles/circles_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/circle_models.dart';
import '../../services/circle_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/circle_card.dart';
import 'create_circle_screen.dart';
import 'circle_detail_screen.dart';
import 'join_circle_dialog.dart';

class CirclesListScreen extends StatefulWidget {
  const CirclesListScreen({super.key});

  @override
  State<CirclesListScreen> createState() => _CirclesListScreenState();
}

class _CirclesListScreenState extends State<CirclesListScreen> 
    with SingleTickerProviderStateMixin {
  final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<VibeCircle> _myCircles = [];
  List<VibeCircle> _discoverCircles = [];
  List<SuggestedCircle> _suggestedCircles = [];
  
  bool _isLoadingMyCircles = true;
  bool _isLoadingDiscover = true;
  bool _isLoadingSuggestions = true;
  
  CircleCategory? _selectedCategory;
  List<String> _selectedVibes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyCircles(),
      _loadDiscoverCircles(),
      _loadSuggestions(),
    ]);
  }

  Future<void> _loadMyCircles() async {
    setState(() => _isLoadingMyCircles = true);
    
    try {
      final circles = await _circleService.getUserCircles();
      if (mounted) {
        setState(() {
          _myCircles = circles;
          _isLoadingMyCircles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMyCircles = false);
      }
    }
  }

  Future<void> _loadDiscoverCircles() async {
    setState(() => _isLoadingDiscover = true);
    
    try {
      final circles = await _circleService.discoverCircles(
        category: _selectedCategory,
        vibePreferences: _selectedVibes,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      if (mounted) {
        setState(() {
          _discoverCircles = circles;
          _isLoadingDiscover = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDiscover = false);
      }
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoadingSuggestions = true);
    
    try {
      final suggestions = await _circleService.getCircleSuggestions();
      if (mounted) {
        setState(() {
          _suggestedCircles = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  void _showJoinDialog(VibeCircle circle) {
    showDialog(
      context: context,
      builder: (context) => JoinCircleDialog(
        circle: circle,
        onJoined: () {
          _loadMyCircles();
          _navigateToCircle(circle);
        },
      ),
    );
  }

  void _navigateToCircle(VibeCircle circle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CircleDetailScreen(circleId: circle.id),
      ),
    ).then((_) => _loadMyCircles());
  }

  void _navigateToCreateCircle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCircleScreen(),
      ),
    ).then((created) {
      if (created == true) {
        _loadMyCircles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vibe Circles'),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Circles'),
            Tab(text: 'Discover'),
            Tab(text: 'For You'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCirclesTab(),
          _buildDiscoverTab(),
          _buildForYouTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateCircle,
              icon: const Icon(Icons.add),
              label: const Text('Create Circle'),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  Widget _buildMyCirclesTab() {
    if (_isLoadingMyCircles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCircles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.group_outlined,
        title: 'No Circles Yet',
        subtitle: 'Join or create a circle to start sharing your favorite places',
        actionLabel: 'Create Your First Circle',
        onAction: _navigateToCreateCircle,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyCircles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myCircles.length,
        itemBuilder: (context, index) {
          return CircleCard(
            circle: _myCircles[index],
            onTap: () => _navigateToCircle(_myCircles[index]),
            showJoinButton: false,
          );
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: _isLoadingDiscover
              ? const Center(child: CircularProgressIndicator())
              : _discoverCircles.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.search_off,
                      title: 'No Circles Found',
                      subtitle: 'Try adjusting your filters or search terms',
                      actionLabel: 'Clear Filters',
                      onAction: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedVibes = [];
                          _searchController.clear();
                          _searchQuery = '';
                        });
                        _loadDiscoverCircles();
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDiscoverCircles,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _discoverCircles.length,
                        itemBuilder: (context, index) {
                          final circle = _discoverCircles[index];
                          final isMember = _myCircles.any((c) => c.id == circle.id);
                          
                          return CircleCard(
                            circle: circle,
                            onTap: isMember 
                                ? () => _navigateToCircle(circle)
                                : () => _showJoinDialog(circle),
                            showJoinButton: !isMember,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildForYouTab() {
    if (_isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestedCircles.isEmpty) {
      return _buildEmptyState(
        icon: Icons.auto_awesome,
        title: 'No Suggestions Yet',
        subtitle: 'Check in to more places to get personalized circle recommendations',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestedCircles.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestedCircles[index];
          final isMember = _myCircles.any((c) => c.id == suggestion.circle.id);
          
          return _buildSuggestionCard(suggestion, isMember);
        },
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search circles...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _loadDiscoverCircles();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              if (value.isEmpty || value.length > 2) {
                _loadDiscoverCircles();
              }
            },
          ),
          const SizedBox(height: 12),
          // Category filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(null, 'All'),
                ...CircleCategory.values.map((category) => 
                  _buildCategoryChip(category, category.displayName)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CircleCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Text(category.emoji),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
          _loadDiscoverCircles();
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(SuggestedCircle suggestion, bool isMember) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: isMember 
            ? () => _navigateToCircle(suggestion.circle)
            : () => _showJoinDialog(suggestion.circle),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compatibility badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.1),
                      Colors.blue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      '${(suggestion.compatibilityScore * 100).toInt()}% Match',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Circle info
              Row(
                children: [
                  _buildCircleAvatar(suggestion.circle),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.circle.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion.circle.category.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMember)
                    ElevatedButton(
                      onPressed: () => _showJoinDialog(suggestion.circle),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Join'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Member',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Matching vibes
              if (suggestion.matchingVibes.isNotEmpty) ...[
                Text(
                  suggestion.reason ?? 'Matches your vibes:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: suggestion.matchingVibes.take(4).map((vibe) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vibe,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleAvatar(VibeCircle circle) {
    if (circle.imageUrl != null) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: CachedNetworkImageProvider(circle.imageUrl!),
      );
    }
    
    return CircleAvatar(
      radius: 30,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        circle.category.emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}