// lib/screens/circles/join_circle_dialog.dart
import 'package:flutter/material.dart';
// Using NetworkImage instead of cached_network_image
import '../../models/circle_models.dart';
import '../../services/circle_service.dart';

class JoinCircleDialog extends StatefulWidget {
  final VibeCircle circle;
  final VoidCallback? onJoined;

  const JoinCircleDialog({
    super.key,
    required this.circle,
    this.onJoined,
  });

  @override
  State<JoinCircleDialog> createState() => _JoinCircleDialogState();
}

class _JoinCircleDialogState extends State<JoinCircleDialog> {
  final CircleService _circleService = CircleService();
  final TextEditingController _inviteCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _showInviteCode = false;

  @override
  void initState() {
    super.initState();
    // Show invite code field immediately for private circles
    _showInviteCode = !widget.circle.isPublic;
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinCircle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _circleService.joinCircleWithCode(
      widget.circle.id,
      inviteCode: _inviteCodeController.text.isEmpty ? null : _inviteCodeController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pop(context);
      
      if (result.message?.contains('request sent') == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result.message!)),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Welcome to ${widget.circle.name}!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onJoined?.call();
      }
    } else {
      setState(() {
        _errorMessage = result.error;
        if (result.error?.contains('invite code') == true) {
          _showInviteCode = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with circle info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildCircleAvatar(),
                  const SizedBox(height: 12),
                  Text(
                    widget.circle.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.circle.isPublic ? Icons.public : Icons.lock,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.circle.isPublic ? 'Public Circle' : 'Private Circle',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.circle.memberCount} members',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (widget.circle.description.isNotEmpty) ...[
                    Text(
                      widget.circle.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Vibes
                  if (widget.circle.vibePreferences.isNotEmpty) ...[
                    Text(
                      'Circle Vibes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.circle.vibePreferences.map((vibe) {
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
                              fontSize: 13,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Invite code field
                  if (_showInviteCode) ...[
                    Text(
                      'Invite Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _inviteCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-character code',
                        prefixIcon: const Icon(Icons.key),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLength: 6,
                    ),
                  ],
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 20, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Privacy notice
                  if (widget.circle.requiresApproval) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This circle requires approval. Your request will be sent to the admins.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
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
                      onPressed: _isLoading ? null : _joinCircle,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                          : Text(
                              widget.circle.requiresApproval ? 'Request to Join' : 'Join Circle',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAvatar() {
    if (widget.circle.imageUrl != null && widget.circle.imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(widget.circle.imageUrl!),
        backgroundColor: Colors.grey[200],
      );
    }
    
    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        widget.circle.category.emoji,
        style: const TextStyle(fontSize: 40),
      ),
    );
  }
}