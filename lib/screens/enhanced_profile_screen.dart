import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/follow_service.dart';
import '../services/user_initialization_service.dart';
import '../services/visit_service.dart';
import '../services/board_service.dart';
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
  
  // Telescope-inspired color scheme
  static const Color telescopeBeige = Color(0xFFF4F3F0);
  static const Color telescopeBlue = Color(0xFF0671FF);
  static const Color telescopeYellow = Color(0xFFE3F794);
  static const Color telescopeCharcoal = Color(0xFF1A1915);
  static const Color telescopeLightGrey = Color(0xFFF8F7F4);

  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final FollowService _followService = FollowService();
  final UserInitializationService _initService = UserInitializationService();
  final VisitService _visitService = VisitService();
  final BoardService _boardService = BoardService();

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
  int _visitCount = 0;
  int _cityCount = 0;
  int _photoCount = 0;
  int _boardCount = 0;

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
    _tabController = TabController(length: 3, vsync: this);
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
          _user = await _createFallbackUser(targetUserId, userDoc);
        }
      } else {
        print('No user document found, creating fallback user');
        // Create a basic user profile if none exists
        _user = await _createFallbackUser(targetUserId, null);
      }

      // Load follow statistics
      _followStats = await _followService.getFollowStats(targetUserId);

      // Check if current user is following this profile
      if (!_isCurrentUser) {
        _isFollowing = await _followService.isFollowing(currentUser.uid, targetUserId);
      }

      // Load visit and board counts
      await _loadVisitStats(targetUserId);
      await _loadBoardCount(targetUserId);
    } catch (e) {
      print('Error loading profile data: $e');
      // Create a minimal fallback user even on error
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final targetUserId = widget.userId ?? currentUser.uid;
        _user = await _createFallbackUser(targetUserId, null);
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

  Future<void> _loadVisitStats(String userId) async {
    try {
      final visitStats = await _visitService.getVisitStats();
      final visits = await _visitService.getVisitHistory(limit: 1000).first;
      
      // Count unique cities
      final uniqueCities = <String>{};
      int photoCount = 0;
      
      for (final visit in visits) {
        if (visit.address != null && visit.address!.isNotEmpty) {
          // Extract city from address (this is a simplified approach)
          final addressParts = visit.address!.split(',');
          if (addressParts.isNotEmpty) {
            uniqueCities.add(addressParts.last.trim());
          }
        }
        
        // Count photos
        if (visit.photoUrls != null && visit.photoUrls!.isNotEmpty) {
          photoCount += visit.photoUrls!.length;
        }
      }
      
      setState(() {
        _visitCount = visitStats.totalVisits;
        _cityCount = uniqueCities.length;
        _photoCount = photoCount;
      });
    } catch (e) {
      print('Error loading visit stats: $e');
      setState(() {
        _visitCount = 0;
        _cityCount = 0;
        _photoCount = 0;
      });
    }
  }

  Future<void> _loadBoardCount(String userId) async {
    try {
      // Query boards created by this user
      final userBoards = await FirebaseFirestore.instance
          .collection('boards')
          .where('createdBy', isEqualTo: userId)
          .get();
      
      setState(() {
        _boardCount = userBoards.docs.length;
      });
    } catch (e) {
      print('Error loading board count: $e');
      setState(() {
        _boardCount = 0;
      });
    }
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

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                // Add share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                // Add report functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                // Add block functionality
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
      backgroundColor: telescopeBeige,
      appBar: !_isCurrentUser ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[800], size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _user != null ? Text(
          _user!.name,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ) : null,
        centerTitle: false,
        actions: [
          if (_user != null)
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onPressed: () => _showProfileOptions(),
            ),
        ],
      ) : null,
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
            expandedHeight: 250,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: telescopeLightGrey,
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
                indicatorColor: telescopeBlue,
                labelColor: telescopeBlue,
                unselectedLabelColor: telescopeCharcoal.withOpacity(0.6),
                tabs: const [
                  Tab(text: 'Profile'),
                  Tab(text: 'My Journey'),
                  Tab(text: 'Boards'),
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
          _buildProfileTab(),
          _buildMyJourneyTab(),
          _buildBoardsTab(),
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
            telescopeBlue.withOpacity(0.08),
            telescopeBeige,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildVibeAuraAvatar(),
              const SizedBox(height: 12),
              _buildUserInfo(),
              const SizedBox(height: 12),
              _buildStatsRow(),
              const SizedBox(height: 12),
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            _user?.name ?? 'Unknown User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            _user?.bio ?? 'Exploring the world, one vibe at a time ✨',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildClickableStatItem(
            'Places', 
            '$_visitCount',
            () {
              // Navigate to My Journey tab
              _tabController.animateTo(1);
            },
          ),
          _buildClickableStatItem(
            'Followers', 
            '${_followStats?.followersCount ?? 0}',
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Followers'),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                    body: FollowersTab(userId: widget.userId ?? _authService.currentUser!.uid),
                  ),
                ),
              );
            },
          ),
          _buildClickableStatItem(
            'Following', 
            '${_followStats?.followingCount ?? 0}',
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Following'),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                    body: FollowingTab(userId: widget.userId ?? _authService.currentUser!.uid),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClickableStatItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnhancedStatsRow(),
          const SizedBox(height: 20),
          _buildNextStopSection(),
          const SizedBox(height: 20),
          _buildVibeDNA(),
          const SizedBox(height: 20),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildMyJourneyTab() {
    return MyJourneyTab(userId: widget.userId ?? _authService.currentUser!.uid);
  }

  Widget _buildBoardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBoardsHeader(),
          const SizedBox(height: 16),
          _buildBoardsGrid(),
        ],
      ),
    );
  }

  int _getPlacesVisitedCount() {
    // This will be updated with real visit count from service
    return 0;
  }

  Widget _buildEnhancedStatsRow() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: telescopeLightGrey,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: telescopeCharcoal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTelescopeStatItem(
                'Places', 
                '$_visitCount',
                Icons.location_on_outlined,
                () {
                  _tabController.animateTo(1);
                },
              ),
              _buildTelescopeStatItem(
                'Following', 
                '${_followStats?.followingCount ?? 0}',
                Icons.people_outline,
                () => _navigateToFollowing(),
              ),
              _buildTelescopeStatItem(
                'Followers', 
                '${_followStats?.followersCount ?? 0}',
                Icons.favorite_outline,
                () => _navigateToFollowers(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: telescopeCharcoal.withOpacity(0.1), thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTelescopeStatItem(
                'Reviews', 
                '${_visitCount}', // Using visit count as reviews for now
                Icons.rate_review_outlined,
                () {},
              ),
              _buildTelescopeStatItem(
                'Ratings', 
                '4.2', // Mock rating
                Icons.star_outline,
                () {},
              ),
              _buildTelescopeStatItem(
                'Activity', 
                '${_calculateActivityScore()}',
                Icons.timeline_outlined,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelescopeStatItem(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: telescopeCharcoal.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: telescopeBlue,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: telescopeCharcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: telescopeCharcoal.withOpacity(0.6),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStopSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: telescopeCharcoal.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: telescopeYellow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bookmark_outline,
                    color: telescopeCharcoal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Stop',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: telescopeCharcoal,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Places you want to explore',
                        style: TextStyle(
                          fontSize: 14,
                          color: telescopeCharcoal.withOpacity(0.6),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full wishlist
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: telescopeBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5, // Mock data
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: telescopeLightGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: telescopeCharcoal.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              telescopeBlue.withOpacity(0.3),
                              telescopeYellow.withOpacity(0.3),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.place_outlined,
                            color: telescopeCharcoal,
                            size: 32,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Place ${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: telescopeCharcoal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: telescopeCharcoal.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: telescopeBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  color: telescopeBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: telescopeCharcoal,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mock activity items
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: telescopeLightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: telescopeBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visited a new place',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: telescopeCharcoal,
                          ),
                        ),
                        Text(
                          '2 hours ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: telescopeCharcoal.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Show full activity
            },
            child: Text(
              'View All Activity',
              style: TextStyle(
                color: telescopeBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: telescopeYellow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.dashboard_outlined,
            color: telescopeCharcoal,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Boards',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: telescopeCharcoal,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Curated collections of places',
                style: TextStyle(
                  fontSize: 14,
                  color: telescopeCharcoal.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Create new board
          },
          icon: Icon(
            Icons.add_circle_outline,
            color: telescopeBlue,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBoardsGrid() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('boards')
          .where('createdBy', isEqualTo: widget.userId ?? _authService.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return _buildBoardsError();
        }
        
        final boards = snapshot.data?.docs ?? [];
        
        if (boards.isEmpty) {
          return _buildBoardsEmpty();
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: boards.length,
          itemBuilder: (context, index) {
            final boardDoc = boards[index];
            final boardData = boardDoc.data() as Map<String, dynamic>;
            return _buildBoardCard(boardData);
          },
        );
      },
    );
  }

  Widget _buildBoardCard(Map<String, dynamic> boardData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: telescopeCharcoal.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  telescopeBlue.withOpacity(0.3),
                  telescopeYellow.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                if (boardData['coverPhotoUrl'] != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      boardData['coverPhotoUrl'],
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Center(
                    child: Icon(
                      Icons.dashboard,
                      color: telescopeCharcoal,
                      size: 32,
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showBoardOptions(boardData),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: telescopeCharcoal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boardData['name'] ?? 'Untitled Board',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: telescopeCharcoal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(boardData['places'] as List?)?.length ?? 0} places',
                    style: TextStyle(
                      fontSize: 12,
                      color: telescopeCharcoal.withOpacity(0.6),
                    ),
                  ),
                  if (boardData['circleId'] != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: telescopeBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Circle Board',
                        style: TextStyle(
                          fontSize: 10,
                          color: telescopeBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: telescopeCharcoal.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No boards yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: telescopeCharcoal.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first board to start curating places!',
            style: TextStyle(
              fontSize: 14,
              color: telescopeCharcoal.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create board
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Board'),
            style: ElevatedButton.styleFrom(
              backgroundColor: telescopeBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsError() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading boards',
            style: TextStyle(
              fontSize: 16,
              color: telescopeCharcoal.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _showBoardOptions(Map<String, dynamic> boardData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.share, color: telescopeBlue),
              title: const Text('Share Board'),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.recommend, color: telescopeBlue),
              title: const Text('Recommend to Friends'),
              onTap: () {
                Navigator.pop(context);
                // Implement recommend functionality
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: telescopeCharcoal),
              title: const Text('Edit Board'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit board
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToFollowing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Following'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: FollowingTab(userId: widget.userId ?? _authService.currentUser!.uid),
        ),
      ),
    );
  }

  void _navigateToFollowers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Followers'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: FollowersTab(userId: widget.userId ?? _authService.currentUser!.uid),
        ),
      ),
    );
  }

  int _calculateActivityScore() {
    // Simple activity calculation
    return (_visitCount * 2) + ((_followStats?.followersCount ?? 0) * 1) + (_boardCount * 3);
  }


  Widget _buildVibeDNA() {
    final primaryVibes = _user?.vibeProfile?.primaryVibes ?? [];
    
    // Add some default vibes if none exist
    final displayVibes = primaryVibes.isNotEmpty ? primaryVibes : ['social', 'aesthetic'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: telescopeCharcoal.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: telescopeBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: telescopeBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Vibe DNA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: telescopeCharcoal,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Your unique personality signature',
                      style: TextStyle(
                        fontSize: 14,
                        color: telescopeCharcoal.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: displayVibes.map((vibe) => _buildTelescopeVibeChip(vibe)).toList(),
          ),
          if (displayVibes.length < 3) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: telescopeLightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: telescopeCharcoal.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: telescopeBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete more check-ins to discover your unique vibe pattern!',
                      style: TextStyle(
                        color: telescopeCharcoal.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelescopeVibeChip(String vibe) {
    final colors = _getVibeColors(vibe);
    final icon = _getVibeIcon(vibe);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.first.withOpacity(0.1),
            colors.last.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.first.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.first.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: colors.first,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            vibe.capitalize(),
            style: TextStyle(
              color: colors.first,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVibeChip(String vibe) {
    final colors = _getVibeColors(vibe);
    final icon = _getVibeIcon(vibe);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.first, colors.last],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            vibe.capitalize(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVibeIcon(String vibe) {
    const vibeIconMap = {
      'cozy': Icons.home,
      'active': Icons.directions_run,
      'aesthetic': Icons.palette,
      'adventurous': Icons.explore,
      'luxurious': Icons.diamond,
      'social': Icons.people,
      'chill': Icons.self_improvement,
      'intimate': Icons.favorite,
      'trendy': Icons.trending_up,
      'romantic': Icons.favorite_border,
    };
    return vibeIconMap[vibe] ?? Icons.tag;
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
      color: _EnhancedProfileScreenState.telescopeLightGrey,
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