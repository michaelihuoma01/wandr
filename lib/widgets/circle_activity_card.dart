// lib/widgets/circle_activity_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/circle_service.dart';
import 'package:myapp/widgets/activity_comments.dart';
import 'package:myapp/widgets/emoji_reactions.dart';
import '../models/circle_models.dart';
import '../models/visit_models.dart';

class CircleActivityCard extends StatefulWidget {
  final CircleActivity activity;
   final VoidCallback? onActivityUpdate;

  const CircleActivityCard({
    super.key,
    required this.activity,
    this.onActivityUpdate,
  });

  @override
  State<CircleActivityCard> createState() => _CircleActivityCardState();
}

class _CircleActivityCardState extends State<CircleActivityCard> {
   final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  
  bool _isLiking = false;
  bool _isReacting = false;

  Future<void> _handleLike() async {
    if (_isLiking) return;
    
    setState(() => _isLiking = true);
    
    final success = await _circleService.toggleLike(
      circleId: widget.activity.circleId,
      activityId: widget.activity.id,
    );
    
    if (success && widget.onActivityUpdate != null) {
      widget.onActivityUpdate!();
    }
    
    setState(() => _isLiking = false);
  }

  Future<void> _handleReaction(String emoji) async {
    if (_isReacting) return;
    
    setState(() => _isReacting = true);
    
    final success = await _circleService.toggleReaction(
      circleId: widget.activity.circleId,
      activityId: widget.activity.id,
      emoji: emoji,
    );
    
    if (success && widget.onActivityUpdate != null) {
      widget.onActivityUpdate!();
    }
    
    setState(() => _isReacting = false);
  }

  Future<void> _handleComment(String text) async {
    final success = await _circleService.addComment(
      circleId: widget.activity.circleId,
      activityId: widget.activity.id,
      text: text,
    );
    
    if (success && widget.onActivityUpdate != null) {
      widget.onActivityUpdate!();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          // Content based on activity type
          _buildContent(context),

          // Footer with actions
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.activity.userPhotoUrl != null
                ? CachedNetworkImageProvider(widget.activity.userPhotoUrl!)
                : null,
            child: widget.activity.userPhotoUrl == null
                ? Text(
                    widget.activity.userName.isNotEmpty
                        ? widget.activity.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // User info and activity type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.activity.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      widget.activity.icon,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(widget.activity.timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // TODO: Show options menu
            },
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (widget.activity.type) {
      case ActivityType.checkIn:
        return _buildCheckInContent(context);
      case ActivityType.placeShared:
        return _buildPlaceSharedContent(context);
      case ActivityType.boardCreated:
        return _buildBoardCreatedContent(context);
      case ActivityType.microReview:
        return _buildMicroReviewContent(context);
      case ActivityType.memberJoined:
        return _buildMemberJoinedContent(context);
      case ActivityType.milestone:
        return _buildMilestoneContent(context);
    }
  }

  Widget _buildCheckInContent(BuildContext context) {
    final placeName = widget.activity.data['placeName'] ?? 'Unknown Place';
    final placeType = widget.activity.data['placeType'] ?? '';
    final vibes = List<String>.from(widget.activity.data['vibes'] ?? []);
    final note = widget.activity.data['note'];
    final rating = widget.activity.data['rating'] as int?;
    final photoUrls = List<String>.from(widget.activity.data['photoUrls'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Check-in message
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(text: 'Checked in at '),
                      TextSpan(
                        text: placeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (placeType.isNotEmpty)
                        TextSpan(
                          text: ' • $placeType',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Photos
        if (photoUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: photoUrls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photoUrls[index],
                      fit: BoxFit.cover,
                      width: 200,
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Note
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              note,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],

        // Rating
        if (rating != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 20,
                  color: Colors.amber,
                );
              }),
            ),
          ),
        ],

        // Vibes
        if (vibes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: vibes.map((vibeId) {
                final vibe = VibeConstants.getVibeById(vibeId);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${vibe?.icon ?? ''} ${vibe?.name ?? vibeId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPlaceSharedContent(BuildContext context) {
    final placeName = widget.activity.data['placeName'] ?? 'Unknown Place';
    final note = widget.activity.data['note'] ?? '';
    final imageUrl = widget.activity.data['imageUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.share_location, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(text: 'Shared '),
                      TextSpan(
                        text: placeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (imageUrl != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            ),
          ),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              note,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBoardCreatedContent(BuildContext context) {
    final boardTitle = widget.activity.data['boardTitle'] ?? 'Untitled Board';
    final placeCount = widget.activity.data['placeCount'] ?? 0;
    final coverImageUrl = widget.activity.data['coverImageUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.dashboard, color: Colors.purple[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(text: 'Created vibe board '),
                      TextSpan(
                        text: boardTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' with $placeCount places',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (coverImageUrl != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: coverImageUrl,
                fit: BoxFit.cover,
                height: 150,
                width: double.infinity,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMicroReviewContent(BuildContext context) {
    final placeName = widget.activity.data['placeName'] ?? 'Unknown Place';
    final quickTake = widget.activity.data['quickTake'] ?? '';
    final rating = widget.activity.data['rating'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.rate_review, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(text: 'Reviewed '),
                      TextSpan(
                        text: placeName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (rating != null)
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
            ],
          ),
        ),
        if (quickTake.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '"$quickTake"',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMemberJoinedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(Icons.person_add, color: Colors.green[600], size: 20),
          const SizedBox(width: 8),
          const Text('Joined the circle!'),
        ],
      ),
    );
  }

  Widget _buildMilestoneContent(BuildContext context) {
    final message = widget.activity.data['message'] ?? 'Circle milestone!';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(Icons.celebration, color: Colors.purple[600], size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

   Widget _buildFooter(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    final isLiked = widget.activity.likedBy.contains(currentUserId);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reactions and Like row
          Row(
            children: [
              // Like button
              InkWell(
                onTap: _isLiking ? null : _handleLike,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isLiked ? Colors.red : Colors.grey[600],
                      ),
                      if (widget.activity.likedBy.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${widget.activity.likedBy.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Emoji reactions
              Expanded(
                child: EmojiReactionsWidget(
                  activityId: widget.activity.id,
                  circleId: widget.activity.circleId,
                  reactions: widget.activity.reactions,
                  onReact: _handleReaction,
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Comments section
          ActivityCommentsWidget(
            activityId: widget.activity.id,
            circleId: widget.activity.circleId,
            comments: widget.activity.comments,
            onAddComment: _handleComment,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
