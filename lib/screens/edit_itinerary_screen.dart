import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/services/board_service.dart';
import 'package:myapp/services/search_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/widgets/place_card.dart';

class EditItineraryScreen extends StatefulWidget {
  final VibeList vibeList;

  const EditItineraryScreen({super.key, required this.vibeList});

  @override
  State<EditItineraryScreen> createState() => _EditItineraryScreenState();
}

class _EditItineraryScreenState extends State<EditItineraryScreen> {
  final BoardService _boardService = BoardService();
  final SearchService _searchService = SearchService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  
  List<EditableItineraryStop> _editableStops = [];
  File? _selectedCoverPhoto;
  String? _coverPhotoUrl;
  bool _isSaving = false;
  Position? _currentPosition;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vibeList.title);
    _descriptionController = TextEditingController(text: widget.vibeList.description);
    _tagsController = TextEditingController(text: widget.vibeList.tags.join(', '));
    
    // Convert ItineraryStops to EditableItineraryStops
    _editableStops = widget.vibeList.itineraryStops?.map((stop) => 
      EditableItineraryStop.fromItineraryStop(stop)
    ).toList() ?? [];
    
    _getCurrentPosition();
  }
  
  Future<void> _getCurrentPosition() async {
    final result = await _locationService.getCurrentLocation();
    if (result.success && result.position != null) {
      setState(() {
        _currentPosition = result.position;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildItineraryDetails(),
          _buildStopsEditor(),
        ],
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Edit Itinerary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedCoverPhoto != null)
              Image.file(_selectedCoverPhoto!, fit: BoxFit.cover)
            else if (_coverPhotoUrl != null)
              Image.network(_coverPhotoUrl!, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _selectCoverPhoto,
                backgroundColor: Colors.white,
                child: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryDetails() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Itinerary Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Itinerary Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                hintText: 'romantic, sunset, drinks',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopsEditor() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Edit Your Stops',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your itinerary stops, categories, and order',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            
            // Stops list
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _editableStops.length,
              onReorder: _reorderStops,
              itemBuilder: (context, index) {
                final stop = _editableStops[index];
                return _buildStopEditor(stop, index);
              },
            ),
            
            const SizedBox(height: 100), // Space for save button
          ],
        ),
      ),
    );
  }

  Widget _buildStopEditor(EditableItineraryStop stop, int index) {
    return Container(
      key: ValueKey(stop.id),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with order and actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTimeSlotColor(stop.timeSlot).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stop.timeSlot.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getTimeSlotColor(stop.timeSlot),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _editCategoryName(stop),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      stop.category.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit, size: 14, color: Colors.grey[600]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeStop(stop),
                ),
              ],
            ),
          ),
          
          // Place details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_currentPosition != null)
                  PlaceCard(
                    place: stop.place,
                    currentPosition: _currentPosition!,
                    processImageUrl: _searchService.processImageUrl,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          stop.place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stop.place.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (stop.description != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      stop.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editStopDescription(stop),
                        icon: const Icon(Icons.note_add),
                        label: Text(stop.description != null ? 'Edit Note' : 'Add Note'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _replacePlace(stop),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Replace'),
                      ),
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

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveItinerary,
          icon: _isSaving 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
          label: Text(_isSaving ? 'Saving...' : 'Save Itinerary Board'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTimeSlotColor(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return Colors.orange;
      case 'afternoon':
        return Colors.blue;
      case 'evening':
        return Colors.purple;
      case 'night':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  void _reorderStops(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _editableStops.removeAt(oldIndex);
      _editableStops.insert(newIndex, item);
      
      // Update order numbers
      for (int i = 0; i < _editableStops.length; i++) {
        _editableStops[i] = EditableItineraryStop(
          id: _editableStops[i].id,
          place: _editableStops[i].place,
          timeSlot: _editableStops[i].timeSlot,
          category: _editableStops[i].category,
          order: i,
          description: _editableStops[i].description,
          isCustomCategory: _editableStops[i].isCustomCategory,
        );
      }
    });
  }

  void _removeStop(EditableItineraryStop stop) {
    setState(() {
      _editableStops.removeWhere((s) => s.id == stop.id);
    });
  }

  void _editCategoryName(EditableItineraryStop stop) {
    final controller = TextEditingController(text: stop.category);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Sunset Lounge, Morning Coffee',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  final index = _editableStops.indexWhere((s) => s.id == stop.id);
                  if (index != -1) {
                    _editableStops[index] = EditableItineraryStop(
                      id: stop.id,
                      place: stop.place,
                      timeSlot: stop.timeSlot,
                      category: controller.text,
                      order: stop.order,
                      description: stop.description,
                      isCustomCategory: true,
                    );
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editStopDescription(EditableItineraryStop stop) {
    final controller = TextEditingController(text: stop.description ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Stop Description'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Add details about this stop...',
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
                final index = _editableStops.indexWhere((s) => s.id == stop.id);
                if (index != -1) {
                  _editableStops[index] = EditableItineraryStop(
                    id: stop.id,
                    place: stop.place,
                    timeSlot: stop.timeSlot,
                    category: stop.category,
                    order: stop.order,
                    description: controller.text.isEmpty ? null : controller.text,
                    isCustomCategory: stop.isCustomCategory,
                  );
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _replacePlace(EditableItineraryStop stop) {
    // Placeholder for place replacement functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Place replacement coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectCoverPhoto() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedCoverPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveItinerary() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an itinerary name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload cover photo if selected
      String? coverPhotoUrl = _coverPhotoUrl;
      if (_selectedCoverPhoto != null) {
        // Generate a temporary board ID for the upload
        final tempBoardId = DateTime.now().millisecondsSinceEpoch.toString();
        coverPhotoUrl = await _boardService.uploadCoverPhoto(_selectedCoverPhoto!, tempBoardId);
      }

      // Convert editable stops back to itinerary stops
      final itineraryStops = _editableStops.map((editableStop) => ItineraryStop(
        place: editableStop.place,
        timeSlot: editableStop.timeSlot,
        category: editableStop.category,
        order: editableStop.order,
        description: editableStop.description,
      )).toList();

      // Create updated vibe list
      final updatedVibeList = VibeList(
        id: widget.vibeList.id,
        title: _nameController.text,
        description: _descriptionController.text,
        places: widget.vibeList.places,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        vibeType: widget.vibeList.vibeType,
        estimatedDuration: widget.vibeList.estimatedDuration,
        createdAt: widget.vibeList.createdAt,
        createdBy: widget.vibeList.createdBy,
        isShared: widget.vibeList.isShared,
        sharedWithCircles: widget.vibeList.sharedWithCircles,
        isMultiStop: true,
        itineraryStops: itineraryStops,
        groupType: widget.vibeList.groupType,
        specialOccasion: widget.vibeList.specialOccasion,
      );

      // Save as board
      await _boardService.saveVibeListAsBoard(
        vibeList: updatedVibeList,
        name: _nameController.text,
        description: _descriptionController.text,
        customTags: _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        coverPhotoUrl: coverPhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Itinerary board saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving itinerary: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}