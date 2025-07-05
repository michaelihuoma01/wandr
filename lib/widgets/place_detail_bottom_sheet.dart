import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/services/search_service.dart';
import 'package:myapp/widgets/share_to_circle_dialog.dart';
import 'package:myapp/widgets/share_to_vibe_board_dialog.dart';

class PlaceDetailBottomSheet extends StatelessWidget {
  final PlaceDetails place;

  const PlaceDetailBottomSheet({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final searchService = SearchService();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // Hero Image
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          _buildHeroImage(searchService),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Rating
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        place.type,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (place.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.amber[200]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          place.rating!.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Description
                            Text(
                              place.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Tags
                            if (place.tags != null && place.tags!.isNotEmpty) ...[
                              Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final tag in place.tags!)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                            
                            // Reviews
                            if (place.reviewTexts != null && place.reviewTexts!.isNotEmpty) ...[
                              Text(
                                'Reviews',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final review in place.reviewTexts!.take(2))
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Text(
                                    review,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                            
                            // Contact Info
                            if (place.phoneNumber != null || place.websiteUrl != null) ...[
                              Text(
                                'Contact',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (place.phoneNumber != null)
                                _buildContactItem(
                                  icon: Icons.phone,
                                  label: 'Call',
                                  value: place.phoneNumber!,
                                  onTap: () => _makePhoneCall(place.phoneNumber!),
                                ),
                              if (place.websiteUrl != null)
                                _buildContactItem(
                                  icon: Icons.language,
                                  label: 'Website',
                                  value: place.websiteUrl!,
                                  onTap: () => _launchUrl(place.websiteUrl!),
                                ),
                              const SizedBox(height: 24),
                            ],
                            
                            const SizedBox(height: 80), // Space for buttons
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDirections(context),
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCheckInDialog(context),
                          icon: const Icon(Icons.location_on),
                          label: const Text('Check In'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => _showMoreOptions(context),
                          icon: const Icon(Icons.more_vert),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(SearchService searchService) {
    if (place.imageUrls != null && place.imageUrls!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: CachedNetworkImage(
          imageUrl: searchService.processImageUrl(place.imageUrls!.first),
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: double.infinity,
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildFallbackHeroImage(),
        ),
      );
    } else {
      return _buildFallbackHeroImage();
    }
  }

  Widget _buildFallbackHeroImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[400]!, Colors.grey[600]!],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Icon(
        Icons.place,
        size: 64,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}';
    await _launchUrl(url);
  }

  void _showCheckInDialog(BuildContext context) {
    // Simple check-in placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check In'),
        content: Text('Check in to ${place.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Checked in to ${place.name}!')),
              );
            },
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share to Circle'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => ShareToCircleDialog(place: place),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Save to Board'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => ShareToVibeBoardDialog(place: place),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Report Issue'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}