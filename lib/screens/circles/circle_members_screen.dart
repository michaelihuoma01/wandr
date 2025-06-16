// lib/screens/circles/circle_members_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/circle_models.dart';
import '../../services/circle_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/circle_member_card.dart';

class CircleMembersScreen extends StatefulWidget {
  final String circleId;
  final CircleMembership? currentUserMembership;

  const CircleMembersScreen({
    super.key,
    required this.circleId,
    this.currentUserMembership,
  });

  @override
  State<CircleMembersScreen> createState() => _CircleMembersScreenState();
}

class _CircleMembersScreenState extends State<CircleMembersScreen> {
  final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  
  List<CircleMembership> _members = [];
  List<Map<String, dynamic>> _joinRequests = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load members
      final members = await _circleService.getCircleMembers(widget.circleId);
      
      // Load join requests if admin
      List<Map<String, dynamic>> joinRequests = [];
      if (widget.currentUserMembership?.role == MemberRole.admin) {
        final requestsSnapshot = await _circleService.firestore
            .collection('circles')
            .doc(widget.circleId)
            .collection('joinRequests')
            .where('status', isEqualTo: 'pending')
            .get();
        
        joinRequests = requestsSnapshot.docs
            .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
            .toList();
      }

      setState(() {
        _members = members;
        _joinRequests = joinRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<CircleMembership> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    
    final query = _searchQuery.toLowerCase();
    return _members.where((member) {
      return member.userName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _handleJoinRequest(String userId, bool approve) async {
    try {
      if (approve) {
        // Add member to circle
        await _circleService.addMemberToCircle(widget.circleId, userId);
      }
      
      // Update request status
      await _circleService.firestore
          .collection('circles')
          .doc(widget.circleId)
          .collection('joinRequests')
          .doc(userId)
          .update({
        'status': approve ? 'approved' : 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': _authService.currentUser?.uid,
      });

      // Reload data
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Member approved' : 'Request rejected'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInviteDialog() {
    final circle = _circleService.firestore
        .collection('circles')
        .doc(widget.circleId)
        .get();
    
    circle.then((doc) {
      final data = doc.data();
      final inviteCode = data?['inviteCode'];
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invite Members'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inviteCode != null) ...[
                const Text('Share this invite code:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text('Generate an invite link to share'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement invite link generation
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite links coming soon!'),
                      ),
                    );
                  },
                  child: const Text('Generate Link'),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Join requests section
          if (_joinRequests.isNotEmpty) ...[
            Container(
              color: Colors.orange[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Join Requests (${_joinRequests.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._joinRequests.map((request) => _buildJoinRequestCard(request)),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Members list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _filteredMembers.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filteredMembers.length} Members',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Sort dropdown
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.sort),
                            onSelected: (value) {
                              // TODO: Implement sorting
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'contribution',
                                child: Text('By Contribution'),
                              ),
                              const PopupMenuItem(
                                value: 'joined',
                                child: Text('Recently Joined'),
                              ),
                              const PopupMenuItem(
                                value: 'name',
                                child: Text('By Name'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  final member = _filteredMembers[index - 1];
                  return CircleMemberCard(
                    member: member,
                    isCurrentUser: member.userId == _authService.currentUser?.uid,
                    onTap: () => _showMemberOptions(member),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: request['userPhotoUrl'] != null
              ? NetworkImage(request['userPhotoUrl'])
              : null,
          child: request['userPhotoUrl'] == null
              ? Text(request['userName']?[0] ?? '?')
              : null,
        ),
        title: Text(request['userName'] ?? 'Unknown'),
        subtitle: Text(
          'Requested ${_formatTime(request['requestedAt']?.toDate())}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _handleJoinRequest(request['id'], true),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _handleJoinRequest(request['id'], false),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberOptions(CircleMembership member) {
    if (member.userId == _authService.currentUser?.uid) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement messaging
              },
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('View Places'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show member's places
              },
            ),
            if (widget.currentUserMembership?.role == MemberRole.admin &&
                member.role == MemberRole.member) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Make Moderator'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement role change
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text(
                  'Remove from Circle',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement member removal
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}