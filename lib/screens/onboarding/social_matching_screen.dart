import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/onboarding_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_persona_service.dart';

class SocialMatchingScreen extends StatefulWidget {
  const SocialMatchingScreen({super.key});

  @override
  State<SocialMatchingScreen> createState() => _SocialMatchingScreenState();
}

class _SocialMatchingScreenState extends State<SocialMatchingScreen>
    with TickerProviderStateMixin {
  final OnboardingService _onboardingService = OnboardingService();
  final AuthService _authService = AuthService();

  late AnimationController _loadingController;
  late AnimationController _revealController;
  late AnimationController _celebrationController;
  
  late Animation<double> _loadingAnimation;
  late Animation<double> _revealAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = true;
  bool _isCompleting = false;
  OnboardingResult? _result;
  UserPersona? _persona;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMatches();
  }

  void _setupAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _revealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeInOut,
    ));

    _loadingController.repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _revealController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    try {
      // Simulate analysis time for better UX
      await Future.delayed(const Duration(milliseconds: 2500));

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

      // Complete onboarding
      final result = await _onboardingService.completeOnboarding(onboardingState);
      
      if (result.success) {
        setState(() {
          _result = result;
          _persona = result.persona;
          _isLoading = false;
        });

        _loadingController.stop();
        _revealController.forward();
        
        // Add celebration animation after reveal
        Future.delayed(const Duration(milliseconds: 400), () {
          _celebrationController.forward();
          HapticFeedback.mediumImpact();
        });
      } else {
        _showError(result.error ?? 'Failed to complete onboarding');
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      // Add haptic feedback
      HapticFeedback.heavyImpact();

      // Navigate to home with celebration
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      _showError('Failed to complete setup. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
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
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading ? _buildLoadingView() : _buildResultsView(),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                      transform: GradientRotation(_loadingAnimation.value * 2 * 3.14159),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 60,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Text(
                      _getLoadingText(_loadingAnimation.value),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getLoadingSubtext(_loadingAnimation.value),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    return AnimatedBuilder(
      animation: _revealAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _revealAnimation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _revealAnimation.value) * 50),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
                _buildBottomPanel(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              _buildProgressIndicator(),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Vibe DNA is Ready!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
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
        _buildProgressDot(true),
        const SizedBox(width: 8),
        _buildProgressDot(true),
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

  Widget _buildContent() {
    if (_persona == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildPersonaCard(),
          const SizedBox(height: 24),
          _buildMatchingResults(),
          const SizedBox(height: 24),
          _buildFeedPreview(),
        ],
      ),
    );
  }

  Widget _buildPersonaCard() {
    if (_persona == null) return const SizedBox();

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_bounceAnimation.value * 0.1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${_persona!.emoji} ${_persona!.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _persona!.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _persona!.primaryVibes.map((vibe) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      vibe.capitalize(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchingResults() {
    final matches = _result?.initialMatches;
    if (matches == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Vibe Tribe Awaits',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Circle matches
        if (matches.circleMatches.isNotEmpty) ...[
          _buildMatchSection(
            title: 'Perfect Circles',
            subtitle: '${matches.circleMatches.length} communities match your vibe',
            icon: Icons.group,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
        ],

        // User matches
        if (matches.userMatches.isNotEmpty) ...[
          _buildMatchSection(
            title: 'Kindred Spirits',
            subtitle: '${matches.userMatches.length} like-minded explorers found',
            icon: Icons.people,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
        ],

        // Board matches
        if (matches.boardMatches.isNotEmpty) ...[
          _buildMatchSection(
            title: 'Curated Collections',
            subtitle: '${matches.boardMatches.length} boards match your taste',
            icon: Icons.collections_bookmark,
            color: Colors.purple,
          ),
        ],
      ],
    );
  }

  Widget _buildMatchSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Personalized Feed',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ve curated a personalized feed of experiences, places, and people that match your unique vibe profile.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildPreviewCards(),
        ],
      ),
    );
  }

  Widget _buildPreviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniCard(
            '🌟',
            'Trending Now',
            'Hot spots in your area',
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniCard(
            '💎',
            'Hidden Gems',
            'Secret local favorites',
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard(String emoji, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
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
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCompleting ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: _isCompleting
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
                        const Icon(Icons.explore, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Start Exploring',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome to your personalized exploration journey!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getLoadingText(double progress) {
    if (progress < 0.3) return 'Analyzing Your Vibe...';
    if (progress < 0.6) return 'Finding Your Tribe...';
    if (progress < 0.9) return 'Curating Your Feed...';
    return 'Almost Ready!';
  }

  String _getLoadingSubtext(double progress) {
    if (progress < 0.3) return 'Processing your unique preferences';
    if (progress < 0.6) return 'Matching you with like-minded explorers';
    if (progress < 0.9) return 'Creating personalized recommendations';
    return 'Finalizing your experience';
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }
}