// lib/widgets/share_to_circle_dialog.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../models/circle_models.dart';
import '../services/circle_service.dart';
import '../services/auth_service.dart';

class ShareToCircleDialog extends StatefulWidget {
  final PlaceDetails place;

  const ShareToCircleDialog({
    super.key,
    required this.place,
  });

  @override
  State<ShareToCircleDialog> createState() => _ShareToCircleDialogState();
}

class _ShareToCircleDialogState extends State<ShareToCircleDialog> {
  final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  final TextEditingController _noteController = TextEditingController();
  
  List<VibeCircle> _myCircles = [];
  final Set<String> _selectedCircleIds = {};
  bool _isLoading = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCircles() async {
    try {
      final circles = await _circleService.getUserCircles();
      setState(() {
        _myCircles = circles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load circles: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _shareToCircles() async {
    if (_selectedCircleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one circle')),
      );
      return;
    }

    setState(() => _isSharing = true);

    try {
      // Share to each selected circle
      for (final circleId in _selectedCircleIds) {
        await _circleService.sharePlace(
          circleId: circleId,
          place: widget.place,
          note: _noteController.text.trim(),
        );
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
                'Shared to ${_selectedCircleIds.length} circle${_selectedCircleIds.length > 1 ? 's' : ''}!',
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSharing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                Icons.share_location,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Share to Circles',
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
              hintText: 'Why are you sharing this place?',
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
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          
          // Circle selection
          Text(
            'Select Circles (${_selectedCircleIds.length} selected)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Circle list
          ...List.generate(
            _myCircles.length,
            (index) => _buildCircleItem(_myCircles[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleItem(VibeCircle circle) {
    final isSelected = _selectedCircleIds.contains(circle.id);
    
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
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedCircleIds.add(circle.id);
            } else {
              _selectedCircleIds.remove(circle.id);
            }
          });
        },
        secondary: CircleAvatar(
          backgroundImage: circle.imageUrl != null
              ? CachedNetworkImageProvider(circle.imageUrl!)
              : null,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: circle.imageUrl == null
              ? Text(
                  circle.category.emoji,
                  style: const TextStyle(fontSize: 20),
                )
              : null,
        ),
        title: Text(
          circle.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.people, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${circle.memberCount} members',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
              'Join or create circles to share places',
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
              onPressed: _isSharing ? null : () => Navigator.pop(context),
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
              onPressed: _isSharing || _selectedCircleIds.isEmpty
                  ? null
                  : _shareToCircles,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isSharing
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
                        const Icon(Icons.share, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCircleIds.isEmpty
                              ? 'Share'
                              : 'Share to ${_selectedCircleIds.length}',
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