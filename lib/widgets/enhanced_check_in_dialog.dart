import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/models.dart';
import '../models/visit_models.dart';
import '../services/visit_service.dart';
import '../services/location_service.dart';

class EnhancedCheckInBottomSheet extends StatefulWidget {
  final PlaceDetails place;

  const EnhancedCheckInBottomSheet({
    super.key,
    required this.place,
  });

  @override
  State<EnhancedCheckInBottomSheet> createState() => _EnhancedCheckInBottomSheetState();
}

class _EnhancedCheckInBottomSheetState extends State<EnhancedCheckInBottomSheet> {
  final VisitService _visitService = VisitService();
  final LocationService _locationService = LocationService();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  final Set<String> _selectedVibes = {};
  int? _rating;
  bool _isLoading = false;
  bool _isVerifying = false;
  
  // Enhanced features
  File? _selectedPhoto;
  bool _isStoryPublic = false;
  CheckInVerification? _checkInVerification;

  @override
  void initState() {
    super.initState();
    _verifyCheckInEligibility();
  }

  Future<void> _verifyCheckInEligibility() async {
    setState(() => _isVerifying = true);
    
    try {
      final verification = await _visitService.verifyCheckInEligibility(place: widget.place);
      setState(() {
        _checkInVerification = verification;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkInVerification = CheckInVerification(
            canCheckIn: false,
            error: 'Unable to verify location: $e',
            distanceFromPlace: 0,
            isWithinRadius: false,
            isWithinGracePeriod: false,
          );
        });
      }
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedPhoto = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _handleCheckIn() async {
    if (_selectedVibes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one vibe')),
      );
      return;
    }

    if (_checkInVerification?.canCheckIn != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_checkInVerification?.error ?? 'Cannot check in at this location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _visitService.checkIn(
        place: widget.place,
        selectedVibes: _selectedVibes.toList(),
        userNote: _noteController.text.isNotEmpty ? _noteController.text : null,
        rating: _rating,
        photoFile: _selectedPhoto,
        storyCaption: _noteController.text.isNotEmpty ? _noteController.text : null,
        isStoryPublic: _isStoryPublic,
        actualVisitTime: DateTime.now(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.success) {
        _showSuccessDialog(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check-in failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showSuccessDialog(CheckInResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              'Check-in Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check-in completed successfully!',
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return Material(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verifying location...'),
            ],
          ),
        ),
      );
    }

    return Material(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationStatus(),
                    const SizedBox(height: 16),
                    _buildQuickVibeSelection(),
                    const SizedBox(height: 24),
                    _buildPhotoSection(),
                    const SizedBox(height: 24),
                    _buildRatingSection(),
                    const SizedBox(height: 24),
                    _buildOptionalDetails(),
                  ],
                ),
              ),
            ),
            _buildSimpleBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    if (_checkInVerification == null) return const SizedBox.shrink();

    final verification = _checkInVerification!;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (verification.canCheckIn) {
      if (verification.isWithinRadius) {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Location verified (${verification.distanceFromPlace.round()}m away)';
      } else {
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Grace period check-in (${verification.distanceFromPlace.round()}m away)';
      }
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = verification.error ?? 'Cannot check in at this location';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickVibeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mood, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'How are you feeling?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VibeConstants.allVibes
              .take(8) // Show only top 8 most common vibes
              .map((vibe) {
            final isSelected = _selectedVibes.contains(vibe.id);
            return FilterChip(
              label: Text('${vibe.emoji} ${vibe.name}'),
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
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Capture the moment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedPhoto != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedPhoto!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retake'),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedPhoto = null),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Remove'),
              ),
            ],
          ),
        ] else ...[
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 24, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('Add Photo', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Photos help verify your visit and earn credibility points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Rate this place',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = starIndex),
              child: Icon(
                starIndex <= (_rating ?? 0) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOptionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Drop a quick review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Optional',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'Share your thoughts about this place...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 3,
          maxLength: 280,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Share publicly'),
          subtitle: const Text('Let others discover this place'),
          value: _isStoryPublic,
          onChanged: (value) => setState(() => _isStoryPublic = value),
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildSimpleBottomButton() {
    final canCheckIn = _selectedVibes.isNotEmpty && _checkInVerification?.canCheckIn == true;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canCheckIn && !_isLoading ? _handleCheckIn : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Check In${_selectedVibes.isNotEmpty ? " • ${_selectedVibes.length} vibe${_selectedVibes.length > 1 ? 's' : ''}" : ""}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on,
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
                  'Check In',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.place.name,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
    );
  }
}