import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/follow_service.dart';
import '../services/user_initialization_service.dart';
import '../models/models.dart';
import '../widgets/profile_tabs.dart';

class EnhancedProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's profile
  
  const EnhancedProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final FollowService _followService = FollowService();
  final UserInitializationService _initService = UserInitializationService();

  late TabController _tabController;
  late AnimationController _auraController;
  late AnimationController _pulseController;
  late Animation<double> _auraAnimation;
  late Animation<double> _pulseAnimation;

  EnhancedUser? _user;
  FollowStats? _followStats;
  bool _isLoading = true;
  bool _isCurrentUser = false;
  bool _isFollowing = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupTabs();
    _loadProfileData();
  }

  void _setupAnimations() {
    _auraController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _auraAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _auraController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _auraController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _setupTabs() {
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('No current user found');
        return;
      }

      final targetUserId = widget.userId ?? currentUser.uid;
      _isCurrentUser = targetUserId == currentUser.uid;

      print('Loading profile for user: $targetUserId');

      // Initialize user if needed (only for current user)
      if (_isCurrentUser) {
        await _initService.initializeUserIfNeeded();
      }

      // Load user profile with fallback
      final userDoc = await _userProfileService.getUserProfile(targetUserId);
      print('User doc data: $userDoc');
      
      if (userDoc != null) {
        try {
          // Convert Firestore data to compatible format
          final compatibleData = _convertFirestoreData({
            'id': targetUserId,
            ...userDoc,
          });
          _user = EnhancedUser.fromJson(compatibleData);
          print('Successfully created EnhancedUser');
        } catch (e) {
          print('Error creating EnhancedUser from data: $e');
          // Create a minimal user with fallback data
          _user = _createFallbackUser(targetUserId, userDoc);
        }
      } else {
        print('No user document found, creating fallback user');
        // Create a basic user profile if none exists
        _user = _createFallbackUser(targetUserId, null);
      }

      // Load follow statistics
      _followStats = await _followService.getFollowStats(targetUserId);

      // Check if current user is following this profile
      if (!_isCurrentUser) {
        _isFollowing = await _followService.isFollowing(currentUser.uid, targetUserId);
      }
    } catch (e) {
      print('Error loading profile data: $e');
      // Create a minimal fallback user even on error
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final targetUserId = widget.userId ?? currentUser.uid;
        _user = _createFallbackUser(targetUserId, null);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _convertFirestoreData(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is Timestamp) {
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        converted[key] = _convertFirestoreData(value);
      } else if (value is List) {
        converted[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertFirestoreData(item);
          } else if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    }
    
    return converted;
  }

  EnhancedUser _createFallbackUser(String userId, Map<String, dynamic>? userData) {
    final currentUser = _authService.currentUser;
    
    return EnhancedUser(
      id: userId,
      name: userData?['name'] ?? currentUser?.displayName ?? 'User',
      email: userData?['email'] ?? currentUser?.email ?? 'user@example.com',
      photoUrl: userData?['photoUrl'] ?? currentUser?.photoURL,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      vibeProfile: VibeProfile(
        primaryVibes: ['social', 'aesthetic'],
        vibeScores: {},
        vibeEvolution: [],
        contextualVibes: ContextualVibes(
          contextVibeMap: {},
          lastUpdated: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      ),
      tasteSignature: TasteSignature(
        venuePreferences: {},
        priceRangeAffinity: {},
        socialPreference: 0.7,
        discoveryQuotient: 0.5,
        timePatterns: {},
        lastCalculated: DateTime.now(),
      ),
      behavioralSignals: BehavioralSignals(
        vibeConsistencyScore: 0.5,
        explorationRadius: 0.6,
        influenceScore: 0.4,
        activityPatterns: {},
        lastCalculated: DateTime.now(),
      ),
      onboardingData: OnboardingData(
        completedSteps: ['completed'],
        quizResponses: {},
        initialMatches: [],
        onboardingVersion: '1.0',
        completionTimestamp: DateTime.now(),
        engagementScore: 0.8,
      ),
      privacySettings: PrivacySettings(),
      notificationPreferences: NotificationPreferences(),
      interests: [],
      vibeTitle: 'Exploring Wanderer',
      trustScore: 50,
      achievements: [],
      profileLastUpdated: DateTime.now(),
      appVersion: '1.0.0',
      bio: userData?['bio'],
      location: userData?['location'],
    );
  }

  Future<void> _toggleFollow() async {
    if (_isCurrentUser || _user == null) return;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      HapticFeedback.selectionClick();

      if (_isFollowing) {
        await _followService.unfollowUser(currentUser.uid, _user!.id);
      } else {
        await _followService.followUser(currentUser.uid, _user!.id);
      }

      setState(() {
        _isFollowing = !_isFollowing;
        if (_followStats != null) {
          _followStats = FollowStats(
            followersCount: _followStats!.followersCount + (_isFollowing ? 1 : -1),
            followingCount: _followStats!.followingCount,
            mutualFollowsCount: _followStats!.mutualFollowsCount,
          );
        }
      });
    } catch (e) {
      print('Error toggling follow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'} user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _auraController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Not Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load profile data. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _loadProfileData();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
            actions: [
              if (_isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    // Navigate to settings
                  },
                ),
            ],
          ),
          SliverPersistentHeader(
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).primaryColor,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'My Journey'),
                  Tab(text: 'Following'),
                  Tab(text: 'Followers'),
                  Tab(text: 'Insights'),
                ],
              ),
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMyJourneyTab(),
          _buildFollowingTab(),
          _buildFollowersTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildVibeAuraAvatar(),
              const SizedBox(height: 16),
              _buildUserInfo(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 16),
              if (!_isCurrentUser) _buildFollowButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibeAuraAvatar() {
    final primaryVibe = _user?.vibeProfile?.primaryVibes.isNotEmpty == true
        ? _user!.vibeProfile!.primaryVibes.first
        : 'social';

    final vibeColors = _getVibeColors(primaryVibe);

    return AnimatedBuilder(
      animation: _auraAnimation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: AuraPainter(
                    colors: vibeColors,
                    animationValue: _auraAnimation.value,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: vibeColors.first.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _user?.photoUrl != null
                          ? NetworkImage(_user!.photoUrl!)
                          : null,
                      backgroundColor: vibeColors.first.withOpacity(0.2),
                      child: _user?.photoUrl == null
                          ? Text(
                              _user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: vibeColors.first,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserInfo() {
    final vibeTitle = _user?.vibeTitle;
    
    return Column(
      children: [
        Text(
          _user?.name ?? 'Unknown User',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        if (vibeTitle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vibeTitle,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          _user?.bio ?? 'Exploring the world, one vibe at a time ✨',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Posts', '42'),
        _buildStatItem('Followers', '${_followStats?.followersCount ?? 0}'),
        _buildStatItem('Following', '${_followStats?.followingCount ?? 0}'),
        _buildStatItem('Vibe Score', '${_calculateVibeScore()}'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildFollowButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing
              ? Colors.grey[200]
              : Theme.of(context).primaryColor,
          foregroundColor: _isFollowing
              ? Colors.grey[700]
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          _isFollowing ? 'Following' : 'Follow',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVibeDNA(),
          const SizedBox(height: 24),
          _buildVibeEvolution(),
          const SizedBox(height: 24),
          _buildSocialActivity(),
          const SizedBox(height: 24),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildMyJourneyTab() {
    return MyJourneyTab(userId: widget.userId ?? _authService.currentUser!.uid);
  }

  Widget _buildFollowingTab() {
    return FollowingTab(userId: widget.userId ?? _authService.currentUser!.uid);
  }

  Widget _buildFollowersTab() {
    return FollowersTab(userId: widget.userId ?? _authService.currentUser!.uid);
  }

  Widget _buildInsightsTab() {
    return InsightsTab(userId: widget.userId ?? _authService.currentUser!.uid);
  }

  Widget _buildVibeDNA() {
    final primaryVibes = _user?.vibeProfile?.primaryVibes ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vibe DNA',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: primaryVibes.map((vibe) => _buildVibeChip(vibe)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVibeChip(String vibe) {
    final colors = _getVibeColors(vibe);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.first.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.first),
      ),
      child: Text(
        vibe.capitalize(),
        style: TextStyle(
          color: colors.first,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildVibeEvolution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  'Vibe Evolution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
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

  Widget _buildSocialActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Social Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              'New follower: Alex joined your vibe tribe',
              '2h ago',
              Icons.person_add,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildActivityItem(
              'High vibe match with Sarah found',
              '5h ago',
              Icons.favorite,
              Colors.pink,
            ),
            const SizedBox(height: 8),
            _buildActivityItem(
              'Checked in at trendy rooftop bar',
              '1d ago',
              Icons.location_pin,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'This Month',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Places\nVisited', '12', Icons.location_pin),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('New\nConnections', '8', Icons.people),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Vibe\nMatches', '15', Icons.favorite),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String text, String time, IconData icon, Color color) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Color> _getVibeColors(String vibe) {
    const vibeColorMap = {
      'cozy': [Color(0xFFD4A574), Color(0xFFE6B8A2)],
      'active': [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
      'aesthetic': [Color(0xFFE91E63), Color(0xFFFF8A80)],
      'adventurous': [Color(0xFF27AE60), Color(0xFF66BB6A)],
      'luxurious': [Color(0xFFAF7AC5), Color(0xFFBA68C8)],
      'social': [Color(0xFF3498DB), Color(0xFF42A5F5)],
      'chill': [Color(0xFF58D68D), Color(0xFF81C784)],
      'intimate': [Color(0xFFF1948A), Color(0xFFFFAB91)],
    };

    return vibeColorMap[vibe] ?? [Colors.grey, Colors.grey[300]!];
  }

  int _calculateVibeScore() {
    // Simple vibe score calculation
    final vibeCount = _user?.vibeProfile?.primaryVibes.length ?? 0;
    final followersCount = _followStats?.followersCount ?? 0;
    return (vibeCount * 10) + (followersCount * 2);
  }
}

// Custom painter for vibe aura effect
class AuraPainter extends CustomPainter {
  final List<Color> colors;
  final double animationValue;

  AuraPainter({
    required this.colors,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create gradient paint
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.first.withOpacity(0.3),
          colors.last.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw rotating aura
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue);
    canvas.translate(-center.dx, -center.dy);
    
    canvas.drawCircle(center, radius, paint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Tab bar delegate for sticky tabs
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }
}