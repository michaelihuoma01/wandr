// lib/widgets/vibe_board_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/circle_models.dart';

class VibeBoardCard extends StatelessWidget {
  final VibeBoard board;
  final VoidCallback? onTap;

  const VibeBoardCard({
    super.key,
    required this.board,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image section
            _buildCoverSection(context),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and place count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          board.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place,
                              size: 14,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${board.places.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Description
                  if (board.description != null && board.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      board.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Tags
                  if (board.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: board.tags.take(4).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // Footer
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Creator info
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                board.creatorName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Stats
                      Row(
                        children: [
                          // Likes
                          if (board.likeCount > 0) ...[
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.red[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              board.likeCount.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          // Saves
                          if (board.saveCount > 0) ...[
                            Icon(
                              Icons.bookmark,
                              size: 16,
                              color: Colors.blue[400],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              board.saveCount.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverSection(BuildContext context) {
    if (board.places.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.6),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.dashboard,
            size: 60,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    }

    // Show grid of place images
    final imageUrls = board.places
        .where((place) => place.imageUrl != null)
        .map((place) => place.imageUrl!)
        .take(4)
        .toList();

    if (imageUrls.isEmpty) {
      // No images, show place names
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.6),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 40,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 12),
            Text(
              board.places.take(3).map((p) => p.placeName).join(' • '),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (board.places.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                '+${board.places.length - 3} more',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Show image grid
    if (imageUrls.length == 1) {
      return _buildSingleImage(imageUrls[0]);
    } else if (imageUrls.length == 2) {
      return _buildTwoImageGrid(imageUrls);
    } else if (imageUrls.length == 3) {
      return _buildThreeImageGrid(imageUrls);
    } else {
      return _buildFourImageGrid(imageUrls);
    }
  }

  Widget _buildSingleImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildTwoImageGrid(List<String> imageUrls) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 180,
        child: Row(
          children: imageUrls.map((url) => Expanded(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              height: double.infinity,
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildThreeImageGrid(List<String> imageUrls) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 180,
        child: Row(
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: imageUrls[0],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[2],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFourImageGrid(List<String> imageUrls) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 180,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[0],
                      fit: BoxFit.cover,
                      height: double.infinity,
                    ),
                  ),
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[1],
                      fit: BoxFit.cover,
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CachedNetworkImage(
                      imageUrl: imageUrls[2],
                      fit: BoxFit.cover,
                      height: double.infinity,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrls[3],
                          fit: BoxFit.cover,
                          height: double.infinity,
                        ),
                        if (board.places.length > 4)
                          Container(
                            color: Colors.black.withOpacity(0.6),
                            child: Center(
                              child: Text(
                                '+${board.places.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}