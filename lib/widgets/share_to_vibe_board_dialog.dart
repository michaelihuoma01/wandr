// lib/widgets/share_to_vibe_board_dialog.dart
import 'package:flutter/material.dart';
import 'package:myapp/screens/create_vibe_board_screen.dart';
import '../models/models.dart';
import '../models/circle_models.dart';
import '../services/circle_service.dart';

class ShareToVibeBoardDialog extends StatefulWidget {
  final PlaceDetails place;

  const ShareToVibeBoardDialog({
    super.key,
    required this.place,
  });

  @override
  State<ShareToVibeBoardDialog> createState() => _ShareToVibeBoardDialogState();
}

class _ShareToVibeBoardDialogState extends State<ShareToVibeBoardDialog> {
  final CircleService _circleService = CircleService();
  final TextEditingController _noteController = TextEditingController();
  
  List<VibeCircle> _myCircles = [];
  Map<String, List<VibeBoard>> _circleBoards = {};
  String? _selectedCircleId;
  final Set<String> _selectedBoardIds = {};
  bool _isLoading = true;
  bool _isAddingToBoards = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final circles = await _circleService.getUserCircles();
      setState(() {
        _myCircles = circles;
        if (circles.isNotEmpty) {
          _selectedCircleId = circles.first.id;
        }
      });
      
      // Load boards for each circle
      for (final circle in circles) {
        final boards = await _circleService.getCircleBoards(circle.id);
        setState(() {
          _circleBoards[circle.id] = boards;
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addToBoards() async {
    if (_selectedBoardIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one board')),
      );
      return;
    }

    setState(() => _isAddingToBoards = true);

    try {
      // Create BoardPlace from place
      final boardPlace = BoardPlace(
        placeId: widget.place.placeId ?? '',
        placeName: widget.place.name,
        placeType: widget.place.type,
        latitude: widget.place.latitude,
        longitude: widget.place.longitude,
        imageUrl: widget.place.imageUrls?.isNotEmpty == true 
            ? widget.place.imageUrls!.first : null,
        customNote: _noteController.text.trim(),
        vibes: [],
        orderIndex: 0, // Will be updated when adding to board
      );

      // Add to each selected board
      for (final boardId in _selectedBoardIds) {
        // Find the board and its circle
        String? circleId;
        VibeBoard? board;
        
        for (final entry in _circleBoards.entries) {
          final foundBoard = entry.value.firstWhere(
            (b) => b.id == boardId,
            orElse: () => VibeBoard(
              id: '',
              circleId: '',
              creatorId: '',
              creatorName: '',
              title: '',
              places: [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
          if (foundBoard.id.isNotEmpty) {
            circleId = entry.key;
            board = foundBoard;
            break;
          }
        }

        if (circleId != null && board != null) {
          // Add place to board
          final updatedPlaces = [...board.places];
          boardPlace.orderIndex = updatedPlaces.length;
          updatedPlaces.add(boardPlace);

          // Update board in Firestore
          await _circleService.firestore
              .collection('circles')
              .doc(circleId)
              .collection('boards')
              .doc(boardId)
              .update({
            'places': updatedPlaces.map((p) => p.toJson()).toList(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }

      if (!mounted) return;

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Added to ${_selectedBoardIds.length} board${_selectedBoardIds.length > 1 ? 's' : ''}!',
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isAddingToBoards = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to boards: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToCreateBoard() {
    if (_selectedCircleId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateVibeBoardScreen(circleId: _selectedCircleId!),
      ),
    ).then((created) {
      if (created == true) {
        _loadData(); // Reload boards
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _myCircles.isEmpty
                      ? _buildEmptyState()
                      : _buildContent(),
            ),
            
            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Add to Vibe Board',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Place info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.place, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.place.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.place.type,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note field
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Add a note (optional)',
              hintText: 'What makes this place special?',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          
          // Circle selector
          if (_myCircles.length > 1) ...[
            const Text(
              'Select Circle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedCircleId,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (value) {
                  setState(() {
                    _selectedCircleId = value;
                    _selectedBoardIds.clear(); // Clear selections when changing circle
                  });
                },
                items: _myCircles.map((circle) {
                  return DropdownMenuItem(
                    value: circle.id,
                    child: Row(
                      children: [
                        Text(circle.category.emoji),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            circle.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Board selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Boards (${_selectedBoardIds.length} selected)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _navigateToCreateBoard,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New Board'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Board list
          if (_selectedCircleId != null) ...[
            if (_circleBoards[_selectedCircleId]?.isEmpty ?? true)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.dashboard_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No boards in this circle yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _navigateToCreateBoard,
                      child: const Text('Create First Board'),
                    ),
                  ],
                ),
              )
            else
              ...(_circleBoards[_selectedCircleId] ?? []).map((board) {
                final isSelected = _selectedBoardIds.contains(board.id);
                final alreadyContains = board.places.any((p) =>
                    p.placeId == widget.place.placeId);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.05)
                        : Colors.white,
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: alreadyContains 
                        ? null 
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedBoardIds.add(board.id);
                              } else {
                                _selectedBoardIds.remove(board.id);
                              }
                            });
                          },
                    title: Text(
                      board.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(Icons.place, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${board.places.length} places',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        if (alreadyContains) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Already added',
                            style: TextStyle(fontSize: 13, color: Colors.green[600]),
                          ),
                        ],
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Circles Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join circles to create and share vibe boards',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to circles tab
              },
              child: const Text('Browse Circles'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isAddingToBoards ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isAddingToBoards || _selectedBoardIds.isEmpty
                  ? null
                  : _addToBoards,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isAddingToBoards
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedBoardIds.isEmpty
                              ? 'Add to Board'
                              : 'Add to ${_selectedBoardIds.length} Board${_selectedBoardIds.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}