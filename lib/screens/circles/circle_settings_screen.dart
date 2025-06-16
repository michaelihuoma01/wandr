// lib/screens/circles/circle_settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/circle_models.dart';
import '../../services/circle_service.dart';

class CircleSettingsScreen extends StatefulWidget {
  final VibeCircle circle;

  const CircleSettingsScreen({
    super.key,
    required this.circle,
  });

  @override
  State<CircleSettingsScreen> createState() => _CircleSettingsScreenState();
}

class _CircleSettingsScreenState extends State<CircleSettingsScreen> {
  final CircleService _circleService = CircleService();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isPublic;
  late bool _requiresApproval;
  late bool _allowMemberInvites;
  late bool _showMemberVisits;
  
  File? _newImage;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.circle.name);
    _descriptionController = TextEditingController(text: widget.circle.description);
    _isPublic = widget.circle.isPublic;
    _requiresApproval = widget.circle.requiresApproval;
    _allowMemberInvites = widget.circle.allowMemberInvites;
    _showMemberVisits = widget.circle.showMemberVisits;
    
    // Listen for changes
    _nameController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() => _hasChanges = true);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _newImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_newImage == null) return widget.circle.imageUrl;
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'circle_images/${widget.circle.id}_$timestamp.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      
      final uploadTask = await ref.putFile(_newImage!);
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;
    
    setState(() => _isSaving = true);

    try {
      // Upload new image if selected
      final imageUrl = await _uploadImage();
      
      // Update circle in Firestore
      await _circleService.firestore
          .collection('circles')
          .doc(widget.circle.id)
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'isPublic': _isPublic,
        'requiresApproval': _requiresApproval,
        'allowMemberInvites': _allowMemberInvites,
        'showMemberVisits': _showMemberVisits,
      });

      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Circle settings updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save changes: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showInviteCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.circle.inviteCode ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.circle.inviteCode ?? ''),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite code copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this code with people you want to invite',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Circle'),
        content: Text(
          'Are you sure you want to delete "${widget.circle.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement circle deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Circle deletion not yet implemented'),
                ),
              );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Circle Settings'),
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
            // Circle image
            _buildImageSection(),
            
            const SizedBox(height: 8),
            
            // Basic info
            _buildBasicInfoSection(),
            
            const SizedBox(height: 8),
            
            // Privacy settings
            _buildPrivacySection(),
            
            const SizedBox(height: 8),
            
            // Invite code (for private circles)
            if (!_isPublic) _buildInviteCodeSection(),
            
            const SizedBox(height: 8),
            
            // Danger zone
            _buildDangerZone(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Circle Image',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(60),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _newImage != null
                      ? Image.file(
                          _newImage!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        )
                      : widget.circle.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.circle.imageUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            )
                          : Container(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  widget.circle.category.emoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Change Image'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Circle Name',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Public Circle'),
            subtitle: const Text('Anyone can discover and join this circle'),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
                _hasChanges = true;
                if (!value) {
                  _requiresApproval = false;
                }
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (_isPublic)
            SwitchListTile(
              title: const Text('Requires Approval'),
              subtitle: const Text('New members need admin approval'),
              value: _requiresApproval,
              onChanged: (value) {
                setState(() {
                  _requiresApproval = value;
                  _hasChanges = true;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          SwitchListTile(
            title: const Text('Allow Member Invites'),
            subtitle: const Text('Members can invite others to join'),
            value: _allowMemberInvites,
            onChanged: (value) {
              setState(() {
                _allowMemberInvites = value;
                _hasChanges = true;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Show Member Visits'),
            subtitle: const Text('Members can see places visited by others'),
            value: _showMemberVisits,
            onChanged: (value) {
              setState(() {
                _showMemberVisits = value;
                _hasChanges = true;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite Code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('View Invite Code'),
            subtitle: const Text('Share this code to invite people'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _showInviteCode,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Circle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}