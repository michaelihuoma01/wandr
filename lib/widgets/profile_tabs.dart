import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../services/auth_service.dart';
import '../services/visit_service.dart';
import '../models/visit_models.dart';
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
// INSIGHTS TAB
// ============================================================================

class InsightsTab extends StatefulWidget {
  final String userId;

  const InsightsTab({super.key, required this.userId});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  final FollowService _followService = FollowService();
  FollowStats? _followStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _followService.getFollowStats(widget.userId);
      setState(() {
        _followStats = stats;
      });
    } catch (e) {
      print('Error loading insights: $e');
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSocialStats(),
          const SizedBox(height: 24),
          _buildVibeInsights(),
          const SizedBox(height: 24),
          _buildEngagementMetrics(),
        ],
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
                  'Mutual',
                  '${_followStats?.mutualFollowsCount ?? 0}',
                  Icons.favorite,
                ),
              ],
            ),
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

  Widget _buildVibeInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vibe Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your vibe compatibility analytics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '75% Average Compatibility',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
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
              'Engagement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Profile Views', '127', Icons.visibility),
            const SizedBox(height: 12),
            _buildMetricRow('Vibe Matches', '23', Icons.favorite),
            const SizedBox(height: 12),
            _buildMetricRow('Check-ins', '15', Icons.location_pin),
          ],
        ),
      ),
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