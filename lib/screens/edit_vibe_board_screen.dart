// lib/screens/circles/edit_vibe_board_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../models/circle_models.dart';
import '../../models/models.dart';
import '../../services/circle_service.dart';
import '../../services/search_service.dart';
import '../../services/location_service.dart';

class EditVibeBoardScreen extends StatefulWidget {
  final String circleId;
  final VibeBoard board;

  const EditVibeBoardScreen({
    super.key,
    required this.circleId,
    required this.board,
  });

  @override
  State<EditVibeBoardScreen> createState() => _EditVibeBoardScreenState();
}

class _EditVibeBoardScreenState extends State<EditVibeBoardScreen> {
  final CircleService _circleService = CircleService();
  final SearchService _searchService = SearchService();
  final LocationService _locationService = LocationService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  
  late List<BoardPlace> _places;
  late Set<String> _tags;
  
  List<PlaceDetails> _searchResults = [];
  bool _isSearching = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  
  Timer? _searchDebouncer;
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.board.title);
    _descriptionController = TextEditingController(text: widget.board.description);
    _places = List.from(widget.board.places);
    _tags = Set.from(widget.board.tags);
    
    _titleController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _tagController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebouncer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _lastSearchQuery = '';
      });
      return;
    }

    if (query == _lastSearchQuery) return;

    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        _searchPlaces(query);
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
      _lastSearchQuery = query;
    });

    try {
      final position = _locationService.currentPosition ?? 
                      await _locationService.getCurrentLocation() as Position;

      final result = await _searchService.searchPlaces(
        query: query,
        latitude: position?.latitude ?? 25.2048,
        longitude: position?.longitude ?? 55.2708,
        radiusKm: 20,
      );

      if (query == _lastSearchQuery && mounted) {
        setState(() {
          _searchResults = result.locations;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted && query == _lastSearchQuery) {
        setState(() => _isSearching = false);
      }
    }
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
        orderIndex: _places.length,
        vibes: [],
      );
      _places.add(boardPlace);
      _hasChanges = true;
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _removePlace(int index) {
    setState(() {
      _places.removeAt(index);
      _updateOrderIndices();
      _hasChanges = true;
    });
  }

  void _reorderPlaces(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final place = _places.removeAt(oldIndex);
      _places.insert(newIndex, place);
      _updateOrderIndices();
      _hasChanges = true;
    });
  }

  void _updateOrderIndices() {
    for (int i = 0; i < _places.length; i++) {
      _places[i] = BoardPlace(
        placeId: _places[i].placeId,
        placeName: _places[i].placeName,
        placeType: _places[i].placeType,
        latitude: _places[i].latitude,
        longitude: _places[i].longitude,
        customNote: _places[i].customNote,
        vibes: _places[i].vibes,
        imageUrl: _places[i].imageUrl,
        orderIndex: i,
      );
    }
  }

  void _editPlaceNote(int index) {
    final place = _places[index];
    final noteController = TextEditingController(text: place.customNote);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Add a note about this place',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _places[index] = BoardPlace(
                  placeId: place.placeId,
                  placeName: place.placeName,
                  placeType: place.placeType,
                  latitude: place.latitude,
                  longitude: place.longitude,
                  customNote: noteController.text.trim(),
                  vibes: place.vibes,
                  imageUrl: place.imageUrl,
                  orderIndex: place.orderIndex,
                );
                _hasChanges = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Board title cannot be empty')),
      );
      return;
    }

    if (_places.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Board must have at least one place')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Update board in Firestore
      await _circleService.firestore
          .collection('circles')
          .doc(widget.circleId)
          .collection('boards')
          .doc(widget.board.id)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'places': _places.map((p) => p.toJson()).toList(),
        'tags': _tags.toList(),
        'coverImageUrl': _places.firstWhere(
          (p) => p.imageUrl != null,
          orElse: () => _places.first,
        ).imageUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Board updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save changes: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board'),
        content: Text(
          'Are you sure you want to delete "${widget.board.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBoard();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBoard() async {
    try {
      await _circleService.firestore
          .collection('circles')
          .doc(widget.circleId)
          .collection('boards')
          .doc(widget.board.id)
          .delete();

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.pop(context, 'deleted');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Board deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete board: ${e.toString()}'),
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
        title: const Text('Edit Vibe Board'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
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
                            setState(() {
                              _tags.remove(tag);
                              _hasChanges = true;
                            });
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
                        '${_places.length} places',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Add new place search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search to add more places',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isSearching)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _lastSearchQuery = '';
                                      });
                                    },
                                  ),
                              ],
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: _onSearchChanged,
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
                          final isAdded = _places
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
                  
                  // Current places
                  const SizedBox(height: 20),
                  const Text(
                    'Current Places (drag to reorder)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _places.length,
                      onReorder: _reorderPlaces,
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Material(
                              elevation: 0,
                              color: Colors.transparent,
                              child: child,
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final place = _places[index];
                        return Card(
                          key: ValueKey('${place.placeId}_$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                            ),
                            title: Text(place.placeName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(place.placeType),
                                if (place.customNote != null && place.customNote!.isNotEmpty)
                                  Text(
                                    place.customNote!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            isThreeLine: place.customNote != null && place.customNote!.isNotEmpty,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.note_add, size: 20),
                                  onPressed: () => _editPlaceNote(index),
                                  tooltip: 'Edit note',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => _removePlace(index),
                                  tooltip: 'Remove',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Delete button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text(
                    'Delete Board',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}