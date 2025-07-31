// lib/screens/circles/circles_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/circle_models.dart';
import '../../services/enhanced_circle_service.dart';
import '../../services/circle_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/circle_card.dart';
import 'circle_detail_screen.dart';
import 'create_circle_screen.dart';

class CirclesListScreen extends StatefulWidget {
  const CirclesListScreen({super.key});

  @override
  State<CirclesListScreen> createState() => _CirclesListScreenState();
}

class _CirclesListScreenState extends State<CirclesListScreen> 
    with TickerProviderStateMixin {
  final EnhancedCircleService _enhancedCircleService = EnhancedCircleService();
  final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<VibeCircle> _myCircles = [];
  List<Map<String, dynamic>> _suggestedCircles = [];
  List<VibeCircle> _allCircles = [];
  bool _isLoading = true;
  String _activeTab = 'my_circles';

  static const List<String> _tabs = ['my_circles', 'suggested', 'discover'];

  @override
  void initState() {
    super.initState();
    _setupController();
    _loadCircles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupController() {
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabs[_tabController.index];
        });
      }
    });
  }

  Future<void> _loadCircles() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Load all circle types in parallel
      final futures = await Future.wait([
        _circleService.getUserCircles(currentUser.uid),
        _enhancedCircleService.getVibeCompatibleCircles(currentUser.uid, limit: 15),
        _circleService.getPublicCircles(limit: 20),
      ]);

      setState(() {
        _myCircles = futures[0] as List<VibeCircle>;
        _suggestedCircles = futures[1] as List<Map<String, dynamic>>;
        _allCircles = futures[2] as List<VibeCircle>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading circles: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinCircle(String circleId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final result = await _circleService.joinCircle(circleId, currentUser.uid);
      
      if (result.success) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Successfully joined circle!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh circles
        _loadCircles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Failed to join circle'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join circle: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createCircle() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CreateCircleScreen(),
      ),
    );

    if (result == true) {
      _loadCircles(); // Refresh after creating
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[800], size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Circles',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createCircle,
            tooltip: 'Create Circle',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: 'My Circles (${_myCircles.length})'),
            Tab(text: 'Suggested (${_suggestedCircles.length})'),
            const Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCirclesTab(),
          _buildSuggestedTab(),
          _buildDiscoverTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCircle,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyCirclesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCircles.isEmpty) {
      return _buildEmptyMyCirclesState();
    }

    return RefreshIndicator(
      onRefresh: _loadCircles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myCircles.length,
        itemBuilder: (context, index) {
          final circle = _myCircles[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CircleCard(
              circle: circle,
              onTap: () => _navigateToCircleDetail(circle.id),
              showJoinButton: false, // Already a member
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestedTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggestedCircles.isEmpty) {
      return _buildEmptySuggestedState();
    }

    return RefreshIndicator(
      onRefresh: _loadCircles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestedCircles.length,
        itemBuilder: (context, index) {
          final circleData = _suggestedCircles[index];
          final circle = circleData['circle'] as VibeCircle;
          final compatibility = circleData['compatibility'] as double;
          final matchReasons = circleData['matchReasons'] as List<String>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSuggestedCircleCard(circle, compatibility, matchReasons),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allCircles.isEmpty) {
      return _buildEmptyDiscoverState();
    }

    return RefreshIndicator(
      onRefresh: _loadCircles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allCircles.length,
        itemBuilder: (context, index) {
          final circle = _allCircles[index];
          final isAlreadyMember = _myCircles.any((mc) => mc.id == circle.id);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CircleCard(
              circle: circle,
              onTap: () => _navigateToCircleDetail(circle.id),
              showJoinButton: !isAlreadyMember,
              onJoin: isAlreadyMember ? null : () => _joinCircle(circle.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestedCircleCard(VibeCircle circle, double compatibility, List<String> matchReasons) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _navigateToCircleDetail(circle.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Circle avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: circle.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              circle.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.group, color: Colors.white, size: 24),
                            ),
                          )
                        : const Icon(Icons.group, color: Colors.white, size: 24),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Circle info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          circle.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          circle.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Compatibility score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCompatibilityColor(compatibility).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(compatibility * 100).round()}% match',
                      style: TextStyle(
                        color: _getCompatibilityColor(compatibility),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Match reasons
              if (matchReasons.isNotEmpty) ...[
                Text(
                  'Why this matches:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: matchReasons.take(3).map((reason) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _navigateToCircleDetail(circle.id),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _joinCircle(circle.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Join Circle'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyMyCirclesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Circles Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first circle or join existing ones to connect with people who share your vibes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createCircle,
              icon: const Icon(Icons.add),
              label: const Text('Create Circle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySuggestedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Suggestions Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Complete your vibe profile to get personalized circle recommendations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDiscoverState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Public Circles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Be the first to create a public circle in your area',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createCircle,
              icon: const Icon(Icons.add),
              label: const Text('Create First Circle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCompatibilityColor(double compatibility) {
    if (compatibility >= 0.8) return Colors.green;
    if (compatibility >= 0.6) return Colors.orange;
    return Colors.grey;
  }

  void _navigateToCircleDetail(String circleId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CircleDetailScreen(circleId: circleId),
      ),
    );
  }
}