// lib/widgets/visit_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/visit_models.dart';
import '../services/search_service.dart';

class VisitCard extends StatelessWidget {
  final PlaceVisit visit;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isGridView;

  const VisitCard({
    super.key,
    required this.visit,
    required this.onTap,
    required this.onDelete,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGridCard(context);
    }
    return _buildListCard(context);
  }

  Widget _buildListCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _buildThumbnail(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              visit.placeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!visit.isManualCheckIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Auto',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(visit.visitTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            PlaceCategory.fromString(visit.placeCategory).emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            visit.placeType,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (visit.vibes.isNotEmpty || visit.aiGeneratedVibe != null) ...[
                        const SizedBox(height: 8),
                        _buildVibes(context),
                      ],
                      if (visit.userNote != null && visit.userNote!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          visit.userNote!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGridThumbnail(context),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.placeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          PlaceCategory.fromString(visit.placeCategory).emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            visit.placeType,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(visit.visitTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (visit.vibes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildCompactVibes(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final imageUrl = visit.placeDetails?['imageUrls']?.isNotEmpty == true
        ? SearchService().processImageUrl(visit.placeDetails!['imageUrls'][0])
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        color: Colors.grey[200],
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderIcon(context),
              )
            : _buildPlaceholderIcon(context),
      ),
    );
  }

  Widget _buildGridThumbnail(BuildContext context) {
    final imageUrl = visit.placeDetails?['imageUrls']?.isNotEmpty == true
        ? SearchService().processImageUrl(visit.placeDetails!['imageUrls'][0])
        : null;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[200],
        child: Stack(
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderIcon(context),
              )
            else
              _buildPlaceholderIcon(context),
            if (!visit.isManualCheckIn)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
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

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withAlpha(26),
      child: Icon(
        Icons.place,
        size: 40,
        color: Theme.of(context).primaryColor.withAlpha(128),
      ),
    );
  }

  Widget _buildVibes(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visit.vibes.map((vibeId) {
          final vibe = VibeConstants.getVibeById(vibeId);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${vibe?.icon ?? ''} ${vibe?.name ?? vibeId}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
        if (visit.aiGeneratedVibe != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.withOpacity(0.1),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                const SizedBox(width: 4),
                Text(
                  visit.aiGeneratedVibe!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.purple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactVibes(BuildContext context) {
    final vibes = visit.vibes.take(2).map((vibeId) {
      final vibe = VibeConstants.getVibeById(vibeId);
      return vibe?.icon ?? '';
    }).join(' ');

    return Row(
      children: [
        Text(
          vibes,
          style: const TextStyle(fontSize: 16),
        ),
        if (visit.vibes.length > 2)
          Text(
            ' +${visit.vibes.length - 2}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Visit'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}