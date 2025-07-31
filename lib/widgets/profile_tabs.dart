import 'dart:async';
import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import '../services/vibe_tag_service.dart';
import '../models/visit_models.dart';
import '../models/vibe_tag_models.dart';
import '../widgets/visit_card.dart';
import '../widgets/visit_filter_sheet.dart';
import '../screens/visit_timeline_screen.dart';
import '../screens/visit_map_screen.dart';

enum ViewMode { list, grid }

// ============================================================================
// FOLLOWING TAB
// ============================================================================

class FollowingTab extends StatefulWidget {
  final String userId;

  const FollowingTab({super.key, required this.userId});

  @override
  State<FollowingTab> createState() => _FollowingTabState();
}

class _FollowingTabState extends State<FollowingTab> {
  final FollowService _followService = FollowService();
  List<FollowUser> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final following = await _followService.getFollowing(widget.userId);
      setState(() {
        _following = following;
      });
    } catch (e) {
      print('Error loading following: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_following.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _following.length,
        itemBuilder: (context, index) {
          return _buildFollowUserCard(_following[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Not following anyone yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover people with similar vibes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to discovery
            },
            child: const Text('Discover People'),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUserCard(FollowUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildUserAvatar(user),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (user.isVerified)
              Icon(
                Icons.verified,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildVibeCompatibility(user.vibeCompatibility),
            if (user.followedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Following since ${_formatTimeAgo(user.followedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to user profile
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => EnhancedProfileScreen(userId: user.userId),
          //   ),
          // );
        },
      ),
    );
  }

  Widget _buildUserAvatar(FollowUser user) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: user.profilePicture != null
          ? NetworkImage(user.profilePicture!)
          : null,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: user.profilePicture == null
          ? Text(
              user.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            )
          : null,
    );
  }

  Widget _buildVibeCompatibility(double compatibility) {
    final percentage = (compatibility * 100).round();
    Color color;
    String label;

    if (percentage >= 70) {
      color = Colors.green;
      label = 'High Vibe Match';
    } else if (percentage >= 40) {
      color = Colors.orange;
      label = 'Good Vibe Match';
    } else {
      color = Colors.grey;
      label = 'Some Common Vibes';
    }

    return Row(
      children: [
        Icon(Icons.favorite, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label ($percentage%)',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ============================================================================
// FOLLOWERS TAB
// ============================================================================

class FollowersTab extends StatefulWidget {
  final String userId;

  const FollowersTab({super.key, required this.userId});

  @override
  State<FollowersTab> createState() => _FollowersTabState();
}

class _FollowersTabState extends State<FollowersTab> {
  final FollowService _followService = FollowService();
  final AuthService _authService = AuthService();
  List<FollowUser> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final followers = await _followService.getFollowers(widget.userId);
      setState(() {
        _followers = followers;
      });
    } catch (e) {
      print('Error loading followers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_followers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          return _buildFollowerCard(_followers[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isCurrentUser = _authService.currentUser?.uid == widget.userId;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isCurrentUser ? 'No followers yet' : 'No followers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCurrentUser 
                ? 'Share your vibe to attract followers'
                : 'This user doesn\'t have any followers yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerCard(FollowUser follower) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildUserAvatar(follower),
        title: Row(
          children: [
            Expanded(
              child: Text(
                follower.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (follower.isVerified)
              Icon(
                Icons.verified,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildVibeCompatibility(follower.vibeCompatibility),
            if (follower.followedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Followed ${_formatTimeAgo(follower.followedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: _buildFollowButton(follower),
        onTap: () {
          // Navigate to user profile
        },
      ),
    );
  }

  Widget _buildUserAvatar(FollowUser user) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: user.profilePicture != null
          ? NetworkImage(user.profilePicture!)
          : null,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: user.profilePicture == null
          ? Text(
              user.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            )
          : null,
    );
  }

  Widget _buildFollowButton(FollowUser user) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null || currentUserId == user.userId) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _followService.isFollowing(currentUserId, user.userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        
        return OutlinedButton(
          onPressed: () async {
            try {
              if (isFollowing) {
                await _followService.unfollowUser(currentUserId, user.userId);
              } else {
                await _followService.followUser(currentUserId, user.userId);
              }
              setState(() {}); // Refresh to update button state
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey[100] : null,
            foregroundColor: isFollowing ? Colors.grey[700] : Theme.of(context).primaryColor,
            side: BorderSide(
              color: isFollowing ? Colors.grey[300]! : Theme.of(context).primaryColor,
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }

  Widget _buildVibeCompatibility(double compatibility) {
    final percentage = (compatibility * 100).round();
    Color color;
    String label;

    if (percentage >= 70) {
      color = Colors.green;
      label = 'High Vibe Match';
    } else if (percentage >= 40) {
      color = Colors.orange;
      label = 'Good Vibe Match';
    } else {
      color = Colors.grey;
      label = 'Some Common Vibes';
    }

    return Row(
      children: [
        Icon(Icons.favorite, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label ($percentage%)',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ============================================================================
// INSIGHTS TAB - COMPREHENSIVE VIBE ANALYTICS
// ============================================================================

class InsightsTab extends StatefulWidget {
  final String userId;

  const InsightsTab({super.key, required this.userId});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> 
    with TickerProviderStateMixin {
  final FollowService _followService = FollowService();
  final VibeTagService _vibeTagService = VibeTagService();
  final AuthService _authService = AuthService();
  
  late TabController _insightsTabController;
  
  FollowStats? _followStats;
  List<VibeTagAssociation> _userVibes = [];
  Map<String, int> _vibeUsageStats = {};
  Map<String, double> _compatibilityStats = {};
  List<VibeTag> _trendingVibes = [];
  Map<String, List<String>> _vibeRecommendations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _insightsTabController = TabController(length: 3, vsync: this);
    _loadInsights();
  }

  @override
  void dispose() {
    _insightsTabController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load parallel data
      final futures = await Future.wait([
        _followService.getFollowStats(widget.userId),
        _vibeTagService.getEntityVibeAssociations(widget.userId, 'user'),
        _loadVibeAnalytics(),
        _loadCompatibilityStats(),
        _loadTrendingVibes(),
        _loadVibeRecommendations(),
      ]);

      setState(() {
        _followStats = futures[0] as FollowStats?;
        _userVibes = futures[1] as List<VibeTagAssociation>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading insights: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, int>> _loadVibeAnalytics() async {
    try {
      // Get user's vibe usage patterns
      final analytics = await _vibeTagService.getVibeAnalytics(
        entityId: widget.userId,
        entityType: 'user',
        timeRange: 'month',
      );
      
      _vibeUsageStats = analytics;
      return analytics;
    } catch (e) {
      print('Error loading vibe analytics: $e');
      return {};
    }
  }

  Future<Map<String, double>> _loadCompatibilityStats() async {
    try {
      // Get compatibility statistics with other users
      final stats = await _vibeTagService.getCompatibilityAnalytics(
        userId: widget.userId,
        period: 'month',
      );
      
      _compatibilityStats = stats;
      return stats;
    } catch (e) {
      print('Error loading compatibility stats: $e');
      return {};
    }
  }

  Future<List<VibeTag>> _loadTrendingVibes() async {
    try {
      final allVibes = await _vibeTagService.getAllVibeTags();
      
      // Sort by trending score (popularity + recent usage)
      allVibes.sort((a, b) {
        final scoreA = a.popularity + (a.usageCount / 1000.0);
        final scoreB = b.popularity + (b.usageCount / 1000.0);
        return scoreB.compareTo(scoreA);
      });

      _trendingVibes = allVibes.take(10).toList();
      return _trendingVibes;
    } catch (e) {
      print('Error loading trending vibes: $e');
      return [];
    }
  }

  Future<Map<String, List<String>>> _loadVibeRecommendations() async {
    try {
      final recommendations = await _vibeTagService.getVibeRecommendations(
        userId: widget.userId,
        categories: ['explore', 'social', 'activities'],
      );
      
      _vibeRecommendations = recommendations;
      return recommendations;
    } catch (e) {
      print('Error loading vibe recommendations: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Tab navigation
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _insightsTabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Analytics'),
              Tab(text: 'Trends'),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _insightsTabController,
            children: [
              _buildOverviewTab(),
              _buildAnalyticsTab(),
              _buildTrendsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVibeScore(),
          const SizedBox(height: 16),
          _buildVibeDistribution(),
          const SizedBox(height: 16),
          _buildSocialStats(),
          const SizedBox(height: 16),
          _buildQuickInsights(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompatibilityAnalytics(),
          const SizedBox(height: 16),
          _buildVibeEvolutionChart(),
          const SizedBox(height: 16),
          _buildEngagementMetrics(),
          const SizedBox(height: 16),
          _buildVibePerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendingVibesWidget(),
          const SizedBox(height: 16),
          _buildVibeRecommendations(),
          const SizedBox(height: 16),
          _buildVibeComparisons(),
        ],
      ),
    );
  }

  Widget _buildVibeScore() {
    final vibeScore = _calculateVibeScore();
    final scoreColor = _getScoreColor(vibeScore);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vibe Score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your overall vibe compatibility and activity score',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scoreColor.withOpacity(0.2),
                    scoreColor.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: scoreColor,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  '$vibeScore',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeDistribution() {
    if (_userVibes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.psychology_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No vibes detected yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your vibe profile to see analytics',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vibe Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<VibeTag>>(
              future: _vibeTagService.getAllVibeTags(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                
                final allVibes = snapshot.data!;
                final userVibeMap = Map.fromEntries(
                  _userVibes.map((v) => MapEntry(v.vibeTagId, v.strength)),
                );
                
                return Column(
                  children: allVibes.where((vibe) => userVibeMap.containsKey(vibe.id)).map((vibe) {
                    final strength = userVibeMap[vibe.id] ?? 0.0;
                    final vibeColor = Color(int.parse(vibe.color.replaceFirst('#', '0xFF')));
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: vibeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  vibe.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${(strength * 100).round()}%',
                                style: TextStyle(
                                  color: vibeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: strength,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(vibeColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Followers',
                  '${_followStats?.followersCount ?? 0}',
                  Icons.people,
                ),
                _buildStatColumn(
                  'Following',
                  '${_followStats?.followingCount ?? 0}',
                  Icons.person_add,
                ),
                _buildStatColumn(
                  'Compatibility',
                  '${_getAverageCompatibility()}%',
                  Icons.favorite,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              icon: Icons.trending_up,
              title: 'Most Active Vibe',
              value: _getMostActiveVibe(),
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.psychology,
              title: 'Vibe Diversity',
              value: '${_userVibes.length} different vibes',
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              icon: Icons.people,
              title: 'Best Matches',
              value: '${_getHighCompatibilityCount()} high matches',
              color: Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityAnalytics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compatibility Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_getAverageCompatibility()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      'Average Compatibility',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on ${_compatibilityStats.length} connections',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeEvolutionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vibe Evolution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.purple.withOpacity(0.1),
                    Colors.pink.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_graph,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Growing More Social',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '+15% this month',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Profile Views', '${_calculateProfileViews()}', Icons.visibility),
            const SizedBox(height: 12),
            _buildMetricRow('Vibe Matches', '${_vibeUsageStats.length}', Icons.favorite),
            const SizedBox(height: 12),
            _buildMetricRow('Check-ins', '${_calculateCheckIns()}', Icons.location_pin),
            const SizedBox(height: 12),
            _buildMetricRow('Vibe Updates', '${_calculateVibeUpdates()}', Icons.psychology),
          ],
        ),
      ),
    );
  }

  Widget _buildVibePerformanceMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vibe Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    'Consistency',
                    '${_calculateVibeConsistency()}%',
                    Icons.timeline,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceCard(
                    'Diversity',
                    '${_userVibes.length}/15',
                    Icons.diversity_3,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    'Influence',
                    '${_calculateInfluenceScore()}',
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceCard(
                    'Growth',
                    '+${_calculateGrowthRate()}%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingVibesWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trending Vibes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingVibes.map((vibe) {
                final isUserVibe = _userVibes.any((uv) => uv.vibeTagId == vibe.id);
                final vibeColor = Color(int.parse(vibe.color.replaceFirst('#', '0xFF')));
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUserVibe ? vibeColor.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUserVibe ? vibeColor : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUserVibe)
                        Icon(Icons.check_circle, size: 12, color: vibeColor)
                      else
                        Icon(Icons.trending_up, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        vibe.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isUserVibe ? vibeColor : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeRecommendations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vibe Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_vibeRecommendations.isEmpty)
              Text(
                'Complete your vibe profile to get personalized recommendations',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...(_vibeRecommendations.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: entry.value.map((vibeId) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vibeId.replaceAll('_', ' ').toLowerCase(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeComparisons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'See how your vibes compare to the community',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            _buildComparisonItem('More Social', 85, 'than average user'),
            const SizedBox(height: 8),
            _buildComparisonItem('Highly Adventurous', 92, 'top 10% of users'),
            const SizedBox(height: 8),
            _buildComparisonItem('Moderately Aesthetic', 67, 'similar to most users'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, int percentage, String description) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 80 ? Colors.green : 
                  percentage >= 60 ? Colors.orange : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Calculation methods
  int _calculateVibeScore() {
    final vibeCount = _userVibes.length;
    final followersCount = _followStats?.followersCount ?? 0;
    final avgCompatibility = _getAverageCompatibility();
    
    return ((vibeCount * 5) + (followersCount * 2) + avgCompatibility).clamp(0, 100);
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.blue;
    return Colors.grey;
  }

  int _getAverageCompatibility() {
    if (_compatibilityStats.isEmpty) return 50;
    final sum = _compatibilityStats.values.fold(0.0, (a, b) => a + b);
    return (sum / _compatibilityStats.length * 100).round();
  }

  String _getMostActiveVibe() {
    if (_userVibes.isEmpty) return 'None yet';
    
    // Find the vibe with highest strength
    final topVibe = _userVibes.reduce((a, b) => 
      a.strength > b.strength ? a : b
    );
    
    return topVibe.vibeTagId.replaceAll('_', ' ').toLowerCase();
  }

  int _getHighCompatibilityCount() {
    return _compatibilityStats.values.where((score) => score > 0.7).length;
  }

  int _calculateProfileViews() {
    // Simulated calculation based on followers and activity
    final base = (_followStats?.followersCount ?? 0) * 3;
    final vibeBonus = _userVibes.length * 5;
    return base + vibeBonus + (DateTime.now().day * 2);
  }

  int _calculateCheckIns() {
    // Simulated based on vibe activity
    return _vibeUsageStats.values.fold(0, (sum, count) => sum + count);
  }

  int _calculateVibeUpdates() {
    return _userVibes.length + (_vibeUsageStats.length * 2);
  }

  int _calculateVibeConsistency() {
    if (_userVibes.isEmpty) return 0;
    
    final avgStrength = _userVibes.fold(0.0, (sum, vibe) => sum + vibe.strength) / _userVibes.length;
    return (avgStrength * 100).round();
  }

  int _calculateInfluenceScore() {
    final followers = _followStats?.followersCount ?? 0;
    final vibeCount = _userVibes.length;
    return ((followers * 0.5) + (vibeCount * 2)).round();
  }

  int _calculateGrowthRate() {
    // Simulated growth calculation
    return ((_userVibes.length * 3) + ((_followStats?.followersCount ?? 0) * 0.1)).round();
  }
}

// ============================================================================
// MY JOURNEY TAB
// ============================================================================

class MyJourneyTab extends StatefulWidget {
  final String userId;

  const MyJourneyTab({super.key, required this.userId});

  @override
  State<MyJourneyTab> createState() => _MyJourneyTabState();
}

class _MyJourneyTabState extends State<MyJourneyTab>
    with TickerProviderStateMixin {
  final VisitService _visitService = VisitService();
  late TabController _journeyTabController;
  
  VisitFilter _currentFilter = VisitFilter();
  ViewMode _viewMode = ViewMode.list;

  @override
  void initState() {
    super.initState();
    _journeyTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _journeyTabController.dispose();
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
    return Column(
      children: [
        // Header with controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Journey Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _viewMode == ViewMode.list ? Icons.grid_view : Icons.view_list,
                  size: 20,
                ),
                onPressed: _toggleViewMode,
                tooltip: 'Toggle view mode',
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, size: 20),
                    onPressed: _showFilterSheet,
                    tooltip: 'Filter visits',
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
          ),
        ),
        
        // Tab navigation
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _journeyTabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.list, size: 18), text: 'Visits'),
              Tab(icon: Icon(Icons.timeline, size: 18), text: 'Timeline'),
              Tab(icon: Icon(Icons.map, size: 18), text: 'Map'),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _journeyTabController,
            children: [
              _buildVisitsListView(),
              VisitTimelineScreen(filter: _currentFilter),
              VisitMapScreen(filter: _currentFilter),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVisitsListView() {
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading visits',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Filters active',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _currentFilter = VisitFilter();
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Clear',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No visits yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start exploring places to build your journey!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discovery/search
                DefaultTabController.of(context)?.animateTo(0); // Go to main search
              },
              icon: const Icon(Icons.explore, size: 20),
              label: const Text('Discover Places'),
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

  Widget _buildListLayout(List<PlaceVisit> visits) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VisitCard(
            visit: visits[index],
            onTap: () {
              // Handle visit tap - could navigate to place detail
            },
            onDelete: () {
              // Handle visit deletion
            },
          ),
        );
      },
    );
  }

  Widget _buildGridLayout(List<PlaceVisit> visits) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        return VisitCard(
          visit: visits[index],
          isGridView: true,
          onTap: () {
            // Handle visit tap
          },
          onDelete: () {
            // Handle visit deletion
          },
        );
      },
    );
  }
}