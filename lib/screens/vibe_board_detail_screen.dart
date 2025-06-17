// lib/screens/circles/vibe_board_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/circle_models.dart';
import '../../models/models.dart';
import '../../services/circle_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/place_card.dart';
import 'edit_vibe_board_screen.dart';

class VibeBoardDetailScreen extends StatefulWidget {
  final String circleId;
  final String boardId;

  const VibeBoardDetailScreen({
    super.key,
    required this.circleId,
    required this.boardId,
  });

  @override
  State<VibeBoardDetailScreen> createState() => _VibeBoardDetailScreenState();
}

class _VibeBoardDetailScreenState extends State<VibeBoardDetailScreen> {
  final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  
  VibeBoard? _board;
  bool _isLoading = true;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _loadBoard();
  }

  Future<void> _loadBoard() async {
    setState(() => _isLoading = true);

    try {
      final boardDoc = await _circleService.firestore
          .collection('circles')
          .doc(widget.circleId)
          .collection('boards')
          .doc(widget.boardId)
          .get();

      if (!boardDoc.exists) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Board not found')),
          );
        }
        return;
      }

      final board = VibeBoard.fromJson({
        'id': boardDoc.id,
        ...boardDoc.data()!,
      });

      final currentUserId = _authService.currentUser?.uid;
      
      setState(() {
        _board = board;
        _isCreator = board.creatorId == currentUserId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading board: $e');
    }
  }

  void _navigateToEdit() {
    if (_board == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVibeBoardScreen(
          circleId: widget.circleId,
          board: _board!,
        ),
      ),
    ).then((result) {
      if (result == 'deleted') {
        Navigator.pop(context, 'deleted');
      } else if (result == true) {
        _loadBoard();
      }
    });
  }

  void _showPlaceDetails(BoardPlace place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlaceDetailsSheet(place),
    );
  }

  Widget _buildPlaceDetailsSheet(BoardPlace place) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place image
                    if (place.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: place.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Place name and type
                    Text(
                      place.placeName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.placeType,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    // Custom note
                    if (place.customNote != null && place.customNote!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note, size: 20, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Note from ${_board?.creatorName ?? 'Creator'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              place.customNote!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Vibes
                    if (place.vibes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Vibes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: place.vibes.map((vibe) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vibe,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    // Actions
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to place
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Show on map
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('View on Map'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_board == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Board not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App bar with cover image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _board!.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: _buildCoverImage(),
            ),
            actions: [
              if (_isCreator)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _navigateToEdit,
                ),
            ],
          ),
          
          // Board info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator and stats
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'By ${_board!.creatorName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (_board!.likeCount > 0) ...[
                        Icon(Icons.favorite, size: 16, color: Colors.red[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${_board!.likeCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.place, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${_board!.places.length} places',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Description
                  if (_board!.description != null && _board!.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _board!.description!,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                  
                  // Tags
                  if (_board!.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _board!.tags.map((tag) {
                        return Chip(
                          label: Text('#$tag'),
                          backgroundColor: Colors.grey[100],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 8),
          ),
          
          // Places list
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final place = _board!.places[index];
                  return _buildPlaceItem(place, index);
                },
                childCount: _board!.places.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Share board
        },
        icon: const Icon(Icons.share),
        label: const Text('Share Board'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildCoverImage() {
    // Create a collage from place images
    final imageUrls = _board!.places
        .where((place) => place.imageUrl != null && place.imageUrl!.isNotEmpty)
        .map((place) => place.imageUrl!)
        .take(4)
        .toList();

    if (imageUrls.isEmpty) {
      return Container(
        decoration: BoxDecoration(
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
            Icons.dashboard,
            size: 80,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    }

    if (imageUrls.length == 1) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrls[0],
            fit: BoxFit.cover,
          ),
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
        ],
      );
    }

    // Create grid for multiple images
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrls.length == 2)
          Row(
            children: imageUrls.map((url) => Expanded(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            )).toList(),
          )
        else if (imageUrls.length == 3)
          Column(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: imageUrls[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[1],
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[2],
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
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
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[3],
                        fit: BoxFit.cover,
                        height: double.infinity,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      ],
    );
  }

  Widget _buildPlaceItem(BoardPlace place, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          onTap: () => _showPlaceDetails(place),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Image
                if (place.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: place.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.place, color: Colors.grey),
                  ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.placeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.placeType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (place.customNote != null && place.customNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          place.customNote!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}