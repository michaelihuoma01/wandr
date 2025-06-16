// lib/widgets/circle_member_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/circle_models.dart';

class CircleMemberCard extends StatelessWidget {
  final CircleMembership member;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const CircleMemberCard({
    super.key,
    required this.member,
    this.isCurrentUser = false,
    this.onTap,
  });

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return 'Joined ${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Joined $months month${months > 1 ? 's' : ''} ago';
    } else {
      return 'Joined ${DateFormat('MMM yyyy').format(date)}';
    }
  }

  Color _getRoleBadgeColor(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return Colors.purple;
      case MemberRole.moderator:
        return Colors.blue;
      case MemberRole.member:
        return Colors.grey;
    }
  }

  Widget _buildContributionBadge(BuildContext context, {
    required IconData icon,
    required int count,
    required Color color,
    required String tooltip,
  }) {
    if (count == 0) return const SizedBox.shrink();

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          // Avatar
          CircleAvatar(
            radius: 25,
            backgroundImage: member.userPhotoUrl != null
                ? CachedNetworkImageProvider(member.userPhotoUrl!)
                : null,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: member.userPhotoUrl == null
                ? Text(
                    member.userName.isNotEmpty 
                        ? member.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          
          // Online indicator (if implemented)
          if (member.lastActivityAt != null &&
              DateTime.now().difference(member.lastActivityAt!).inMinutes < 5)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.userName + (isCurrentUser ? ' (You)' : ''),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Role badge
          if (member.role != MemberRole.member)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleBadgeColor(member.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRoleBadgeColor(member.role).withOpacity(0.3),
                ),
              ),
              child: Text(
                member.role.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: _getRoleBadgeColor(member.role),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            _formatJoinDate(member.joinedAt),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          
          // Contribution badges
          if (member.contributionScore > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildContributionBadge(
                  context,
                  icon: Icons.location_on,
                  count: member.checkInsShared,
                  color: Colors.green,
                  tooltip: '${member.checkInsShared} check-ins shared',
                ),
                _buildContributionBadge(
                  context,
                  icon: Icons.dashboard,
                  count: member.boardsCreated,
                  color: Colors.purple,
                  tooltip: '${member.boardsCreated} boards created',
                ),
                _buildContributionBadge(
                  context,
                  icon: Icons.rate_review,
                  count: member.reviewsWritten,
                  color: Colors.orange,
                  tooltip: '${member.reviewsWritten} reviews written',
                ),
              ],
            ),
          ],
          
          // Contribution score
          if (member.contributionScore >= 100) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Top Contributor',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: member.role == MemberRole.member 
          ? PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onSelected: (value) {
                // TODO: Handle member actions
              },
              itemBuilder: (context) => [
                if (!isCurrentUser) ...[
                  const PopupMenuItem(
                    value: 'message',
                    child: Row(
                      children: [
                        Icon(Icons.message, size: 20),
                        SizedBox(width: 12),
                        Text('Message'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view_places',
                    child: Row(
                      children: [
                        Icon(Icons.place, size: 20),
                        SizedBox(width: 12),
                        Text('View Places'),
                      ],
                    ),
                  ),
                ],
                if (isCurrentUser) ...[
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Leave Circle', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ],
            )
          : null,
      onTap: onTap,
    );
  }
}