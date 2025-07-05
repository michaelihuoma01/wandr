import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/onboarding_service.dart';
import '../../services/auth_service.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  final OnboardingService _onboardingService = OnboardingService();
  final AuthService _authService = AuthService();

  late AnimationController _mainController;
  late AnimationController _floatingController;
  late AnimationController _textController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _floatingAnimation;

  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
    ));

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    // Title animations
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    ));

    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Subtitle animations
    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));

    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    ));

    // Button animations
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Floating animation for background elements
    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mainController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatingController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startOnboarding() async {
    if (_isStarting) return;

    setState(() {
      _isStarting = true;
    });

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _showError('Please sign in to continue');
        return;
      }

      // Initialize onboarding
      final onboardingState = await _onboardingService.initializeOnboarding(currentUser.uid);
      
      // Navigate to vibe wheel
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding/vibe-wheel');
      }
    } catch (e) {
      _showError('Failed to start onboarding. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.02),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildFloatingElements(),
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating emoji elements
            Positioned(
              top: 100 + (_floatingAnimation.value * 20),
              left: 50,
              child: Transform.rotate(
                angle: _floatingAnimation.value * 0.2,
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    '✨',
                    style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200 + (_floatingAnimation.value * -15),
              right: 80,
              child: Transform.rotate(
                angle: -_floatingAnimation.value * 0.3,
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    '🎯',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200 + (_floatingAnimation.value * 25),
              left: 80,
              child: Transform.rotate(
                angle: _floatingAnimation.value * 0.4,
                child: Opacity(
                  opacity: 0.4,
                  child: Text(
                    '🌟',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 300 + (_floatingAnimation.value * -20),
              right: 60,
              child: Transform.rotate(
                angle: -_floatingAnimation.value * 0.2,
                child: Opacity(
                  opacity: 0.3,
                  child: Text(
                    '💫',
                    style: TextStyle(
                      fontSize: 22,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            _buildAnimatedLogo(),
            const SizedBox(height: 40),
            _buildAnimatedTitle(),
            const SizedBox(height: 16),
            _buildAnimatedSubtitle(),
            const SizedBox(height: 8),
            _buildVibeDescription(),
            const Spacer(),
            _buildAnimatedButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFadeAnimation,
          child: ScaleTransition(
            scale: _logoScaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                Icons.explore,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _titleFadeAnimation,
          child: SlideTransition(
            position: _titleSlideAnimation,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ).createShader(bounds),
              child: Text(
                'Let\'s Find Your Vibe Tribe!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSubtitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _subtitleFadeAnimation,
          child: SlideTransition(
            position: _subtitleSlideAnimation,
            child: Text(
              '3 minutes to unlock your perfect experiences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVibeDescription() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _subtitleFadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
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
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Discover Your Vibe DNA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'ll analyze your preferences to create a unique taste profile, then connect you with like-minded explorers and personalized recommendations.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedButton() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _buttonFadeAnimation,
          child: SlideTransition(
            position: _buttonSlideAnimation,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isStarting ? null : _startOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                    child: _isStarting
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
                              const Icon(Icons.rocket_launch, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Start My Vibe Journey',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(true),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                    const SizedBox(width: 8),
                    _buildProgressDot(false),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Step 1 of 4',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
}