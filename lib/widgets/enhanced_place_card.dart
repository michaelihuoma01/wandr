import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Using NetworkImage instead of cached_network_image
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../models/vibe_tag_models.dart';
import '../services/vibe_tag_service.dart';
import '../services/auth_service.dart';
import '../widgets/vibe_selection_widgets.dart';
import '../screens/discovery/visual_discovery_screen.dart';

// ============================================================================
// ENHANCED PLACE CARD WITH VIBE INTEGRATION
// ============================================================================

class EnhancedPlaceCard extends StatefulWidget {
  final PlaceDetails place;
  final Position currentPosition;
  final String Function(String?) processImageUrl;
  final VoidCallback? onVibesUpdated;
  final bool showVibeCompatibility;
  final bool allowVibeEditing;

  const EnhancedPlaceCard({
    super.key,
    required this.place,
    required this.currentPosition,
    required this.processImageUrl,
    this.onVibesUpdated,
    this.showVibeCompatibility = true,
    this.allowVibeEditing = true,
  });

  @override
  State<EnhancedPlaceCard> createState() => _EnhancedPlaceCardState();
}

class _EnhancedPlaceCardState extends State<EnhancedPlaceCard>
    with TickerProviderStateMixin {
  final VibeTagService _vibeTagService = VibeTagService();
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  
  late AnimationController _vibeAnimationController;
  late Animation<double> _vibeSlideAnimation;
  
  List<VibeTagAssociation> _placeVibes = [];
  VibeCompatibilityScore? _userCompatibility;
  bool _isLoadingVibes = true;
  bool _showVibeDetails = false;
  bool _isEditingVibes = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPlaceVibes();
  }

  @override
  void dispose() {
    _vibeAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _vibeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _vibeSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _vibeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadPlaceVibes() async {
    try {
      // Get existing vibe associations
      final vibeAssociations = await _vibeTagService.getEntityVibeAssociations(
        widget.place.placeId!,
        'place',
      );

      // If no vibes exist, auto-detect them
      if (vibeAssociations.isEmpty) {
        await _autoDetectVibes();
      } else {
        setState(() {
          _placeVibes = vibeAssociations;
        });
      }

      // Calculate user compatibility if enabled
      if (widget.showVibeCompatibility) {
        await _calculateUserCompatibility();
      }
    } catch (e) {
      print('Error loading place vibes: $e');
    } finally {
      setState(() => _isLoadingVibes = false);
    }
  }

  Future<void> _autoDetectVibes() async {
    try {
      // Prepare place data for auto-detection
      final placeData = {
        'name': widget.place.name,
        'description': widget.place.description,
        'types': [widget.place.type],
        'priceLevel': widget.place.priceLevel,
        'rating': widget.place.rating,
      };

      final detectedVibes = await _vibeTagService.autoDetectVibes(
        entityData: placeData,
        entityType: 'place',
      );

      if (detectedVibes.isNotEmpty) {
        // Associate detected vibes with the place
        await _vibeTagService.associateVibesWithEntity(
          entityId: widget.place.placeId!,
          entityType: 'place',
          vibeTagIds: detectedVibes,
          source: 'ai_detected',
          metadata: {
            'detection_timestamp': DateTime.now().toIso8601String(),
            'place_types': [widget.place.type],
          },
        );

        // Reload vibes
        final updatedVibes = await _vibeTagService.getEntityVibeAssociations(
          widget.place.placeId!,
          'place',
        );

        setState(() {
          _placeVibes = updatedVibes;
        });
      }
    } catch (e) {
      print('Error auto-detecting vibes: $e');
    }
  }

  Future<void> _calculateUserCompatibility() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final compatibility = await _vibeTagService.calculateVibeCompatibility(
        entityId1: currentUser.uid,
        entityType1: 'user',
        entityId2: widget.place.placeId!,
        entityType2: 'place',
      );

      setState(() {
        _userCompatibility = compatibility;
      });
    } catch (e) {
      print('Error calculating user compatibility: $e');
    }
  }

  void _toggleVibeDetails() {
    setState(() => _showVibeDetails = !_showVibeDetails);
    if (_showVibeDetails) {
      _vibeAnimationController.forward();
    } else {
      _vibeAnimationController.reverse();
    }
  }

  void _editVibes() {
    setState(() => _isEditingVibes = true);
    _showVibeEditDialog();
  }

  void _showVibeEditDialog() {
    final currentVibeIds = _placeVibes.map((v) => v.vibeTagId).toSet();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Vibes',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.place.name,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Vibe selection
            Expanded(
              child: VibeSelectionGrid(
                initialSelectedVibes: currentVibeIds,
                onSelectionChanged: (vibes) {
                  // Update immediately on change
                  _updatePlaceVibes(vibes);
                },
                maxSelections: 8,
                showSearch: true,
              ),
            ),
            
            // Save button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() => _isEditingVibes = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePlaceVibes(Set<String> newVibeIds) async {
    try {
      await _vibeTagService.associateVibesWithEntity(
        entityId: widget.place.placeId!,
        entityType: 'place',
        vibeTagIds: newVibeIds.toList(),
        source: 'user_edited',
        metadata: {
          'edit_timestamp': DateTime.now().toIso8601String(),
          'editor_id': _authService.currentUser?.uid,
        },
      );

      // Reload vibes
      final updatedVibes = await _vibeTagService.getEntityVibeAssociations(
        widget.place.placeId!,
        'place',
      );

      setState(() {
        _placeVibes = updatedVibes;
      });

      // Recalculate compatibility
      if (widget.showVibeCompatibility) {
        await _calculateUserCompatibility();
      }

      // Notify parent
      widget.onVibesUpdated?.call();
    } catch (e) {
      print('Error updating place vibes: $e');
    }
  }

  void _findSimilarVibes() {
    if (_placeVibes.isEmpty) return;
    
    final vibeIds = _placeVibes.map((v) => v.vibeTagId).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VisualDiscoveryScreen(
          initialVibes: vibeIds,
        ),
      ),
    );
  }

  double get _distance =>
      Geolocator.distanceBetween(
        widget.currentPosition.latitude,
        widget.currentPosition.longitude,
        widget.place.latitude,
        widget.place.longitude,
      ) / 1000; // Convert to km

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              _buildContentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (widget.place.imageUrls == null || widget.place.imageUrls!.isEmpty) {
      return _buildPlaceholderImage();
    }

    return Stack(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.place.imageUrls!.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.processImageUrl(widget.place.imageUrls![index]);
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
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
        
        // Vibe compatibility overlay (top right)
        if (_userCompatibility != null && _userCompatibility!.overallScore > 0.3)
          Positioned(
            top: 16,
            right: 16,
            child: _buildCompatibilityBadge(),
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
        if (widget.place.imageUrls!.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.place.imageUrls!.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompatibilityBadge() {
    final score = _userCompatibility!.overallScore;
    final percentage = (score * 100).round();
    
    Color badgeColor;
    String label;
    
    if (score >= 0.7) {
      badgeColor = Colors.green;
      label = 'Perfect Match';
    } else if (score >= 0.5) {
      badgeColor = Colors.orange;
      label = 'Good Match';
    } else {
      badgeColor = Colors.blue;
      label = 'Some Match';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
            Theme.of(context).primaryColor.withOpacity(0.7),
            Theme.of(context).primaryColor,
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

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildDescription(),
          const SizedBox(height: 16),
          _buildInfoChips(),
          const SizedBox(height: 16),
          _buildVibeSection(),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.place.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.place.type,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (widget.place.dataSource != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.place.dataSource!,
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
      widget.place.description,
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[700],
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInfoChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (widget.place.rating != null)
          _buildChip(
            icon: Icons.star_rounded,
            label: widget.place.rating!.toStringAsFixed(1),
            color: Colors.amber,
          ),
        if (widget.place.priceLevel != null && widget.place.priceLevel!.isNotEmpty)
          _buildChip(
            label: '\$' * int.parse(widget.place.priceLevel!),
            color: Colors.green,
          ),
        _buildChip(
          icon: Icons.near_me_rounded,
          label: '${_distance.toStringAsFixed(1)} km',
          color: Colors.blue,
        ),
        if (_userCompatibility != null && _userCompatibility!.overallScore > 0.3)
          _buildChip(
            icon: Icons.favorite,
            label: '${(_userCompatibility!.overallScore * 100).round()}% match',
            color: Colors.pink,
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

  Widget _buildVibeSection() {
    if (_isLoadingVibes) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vibe header
        Row(
          children: [
            Icon(
              Icons.psychology,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Vibes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            if (widget.allowVibeEditing)
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: _editVibes,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (_placeVibes.isNotEmpty)
              IconButton(
                icon: Icon(
                  _showVibeDetails ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onPressed: _toggleVibeDetails,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Vibe chips
        if (_placeVibes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_outlined, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  'No vibes detected yet',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (widget.allowVibeEditing)
                  TextButton(
                    onPressed: _editVibes,
                    child: const Text('Add vibes', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _placeVibes.take(_showVibeDetails ? _placeVibes.length : 4).map((association) {
              return FutureBuilder<List<VibeTag>>(
                future: _vibeTagService.getAllVibeTags(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final vibeTag = snapshot.data!.firstWhere(
                    (tag) => tag.id == association.vibeTagId,
                    orElse: () => VibeTag(
                      id: association.vibeTagId,
                      name: association.vibeTagId,
                      displayName: association.vibeTagId.capitalize(),
                      description: '',
                      category: 'general',
                      synonyms: [],
                      color: '#9E9E9E',
                      icon: 'tag',
                      popularity: 0.5,
                      contextWeights: {},
                      createdAt: DateTime.now(),
                      lastUsed: DateTime.now(),
                      usageCount: 0,
                    ),
                  );
                  
                  return VibeTagChip(
                    vibeTag: vibeTag,
                    isSelected: true,
                    onTap: () {},
                    size: 0.9,
                  );
                },
              );
            }).toList(),
          ),
        
        // Expanded vibe details
        if (_showVibeDetails && _placeVibes.isNotEmpty)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.3),
              end: Offset.zero,
            ).animate(_vibeSlideAnimation),
            child: FadeTransition(
              opacity: _vibeSlideAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    if (_userCompatibility != null && _userCompatibility!.sharedVibes.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Shared vibes: ${_userCompatibility!.sharedVibes.join(", ")}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _findSimilarVibes,
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text('Find similar vibes', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              side: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Primary action buttons row
        Row(
          children: [
            // Check-in button (main action)
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: () => _showCheckInDialog(),
                icon: const Icon(Icons.location_on, size: 20),
                label: const Text('Check In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Share button
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () => _showShareBottomSheet(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Secondary icon actions row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconAction(
              icon: Icons.directions_rounded,
              label: 'Directions',
              onTap: _openDirections,
              color: Colors.blue,
            ),
            if (widget.place.websiteUrl != null)
              _buildIconAction(
                icon: Icons.language_rounded,
                label: 'Website',
                onTap: () => _launchUrl(widget.place.websiteUrl!),
                color: Colors.green,
              ),
            if (widget.place.phoneNumber != null)
              _buildIconAction(
                icon: Icons.phone_rounded,
                label: 'Call',
                onTap: () => _makePhoneCall(widget.place.phoneNumber!),
                color: Colors.orange,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
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
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.place.latitude},${widget.place.longitude}';
    await _launchUrl(url);
  }

  void _showCheckInDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Center(
          child: Text(
            'Check-in feature coming soon!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }

  void _showShareBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        place: widget.place,
        onShareToCircle: () => _showShareToCircleDialog(),
        onSaveToBoard: () => _showSaveToVibeBoardDialog(),
      ),
    );
  }

  void _showShareToCircleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share to Circle'),
        content: Text('Share "${widget.place.name}" to a circle'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showSaveToVibeBoardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save to Board'),
        content: Text('Save "${widget.place.name}" to a vibe board'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARE BOTTOM SHEET (Enhanced version)
// ============================================================================

class ShareBottomSheet extends StatelessWidget {
  final PlaceDetails place;
  final VoidCallback onShareToCircle;
  final VoidCallback onSaveToBoard;

  const ShareBottomSheet({
    super.key,
    required this.place,
    required this.onShareToCircle,
    required this.onSaveToBoard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.share,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share Place',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            place.name,
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Share options
                Column(
                  children: [
                    _buildShareOption(
                      context: context,
                      icon: Icons.group,
                      title: 'Share to Circle',
                      subtitle: 'Share with your friend groups',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        onShareToCircle();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildShareOption(
                      context: context,
                      icon: Icons.bookmark,
                      title: 'Save to Board',
                      subtitle: 'Add to your personal collection',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        onSaveToBoard();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildShareOption(
                      context: context,
                      icon: Icons.link,
                      title: 'Copy Link',
                      subtitle: 'Share anywhere with a link',
                      color: Colors.green,
                      onTap: () async {
                        Navigator.pop(context);
                        final link = 'https://wandr.app/place/${place.placeId ?? 'unknown'}?lat=${place.latitude}&lng=${place.longitude}';
                        await Clipboard.setData(ClipboardData(text: link));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
}

// Extension helper
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}