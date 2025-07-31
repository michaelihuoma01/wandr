// lib/screens/circles/create_circle_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/circle_models.dart';
import '../../models/visit_models.dart';
import '../../services/circle_service.dart';
import '../../services/auth_service.dart';

class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  final CircleService _circleService = CircleService();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  CircleCategory _selectedCategory = CircleCategory.other;
  final Set<String> _selectedVibes = {};
  bool _isPublic = true;
  bool _requiresApproval = false;
  bool _allowMemberInvites = true;
  bool _showMemberVisits = true;
  int? _memberLimit;
  
  File? _selectedImage;
  bool _isCreating = false;
  String _activeVibeCategory = 'mood';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'circle_images/$timestamp.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      
      final uploadTask = await ref.putFile(_selectedImage!);
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _createCircle() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVibes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one vibe for your circle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    // Upload image if selected
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage();
    }

    final result = await _circleService.createCircle(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      vibePreferences: _selectedVibes.toList(),
      isPublic: _isPublic,
      requiresApproval: _requiresApproval,
      allowMemberInvites: _allowMemberInvites,
      showMemberVisits: _showMemberVisits,
      memberLimit: _memberLimit,
      imageUrl: imageUrl,
    );

    if (!mounted) return;

    setState(() => _isCreating = false);

    if (result.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${_nameController.text} created successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create circle: ${result.error}'),
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
        title: const Text('Create Circle'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              _buildImagePicker(),
              const SizedBox(height: 24),
              
              // Basic info
              _buildBasicInfo(),
              const SizedBox(height: 24),
              
              // Category selection
              _buildCategorySelection(),
              const SizedBox(height: 24),
              
              // Vibe selection
              _buildVibeSelection(),
              const SizedBox(height: 24),
              
              // Privacy settings
              _buildPrivacySettings(),
              const SizedBox(height: 32),
              
              // Create button
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(60),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: _selectedImage != null
              ? ClipOval(
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Circle Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Circle Name',
            hintText: 'e.g., Dubai Foodies',
            prefixIcon: Icon(Icons.group),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a circle name';
            }
            if (value.trim().length < 3) {
              return 'Name must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'What is your circle about?',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CircleCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.emoji),
                  const SizedBox(width: 6),
                  Text(category.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVibeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Circle Vibes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select vibes that represent your circle (minimum 1)',
          style: TextStyle(fontSize: 14, color: Colors.grey),
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
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              'Selected: ${_selectedVibes.length} vibes',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Public/Private toggle
        SwitchListTile(
          title: const Text('Public Circle'),
          subtitle: const Text('Anyone can discover and join this circle'),
          value: _isPublic,
          onChanged: (value) {
            setState(() {
              _isPublic = value;
              if (!value) {
                _requiresApproval = false; // Private circles use invite codes
              }
            });
          },
          activeColor: Theme.of(context).primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
        
        // Approval required (only for public circles)
        if (_isPublic)
          SwitchListTile(
            title: const Text('Requires Approval'),
            subtitle: const Text('New members need admin approval to join'),
            value: _requiresApproval,
            onChanged: (value) => setState(() => _requiresApproval = value),
            activeColor: Theme.of(context).primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        
        // Member invites
        SwitchListTile(
          title: const Text('Allow Member Invites'),
          subtitle: const Text('Members can invite others to join'),
          value: _allowMemberInvites,
          onChanged: (value) => setState(() => _allowMemberInvites = value),
          activeColor: Theme.of(context).primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
        
        // Show member visits
        SwitchListTile(
          title: const Text('Show Member Visits'),
          subtitle: const Text('Members can see places visited by others'),
          value: _showMemberVisits,
          onChanged: (value) => setState(() => _showMemberVisits = value),
          activeColor: Theme.of(context).primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
        
        // Member limit
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Member Limit (Optional)',
            hintText: 'Leave empty for unlimited',
            prefixIcon: Icon(Icons.people),
            suffixText: 'members',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            if (value.isEmpty) {
              _memberLimit = null;
            } else {
              _memberLimit = int.tryParse(value);
            }
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final limit = int.tryParse(value);
              if (limit == null || limit < 2) {
                return 'Minimum limit is 2 members';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createCircle,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Create Circle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}