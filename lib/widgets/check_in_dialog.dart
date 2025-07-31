// lib/widgets/check_in_dialog.dart
import 'package:flutter/material.dart';
import 'package:myapp/models/models.dart';
import '../models/visit_models.dart';
import '../services/visit_service.dart';

class CheckInDialog extends StatefulWidget {
  final PlaceDetails place;

  const CheckInDialog({
    super.key,
    required this.place,
  });

  @override
  State<CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<CheckInDialog> {
  final VisitService _visitService = VisitService();
  final TextEditingController _noteController = TextEditingController();
  
  final Set<String> _selectedVibes = {};
  int? _rating;
  bool _isLoading = false;
  String _activeVibeCategory = 'mood';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _performCheckIn() async {
    setState(() => _isLoading = true);

    final result = await _visitService.checkIn(
      place: widget.place,
      selectedVibes: _selectedVibes.toList(),
      userNote: _noteController.text.isNotEmpty ? _noteController.text : null,
      rating: _rating,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      // Show success animation
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Checked in to ${widget.place.name}!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in failed: ${result.error}'),
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
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceInfo(),
                    const SizedBox(height: 24),
                    _buildVibeSelection(),
                    const SizedBox(height: 24),
                    _buildRatingSection(),
                    const SizedBox(height: 24),
                    _buildNoteSection(),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Check In',
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
    );
  }

  Widget _buildPlaceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.place,
            color: Theme.of(context).primaryColor,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.place.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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
    );
  }

  Widget _buildVibeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How was the vibe? (Select all that apply)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Category tabs
        Container(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['mood', 'atmosphere', 'crowd', 'style'].map((category) {
              final isActive = _activeVibeCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    category[0].toUpperCase() + category.substring(1),
                  ),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _activeVibeCategory = category);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Vibes for selected category
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VibeConstants.allVibes
              .where((vibe) => vibe.category == _activeVibeCategory)
              .map((vibe) {
            final isSelected = _selectedVibes.contains(vibe.id);
            return FilterChip(
              label: Text('${vibe.icon} ${vibe.name}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedVibes.add(vibe.id);
                  } else {
                    _selectedVibes.remove(vibe.id);
                  }
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              avatar: isSelected ? null : Text(vibe.icon),
            );
          }).toList(),
        ),
        if (_selectedVibes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected vibes (${_selectedVibes.length}):',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedVibes.map((vibeId) {
                    final vibe = VibeConstants.getVibeById(vibeId);
                    return Chip(
                      label: Text(
                        '${vibe?.icon ?? ''} ${vibe?.name ?? vibeId}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedVibes.remove(vibeId);
                        });
                      },
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      deleteIconColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rate your experience',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final star = index + 1;
            final isSelected = _rating != null && star <= _rating!;
            return IconButton(
              icon: Icon(
                isSelected ? Icons.star : Icons.star_border,
                size: 40,
                color: isSelected ? Colors.amber : Colors.grey[400],
              ),
              onPressed: () {
                setState(() {
                  _rating = star;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a note (optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'What made this place special?',
            hintStyle: TextStyle(color: Colors.grey[500]),
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
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
              onPressed: _isLoading || _selectedVibes.isEmpty
                  ? null
                  : _performCheckIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Check In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}