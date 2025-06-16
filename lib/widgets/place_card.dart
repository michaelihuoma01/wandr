// lib/widgets/place_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/widgets/check_in_dialog.dart';
import 'package:myapp/widgets/share_to_circle_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class PlaceCard extends StatelessWidget {
  final PlaceDetails place;
  final Position currentPosition;
  final String Function(String?) processImageUrl;

  const PlaceCard({
    super.key,
    required this.place,
    required this.currentPosition,
    required this.processImageUrl,
  });

  double get _distance => Geolocator.distanceBetween(
    currentPosition.latitude,
    currentPosition.longitude,
    place.latitude,
    place.longitude,
  ) / 1000; // Convert to km

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

  Future<void> _openDirections() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}';
    await _launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              _buildContentSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (place.imageUrls == null || place.imageUrls!.isEmpty) {
      return _buildPlaceholderImage();
    }

    return Stack(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: place.imageUrls!.length,
            itemBuilder: (context, index) {
              final imageUrl = processImageUrl(place.imageUrls![index]);
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('Image unavailable', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
        ),
        // Image indicators
        if (place.imageUrls!.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                place.imageUrls!.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(buildContext).primaryColor.withOpacity(0.7),
            Theme.of(buildContext).primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.place_outlined,
          size: 80,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildDescription(),
          const SizedBox(height: 16),
          _buildInfoChips(context),
          if (place.tags != null && place.tags!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTags(),
          ],
          const SizedBox(height: 20),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                place.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                place.type,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (place.dataSource != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              place.dataSource!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      place.description,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[700],
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInfoChips(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (place.rating != null)
          _buildChip(
            icon: Icons.star_rounded,
            label: place.rating!.toStringAsFixed(1),
            color: Colors.amber,
          ),
        if (place.priceLevel != null)
          _buildChip(
            label: place.priceLevel!,
            color: Colors.green,
          ),
        _buildChip(
          icon: Icons.near_me_rounded,
          label: '${_distance.toStringAsFixed(1)} km',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildChip({IconData? icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: icon != null ? Colors.black87 : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: place.tags!.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Text(
          tag,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      )).toList(),
    );
  }

Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Primary action buttons row
        Row(
          children: [
            // Check-in button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showCheckInDialog(context),
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('Check In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Share to circle button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showShareToCircleDialog(context),
                icon: const Icon(Icons.group, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Secondary action buttons row
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (place.websiteUrl != null)
              IconButton(
                onPressed: () => _launchUrl(place.websiteUrl!),
                icon: const Icon(Icons.language),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (place.phoneNumber != null)
              IconButton(
                onPressed: () => _makePhoneCall(place.phoneNumber!),
                icon: const Icon(Icons.phone),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

    void _showCheckInDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CheckInDialog(place: place),
    );
  }

      void _showShareToCircleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ShareToCircleDialog(place: place),
    );
  }

  BuildContext get buildContext => PlaceCardContext._context!;
}

// Helper class to pass context
class PlaceCardContext {
  static BuildContext? _context;
  static void setContext(BuildContext context) => _context = context;
}