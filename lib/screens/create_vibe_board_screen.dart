// lib/screens/circles/create_vibe_board_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/circle_models.dart';
import '../../models/models.dart';
import '../../services/circle_service.dart';
import '../../services/search_service.dart';
import '../../services/location_service.dart';

class CreateVibeBoardScreen extends StatefulWidget {
  final String circleId;

  const CreateVibeBoardScreen({
    super.key,
    required this.circleId,
  });

  @override
  State<CreateVibeBoardScreen> createState() => _CreateVibeBoardScreenState();
}

class _CreateVibeBoardScreenState extends State<CreateVibeBoardScreen> {
  final CircleService _circleService = CircleService();
  final SearchService _searchService = SearchService();
  final LocationService _locationService = LocationService();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _tagController = TextEditingController();
  
  final List<BoardPlace> _selectedPlaces = [];
  final Set<String> _tags = {};
  
  List<PlaceDetails> _searchResults = [];
  bool _isSearching = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final position = _locationService.currentPosition;
    if (position == null) {
      await _locationService.getCurrentLocation();
    }

    final result = await _searchService.searchPlaces(
      query: query,
      latitude: position?.latitude ?? 25.2048, // Default to Dubai
      longitude: position?.longitude ?? 55.2708,
      radiusKm: 20,
    );

    setState(() {
      _isSearching = false;
      _searchResults = result.locations;
    });
  }

  void _addPlace(PlaceDetails place) {
    setState(() {
      final boardPlace = BoardPlace(
        placeId: place.placeId ?? '',
        placeName: place.name,
        placeType: place.type,
        latitude: place.latitude,
        longitude: place.longitude,
        imageUrl: place.imageUrls?.isNotEmpty == true ? place.imageUrls!.first : null,
        orderIndex: _selectedPlaces.length,
      );
      _selectedPlaces.add(boardPlace);
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removePlace(int index) {
    setState(() {
      _selectedPlaces.removeAt(index);
      // Update order indices
      for (int i = 0; i < _selectedPlaces.length; i++) {
        _selectedPlaces[i] = BoardPlace(
          placeId: _selectedPlaces[i].placeId,
          placeName: _selectedPlaces[i].placeName,
          placeType: _selectedPlaces[i].placeType,
          latitude: _selectedPlaces[i].latitude,
          longitude: _selectedPlaces[i].longitude,
          customNote: _selectedPlaces[i].customNote,
          vibes: _selectedPlaces[i].vibes,
          imageUrl: _selectedPlaces[i].imageUrl,
          orderIndex: i,
        );
      }
    });
  }

  void _reorderPlaces(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final place = _selectedPlaces.removeAt(oldIndex);
      _selectedPlaces.insert(newIndex, place);
      
      // Update order indices
      for (int i = 0; i < _selectedPlaces.length; i++) {
        _selectedPlaces[i] = BoardPlace(
          placeId: _selectedPlaces[i].placeId,
          placeName: _selectedPlaces[i].placeName,
          placeType: _selectedPlaces[i].placeType,
          latitude: _selectedPlaces[i].latitude,
          longitude: _selectedPlaces[i].longitude,
          customNote: _selectedPlaces[i].customNote,
          vibes: _selectedPlaces[i].vibes,
          imageUrl: _selectedPlaces[i].imageUrl,
          orderIndex: i,
        );
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _createBoard() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a board title')),
      );
      return;
    }

    if (_selectedPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one place')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final boardId = await _circleService.createVibeBoard(
      circleId: widget.circleId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      places: _selectedPlaces,
      tags: _tags.toList(),
    );

    if (!mounted) return;

    setState(() => _isCreating = false);

    if (boardId != null) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vibe board created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create vibe board'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Vibe Board'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createBoard,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Board Title',
                      hintText: 'e.g., Best Brunch Spots in Dubai',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'What makes these places special?',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Tags section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: const InputDecoration(
                            hintText: 'Add a tag',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addTag,
                        icon: const Icon(Icons.add_circle),
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text('#$tag'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() => _tags.remove(tag));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Places section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Places',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_selectedPlaces.length} selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for places to add',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      if (value.length > 2) {
                        _searchPlaces(value);
                      }
                    },
                  ),
                  
                  // Search results
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          final isAdded = _selectedPlaces
                              .any((p) => p.placeId == place.placeId);
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              backgroundImage: place.imageUrls?.isNotEmpty == true
                                  ? CachedNetworkImageProvider(
                                      _searchService.processImageUrl(place.imageUrls!.first),
                                    )
                                  : null,
                              child: place.imageUrls?.isEmpty ?? true
                                  ? const Icon(Icons.place)
                                  : null,
                            ),
                            title: Text(place.name),
                            subtitle: Text(place.type),
                            trailing: isAdded
                                ? const Icon(Icons.check, color: Colors.green)
                                : const Icon(Icons.add),
                            onTap: isAdded ? null : () => _addPlace(place),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // Selected places
                  if (_selectedPlaces.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedPlaces.length,
                      onReorder: _reorderPlaces,
                      itemBuilder: (context, index) {
                        final place = _selectedPlaces[index];
                        return Card(
                          key: ValueKey(place.placeId),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle),
                            ),
                            title: Text(place.placeName),
                            subtitle: Text(place.placeType),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removePlace(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_location_alt,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Search and add places to your board',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}