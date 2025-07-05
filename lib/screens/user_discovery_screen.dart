import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/follow_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_tabs.dart';
import 'enhanced_profile_screen.dart';

class UserDiscoveryScreen extends StatefulWidget {
  const UserDiscoveryScreen({super.key});

  @override
  State<UserDiscoveryScreen> createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends State<UserDiscoveryScreen>
    with TickerProviderStateMixin {
  final FollowService _followService = FollowService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<FollowUser> _discoveredUsers = [];
  List<SocialActivity> _socialFeed = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Load discovered users and social feed in parallel
      final futures = await Future.wait([
        _followService.discoverUsers(currentUser.uid),
        _followService.getSocialActivityFeed(currentUser.uid),
      ]);

      setState(() {
        _discoveredUsers = futures[0] as List<FollowUser>;
        _socialFeed = futures[1] as List<SocialActivity>;
      });
    } catch (e) {
      print('Error loading discovery data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<FollowUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _discoveredUsers;
    
    return _discoveredUsers.where((user) {
      return user.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for people...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
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
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: 'Discover People'),
                  Tab(text: 'Social Feed'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoveryTab(),
                _buildSocialFeedTab(),
              ],
            ),
    );
  }

  Widget _buildDiscoveryTab() {
    final users = _filteredUsers;

    if (users.isEmpty && !_isLoading) {
      return _buildEmptyDiscoveryState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _buildDiscoveryCard(users[index]);
        },
      ),
    );
  }

  Widget _buildSocialFeedTab() {
    if (_socialFeed.isEmpty && !_isLoading) {
      return _buildEmptySocialFeedState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _socialFeed.length,
        itemBuilder: (context, index) {
          return _buildSocialActivityCard(_socialFeed[index]);
        },
      ),
    );
  }

  Widget _buildEmptyDiscoveryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No one to discover yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your vibe profile to find people with similar interests',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySocialFeedState() {
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
            'Your social feed is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow people to see their activities and vibe updates',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard(FollowUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildUserAvatar(user),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
                      const SizedBox(height: 4),
                      _buildVibeCompatibility(user.vibeCompatibility),
                    ],
                  ),
                ),
                _buildFollowButton(user),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EnhancedProfileScreen(userId: user.userId),
                        ),
                      );
                    },
                    child: const Text('View Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialActivityCard(SocialActivity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundImage: activity.actorProfilePicture != null
              ? NetworkImage(activity.actorProfilePicture!)
              : null,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: activity.actorProfilePicture == null
              ? Text(
                  activity.actorName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : null,
        ),
        title: _buildActivityTitle(activity),
        subtitle: _buildActivitySubtitle(activity),
        trailing: _buildActivityIcon(activity.type),
        onTap: () {
          // Navigate to relevant screen based on activity type
          if (activity.type == 'follow') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EnhancedProfileScreen(userId: activity.actorId),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildUserAvatar(FollowUser user) {
    return CircleAvatar(
      radius: 30,
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
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildFollowButton(FollowUser user) {
    return FutureBuilder<bool>(
      future: _followService.isFollowing(_authService.currentUser!.uid, user.userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        
        return ElevatedButton(
          onPressed: () async {
            try {
              HapticFeedback.selectionClick();
              
              if (isFollowing) {
                await _followService.unfollowUser(_authService.currentUser!.uid, user.userId);
              } else {
                await _followService.followUser(_authService.currentUser!.uid, user.userId);
              }
              
              setState(() {}); // Refresh to update button state
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFollowing 
                        ? 'Unfollowed ${user.name}' 
                        : 'Following ${user.name}',
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey[200] : Theme.of(context).primaryColor,
            foregroundColor: isFollowing ? Colors.grey[700] : Colors.white,
          ),
          child: Text(isFollowing ? 'Following' : 'Follow'),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label ($percentage%)',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTitle(SocialActivity activity) {
    switch (activity.type) {
      case 'follow':
        final targetName = activity.data['targetName'] ?? 'someone';
        return RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: activity.actorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' started following '),
              TextSpan(
                text: targetName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      case 'check_in':
        final placeName = activity.data['placeName'] ?? 'a place';
        return RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: activity.actorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' checked in at '),
              TextSpan(
                text: placeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      case 'vibe_update':
        return RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                text: activity.actorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' updated their vibe profile'),
            ],
          ),
        );
      default:
        return Text(activity.actorName);
    }
  }

  Widget _buildActivitySubtitle(SocialActivity activity) {
    final timeAgo = _formatTimeAgo(activity.timestamp);
    return Text(
      timeAgo,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
  }

  Widget _buildActivityIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'follow':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'check_in':
        icon = Icons.location_pin;
        color = Colors.green;
        break;
      case 'vibe_update':
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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