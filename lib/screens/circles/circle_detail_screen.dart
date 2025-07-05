// lib/screens/circles/circle_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:myapp/screens/create_vibe_board_screen.dart';
import 'package:myapp/screens/vibe_board_detail_screen.dart';
import 'package:myapp/widgets/vibe_board_card.dart';
import '../../models/circle_models.dart';
import '../../models/models.dart';
import '../../models/visit_models.dart';
import '../../services/circle_service.dart';
import '../../services/auth_service.dart';
import '../../services/visit_service.dart';
import '../../widgets/circle_activity_card.dart';
import '../../widgets/circle_member_card.dart';
import 'circle_members_screen.dart';
import 'circle_settings_screen.dart';

class CircleDetailScreen extends StatefulWidget {
  final String circleId;

  const CircleDetailScreen({
    super.key,
    required this.circleId,
  });

  @override
  State<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends State<CircleDetailScreen>
    with SingleTickerProviderStateMixin {
  final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  final VisitService _visitService = VisitService();

  late TabController _tabController;
  VibeCircle? _circle;
  CircleMembership? _myMembership;
  bool _isLoading = true;
  String? _errorMessage;

  // Tab data
  List<CircleActivity> _activities = [];
  List<VibeBoard> _boards = [];
  List<CircleMembership> _members = [];

   StreamSubscription<List<CircleActivity>>? _activitySubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCircleData();
    _listenToActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activitySubscription?.cancel();
    super.dispose();
  }

  void _listenToActivities() {
    _activitySubscription = _circleService
        .getCircleFeed(widget.circleId)
        .listen((activities) {
      if (mounted) {
        setState(() => _activities = activities);
      }
    });
  }

  Future<void> _loadCircleData() async {
    setState(() => _isLoading = true);

    try {
      // Load circle info
      final circleDoc = await _circleService.firestore
          .collection('circles')
          .doc(widget.circleId)
          .get();

      if (!circleDoc.exists) {
        setState(() {
          _errorMessage = 'Circle not found';
          _isLoading = false;
        });
        return;
      }

      _circle = VibeCircle.fromFirestore(circleDoc);

      // Check membership
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final memberDoc = await _circleService.firestore
            .collection('circles')
            .doc(widget.circleId)
            .collection('members')
            .doc(userId)
            .get();

        if (memberDoc.exists) {
          _myMembership = CircleMembership.fromFirestore(memberDoc);
        }
      }

      // Load initial data
      await Future.wait([
        _loadActivities(),
        _loadBoards(),
        _loadMembers(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading circle: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivities() async {
    // This would be a stream in real implementation
    // For now, using snapshot
    final snapshot = await _circleService.firestore
        .collection('circles')
        .doc(widget.circleId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();

    setState(() {
      _activities = snapshot.docs
          .map((doc) => CircleActivity.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }

  Future<void> _loadBoards() async {
    final boards = await _circleService.getCircleBoards(widget.circleId);
    setState(() => _boards = boards);
  }

  Future<void> _loadMembers() async {
    final members = await _circleService.getCircleMembers(widget.circleId);
    setState(() => _members = members);
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildShareSheet(),
    );
  }

  Widget _buildShareSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Share to Circle',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Icon(Icons.location_on, color: Colors.green[700]),
            ),
            title: const Text('Share Recent Check-in'),
            subtitle: const Text('Share your latest visit with the circle'),
            onTap: () {
              Navigator.pop(context);
              _shareRecentCheckIn();
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.dashboard, color: Colors.blue[700]),
            ),
            title: const Text('Create Vibe Board'),
            subtitle: const Text('Curate a collection of places'),
            onTap: () {
              Navigator.pop(context);
              _navigateToCreateBoard();
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple[100],
              child: Icon(Icons.rate_review, color: Colors.purple[700]),
            ),
            title: const Text('Write Micro Review'),
            subtitle: const Text('Quick thoughts on a recent place'),
            onTap: () {
              Navigator.pop(context);
              _showMicroReviewDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareRecentCheckIn() async {
    // Get user's most recent check-in
    final visits = await _visitService.getVisitHistory().first;
    if (visits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recent check-ins to share')),
      );
      return;
    }

    final recentVisit = visits.first;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Check-in'),
        content: Text(
          'Share your visit to ${recentVisit.placeName} with ${_circle?.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _circleService.shareCheckIn(
        circleId: widget.circleId,
        visit: recentVisit,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in shared!'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadActivities();
    }
  }

  void _navigateToCreateBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateVibeBoardScreen(circleId: widget.circleId),
      ),
    ).then((created) {
      if (created == true) {
        _loadBoards();
        _loadActivities();
      }
    });
  }

  void _showMicroReviewDialog() {
    // TODO: Implement micro review dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Micro reviews coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _circle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Circle not found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedTab(),
            _buildBoardsTab(),
            _buildMembersTab(),
            _buildPlacesTab(),
          ],
        ),
      ),
      floatingActionButton: _myMembership != null
          ? FloatingActionButton(
              onPressed: _showShareOptions,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            if (_circle!.imageUrl != null)
              CachedNetworkImage(
                imageUrl: _circle!.imageUrl!,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor,
                    ],
                  ),
                ),
              ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Circle info
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _circle!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _circle!.category.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _circle!.category.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        _circle!.isPublic ? Icons.public : Icons.lock,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _circle!.isPublic ? 'Public' : 'Private',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_circle!.memberCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_myMembership?.role == MemberRole.admin)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CircleSettingsScreen(
                    circle: _circle!,
                  ),
                ),
              ).then((_) => _loadCircleData());
            },
          ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'Boards'),
          Tab(text: 'Members'),
          Tab(text: 'Places'),
        ],
      ),
    );
  }

 Widget _buildFeedTab() {
    if (_activities.isEmpty) {
      return _buildEmptyState(
        icon: Icons.timeline,
        title: 'No Activity Yet',
        subtitle: 'Be the first to share something!',
        actionLabel: 'Share Something',
        onAction: _showShareOptions,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // The stream will automatically update
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return CircleActivityCard(
            activity: _activities[index],
            onActivityUpdate: () {
              // The stream will automatically update
            },
          );
        },
      ),
    );
  }


  Widget _buildBoardsTab() {
    if (_boards.isEmpty) {
      return _buildEmptyState(
        icon: Icons.dashboard_outlined,
        title: 'No Vibe Boards Yet',
        subtitle: 'Create curated collections of places',
        actionLabel: 'Create First Board',
        onAction: _navigateToCreateBoard,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBoards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          return  VibeBoardCard(
              board: _boards[index],
              circleId: widget.circleId,  // Add this line
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VibeBoardDetailScreen(
                      circleId: widget.circleId,
                      boardId: _boards[index].id,
                    ),
                  ),
                ).then((result) {
                  if (result == 'deleted') {
                    _loadBoards();
                  }
                });
              },
            );
        },
      ),
    );
  }

  Widget _buildMembersTab() {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        itemCount: _members.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header with member count and invite button
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_members.length} Members',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_circle!.allowMemberInvites || 
                      _myMembership?.role == MemberRole.admin)
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Show invite dialog
                      },
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text('Invite'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return CircleMemberCard(
            member: _members[index - 1],
            isCurrentUser: _members[index - 1].userId == _authService.currentUser?.uid,
            onTap: () {
              // TODO: Navigate to member profile
            },
          );
        },
      ),
    );
  }

  Widget _buildPlacesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.place_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Circle Places Coming Soon!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'See all places visited by circle members',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
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
            Icon(icon, size: 80, color: Colors.grey[300]),
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
            if (actionLabel != null && onAction != null && _myMembership != null) ...[
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