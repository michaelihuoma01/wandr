import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../models/vibe_tag_models.dart';
import '../../services/auth_service.dart';
import '../../services/vibe_tag_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/unified_search_service.dart';
import '../../widgets/vibe_selection_widgets.dart';
import '../enhanced_home_screen.dart';

// ============================================================================
// STREAMLINED ONBOARDING - 3 SIMPLE STEPS
// ============================================================================

class StreamlinedOnboardingScreen extends StatefulWidget {
  const StreamlinedOnboardingScreen({super.key});

  @override
  State<StreamlinedOnboardingScreen> createState() => _StreamlinedOnboardingScreenState();
}

class _StreamlinedOnboardingScreenState extends State<StreamlinedOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  final VibeTagService _vibeTagService = VibeTagService();
  final UserProfileService _userProfileService = UserProfileService();
  final UnifiedSearchService _searchService = UnifiedSearchService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  Set<String> _selectedVibes = {};
  bool _isLoading = false;
  String? _userName;

  static const int _totalSteps = 3;
  static const int _minVibeSelection = 3;
  static const int _maxVibeSelection = 6;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserName();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadUserName() async {
    final currentUser = _authService.currentUser;
    setState(() {
      _userName = currentUser?.displayName?.split(' ').first ?? 'there';
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedVibes.length < _minVibeSelection) {
      _showVibeSelectionError();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('No user found');

      // Initialize vibe system
      await _vibeTagService.initializeVibeSystem();

      // Associate selected vibes with user
      await _vibeTagService.associateVibesWithEntity(
        entityId: currentUser.uid,
        entityType: 'user',
        vibeTagIds: _selectedVibes.toList(),
        source: 'onboarding',
        metadata: {
          'onboarding_version': '2.0_streamlined',
          'completion_time': DateTime.now().toIso8601String(),
        },
      );

      // Update user's vibe profile
      await _userProfileService.updateVibeProfileFromOnboarding(
        userId: currentUser.uid,
        selectedVibes: _selectedVibes.toList(),
        quizResponses: {
          'streamlined_onboarding': true,
          'selected_vibes': _selectedVibes.toList(),
          'step_completion_time': DateTime.now().toIso8601String(),
        },
        vibeIntensities: Map.fromEntries(
          _selectedVibes.map((vibe) => MapEntry(vibe, 0.8)), // Strong initial intensity
        ),
      );

      // Generate vibe title
      await _userProfileService.updateVibeTitle(currentUser.uid);

      // Navigate to home screen with celebration
      if (mounted) {
        _showCompletionCelebration();
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      if (mounted) {
        _showErrorDialog('Failed to complete setup. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVibeSelectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please select at least $_minVibeSelection vibes to continue'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletionCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to Wandr! 🎉',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your vibe profile is ready. Time to discover amazing places!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const EnhancedHomeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(),
                  _buildVibeSelectionStep(),
                  _buildCompletionStep(),
                ],
              ),
            ),
            
            // Navigation
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (_currentStep > 0)
                TextButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.explore,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Hey $_userName! 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Welcome to Wandr',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Discover places that match your vibe.\nConnect with like-minded explorers.\nCreate personalized place collections.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quick setup - takes less than 60 seconds',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibeSelectionStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: VibeSelectionGrid(
          initialSelectedVibes: _selectedVibes,
          onSelectionChanged: (vibes) {
            setState(() => _selectedVibes = vibes);
            HapticFeedback.selectionClick();
          },
          maxSelections: _maxVibeSelection,
          minSelections: _minVibeSelection,
          title: 'What\'s your vibe?',
          subtitle: 'Select $_minVibeSelection-$_maxVibeSelection vibes that describe the kind of places you love',
          showSearch: true,
        ),
      ),
    );
  }

  Widget _buildCompletionStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Completion illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green,
                      Colors.green.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.check,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Perfect! ✨',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Your vibe profile is ready',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Selected vibes preview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your vibes:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedVibes.map((vibeId) {
                        // Create a simplified vibe tag display
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            vibeId.capitalize(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'We\'ll use these to recommend places, people, and experiences that match your style.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
                child: const Text('Back'),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_currentStep == _totalSteps - 1) {
                  _completeOnboarding();
                } else if (_currentStep == 1 && _selectedVibes.length < _minVibeSelection) {
                  _showVibeSelectionError();
                } else {
                  _nextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_getButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Let\'s Start';
      case 1:
        return _selectedVibes.length >= _minVibeSelection ? 'Continue' : 'Select $_minVibeSelection+ vibes';
      case 2:
        return 'Complete Setup';
      default:
        return 'Next';
    }
  }
}

// ============================================================================
// HELPER EXTENSION
// ============================================================================

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}