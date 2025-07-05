import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../services/onboarding_service.dart';
import '../../services/auth_service.dart';
import '../../services/vibe_definition_service.dart';

class VibeWheelScreen extends StatefulWidget {
  const VibeWheelScreen({super.key});

  @override
  State<VibeWheelScreen> createState() => _VibeWheelScreenState();
}

class _VibeWheelScreenState extends State<VibeWheelScreen>
    with TickerProviderStateMixin {
  final OnboardingService _onboardingService = OnboardingService();
  final AuthService _authService = AuthService();

  late AnimationController _wheelController;
  late AnimationController _selectionController;
  late AnimationController _pulseController;
  
  late Animation<double> _wheelRotation;
  late Animation<double> _selectionScale;
  late Animation<double> _pulseAnimation;

  final Map<String, double> _vibeIntensities = {};
  final Map<String, bool> _selectedVibes = {};
  String? _centerVibe;
  bool _isProcessing = false;

  // Vibe wheel configuration
  static const List<String> _coreVibes = [
    'cozy', 'active', 'aesthetic', 'adventurous',
    'luxurious', 'social', 'chill', 'intimate'
  ];

  static const Map<String, String> _vibeEmojis = {
    'cozy': '🛋️',
    'active': '⚡',
    'aesthetic': '📸',
    'adventurous': '🗺️',
    'luxurious': '✨',
    'social': '🤝',
    'chill': '😌',
    'intimate': '💕',
  };

  static const Map<String, Color> _vibeColors = {
    'cozy': Color(0xFFD4A574),
    'active': Color(0xFFE74C3C),
    'aesthetic': Color(0xFFE91E63),
    'adventurous': Color(0xFF27AE60),
    'luxurious': Color(0xFFAF7AC5),
    'social': Color(0xFF3498DB),
    'chill': Color(0xFF58D68D),
    'intimate': Color(0xFFF1948A),
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeVibes();
  }

  void _setupAnimations() {
    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _wheelRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _wheelController,
      curve: Curves.easeOutCubic,
    ));

    _selectionScale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _wheelController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _initializeVibes() {
    for (final vibe in _coreVibes) {
      _vibeIntensities[vibe] = 0.0;
      _selectedVibes[vibe] = false;
    }
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _selectionController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onVibeSelected(String vibe) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _selectedVibes[vibe] = !(_selectedVibes[vibe] ?? false);
      
      if (_selectedVibes[vibe]!) {
        _vibeIntensities[vibe] = 0.8;
        _centerVibe = vibe;
      } else {
        _vibeIntensities[vibe] = 0.0;
        if (_centerVibe == vibe) {
          _centerVibe = null;
        }
      }
    });

    _selectionController.forward().then((_) {
      _selectionController.reverse();
    });
  }

  void _onVibeIntensityChanged(String vibe, double intensity) {
    setState(() {
      _vibeIntensities[vibe] = intensity;
      _selectedVibes[vibe] = intensity > 0.2;
      
      if (intensity > 0.5) {
        _centerVibe = vibe;
      }
    });
  }

  Future<void> _continueToNext() async {
    if (_isProcessing) return;

    final selectedVibes = _selectedVibes.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedVibes.isEmpty) {
      _showError('Please select at least one vibe that resonates with you');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showError('Please sign in to continue');
        return;
      }

      final onboardingState = await _onboardingService.getOnboardingState(currentUser.uid);
      if (onboardingState == null) {
        _showError('Onboarding session not found. Please restart.');
        return;
      }

      final stepResponses = {
        'vibeWheel': {
          'selectedVibes': selectedVibes,
          'vibePositions': _vibeIntensities,
          'centerVibe': _centerVibe,
          'selectionTime': DateTime.now().toIso8601String(),
        }
      };

      await _onboardingService.progressToNextStep(onboardingState, stepResponses);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding/contextual-preferences');
      }
    } catch (e) {
      _showError('Failed to save your selections. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildVibeWheel()),
              _buildBottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const Spacer(),
              _buildProgressIndicator(),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'What\'s Your Vibe?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the vibes that speak to you',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressDot(true),
        const SizedBox(width: 8),
        _buildProgressDot(true),
        const SizedBox(width: 8),
        _buildProgressDot(false),
        const SizedBox(width: 8),
        _buildProgressDot(false),
      ],
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).primaryColor 
            : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildVibeWheel() {
    return Center(
      child: Container(
        width: 320,
        height: 320,
        child: AnimatedBuilder(
          animation: _wheelRotation,
          builder: (context, child) {
            return GestureDetector(
              onTapDown: (details) => _handleWheelTap(details.localPosition),
              child: CustomPaint(
                painter: VibeWheelPainter(
                  vibes: _coreVibes,
                  vibeColors: _vibeColors,
                  vibeEmojis: _vibeEmojis,
                  selectedVibes: _selectedVibes,
                  vibeIntensities: _vibeIntensities,
                  animationProgress: _wheelRotation.value,
                  pulseAnimation: _pulseAnimation,
                ),
                child: Container(
                  width: 320,
                  height: 320,
                  child: _buildCenterDisplay(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCenterDisplay() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _centerVibe != null ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _centerVibe != null 
                    ? _vibeColors[_centerVibe!]?.withOpacity(0.2)
                    : Colors.white,
                border: Border.all(
                  color: _centerVibe != null 
                      ? _vibeColors[_centerVibe!]!
                      : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_centerVibe != null 
                        ? _vibeColors[_centerVibe!]!
                        : Colors.grey[300]!).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _centerVibe != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _vibeEmojis[_centerVibe!] ?? '✨',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _centerVibe!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _vibeColors[_centerVibe!],
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.touch_app,
                        color: Colors.grey[400],
                        size: 24,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleWheelTap(Offset localPosition) {
    final center = const Offset(160, 160); // Half of 320x320
    final offset = localPosition - center;
    final distance = offset.distance;
    
    // Only process taps within the wheel (excluding center circle)
    // Wheel radius is 140 (160 - 20), center circle is 40 radius
    if (distance < 40 || distance > 140) return;
    
    // Calculate angle - match the painter's coordinate system
    final angle = math.atan2(offset.dy, offset.dx);
    // Adjust angle to start from top (12 o'clock) like the painter
    final adjustedAngle = angle + math.pi / 2;
    // Normalize to 0-2π range
    final normalizedAngle = (adjustedAngle + 2 * math.pi) % (2 * math.pi);
    
    final sectionSize = 2 * math.pi / _coreVibes.length;
    final sectionIndex = (normalizedAngle / sectionSize).floor() % _coreVibes.length;
    
    print('Tap detected at distance: $distance, angle: $angle, adjusted: $adjustedAngle, normalized: $normalizedAngle, section: $sectionIndex, vibe: ${_coreVibes[sectionIndex]}');
    _onVibeSelected(_coreVibes[sectionIndex]);
  }

  Widget _buildBottomPanel() {
    final selectedCount = _selectedVibes.values.where((selected) => selected).length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0) ...[
            Text(
              'Selected Vibes ($selectedCount)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedVibes.entries
                  .where((entry) => entry.value)
                  .map((entry) => _buildSelectedVibeChip(entry.key))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedCount > 0 && !_isProcessing ? _continueToNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: selectedCount > 0 ? 4 : 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Continue',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
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

  Widget _buildSelectedVibeChip(String vibe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _vibeColors[vibe]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _vibeColors[vibe] ?? Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _vibeEmojis[vibe] ?? '✨',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            vibe.capitalize(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _vibeColors[vibe],
            ),
          ),
        ],
      ),
    );
  }
}

class VibeWheelPainter extends CustomPainter {
  final List<String> vibes;
  final Map<String, Color> vibeColors;
  final Map<String, String> vibeEmojis;
  final Map<String, bool> selectedVibes;
  final Map<String, double> vibeIntensities;
  final double animationProgress;
  final Animation<double> pulseAnimation;

  VibeWheelPainter({
    required this.vibes,
    required this.vibeColors,
    required this.vibeEmojis,
    required this.selectedVibes,
    required this.vibeIntensities,
    required this.animationProgress,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final sectionAngle = 2 * math.pi / vibes.length;

    for (int i = 0; i < vibes.length; i++) {
      final vibe = vibes[i];
      final startAngle = i * sectionAngle - math.pi / 2;
      final endAngle = (i + 1) * sectionAngle - math.pi / 2;
      
      final isSelected = selectedVibes[vibe] ?? false;
      final intensity = vibeIntensities[vibe] ?? 0.0;
      
      // Calculate animated radius
      final currentRadius = radius * animationProgress;
      final selectedRadius = isSelected 
          ? currentRadius + (10 * pulseAnimation.value)
          : currentRadius;

      // Draw the section
      final paint = Paint()
        ..color = (vibeColors[vibe] ?? Colors.grey).withOpacity(
          isSelected ? 0.8 + (0.2 * intensity) : 0.3
        )
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.addArc(
        Rect.fromCircle(center: center, radius: selectedRadius),
        startAngle,
        sectionAngle,
      );
      path.close();

      canvas.drawPath(path, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawPath(path, borderPaint);

      // Draw emoji and label
      final labelAngle = startAngle + sectionAngle / 2;
      final labelRadius = selectedRadius * 0.75;
      final labelX = center.dx + labelRadius * math.cos(labelAngle);
      final labelY = center.dy + labelRadius * math.sin(labelAngle);

      // Draw emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: vibeEmojis[vibe] ?? '✨',
          style: TextStyle(
            fontSize: isSelected ? 24 : 20,
            fontFamily: 'NotoColorEmoji',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelX - textPainter.width / 2,
          labelY - textPainter.height / 2 - 12,
        ),
      );

      // Draw label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: vibe.toUpperCase(),
          style: TextStyle(
            fontSize: isSelected ? 11 : 9,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          labelX - labelPainter.width / 2,
          labelY - labelPainter.height / 2 + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }
}