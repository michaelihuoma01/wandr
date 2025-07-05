import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/onboarding_service.dart';
import '../../services/auth_service.dart';

class ContextualPreferencesScreen extends StatefulWidget {
  const ContextualPreferencesScreen({super.key});

  @override
  State<ContextualPreferencesScreen> createState() => _ContextualPreferencesScreenState();
}

class _ContextualPreferencesScreenState extends State<ContextualPreferencesScreen>
    with TickerProviderStateMixin {
  final OnboardingService _onboardingService = OnboardingService();
  final AuthService _authService = AuthService();

  late AnimationController _slideController;
  late AnimationController _scaleController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _scaleAnimations;

  bool _isProcessing = false;
  int _currentQuestionIndex = 0;
  
  final Map<String, dynamic> _responses = {};

  final List<QuickQuestion> _questions = [
    QuickQuestion(
      id: 'morning_person',
      title: 'Are you a morning person?',
      subtitle: 'This helps us suggest the perfect timing',
      emoji: '🌅',
      options: [
        QuickOption(id: 'yes', label: 'Early bird', icon: Icons.wb_sunny),
        QuickOption(id: 'no', label: 'Night owl', icon: Icons.nightlight_round),
      ],
    ),
    QuickQuestion(
      id: 'discovery_style',
      title: 'How do you like to discover?',
      subtitle: 'Your exploration personality',
      emoji: '🗺️',
      options: [
        QuickOption(id: 'planned', label: 'Plan ahead', icon: Icons.calendar_today),
        QuickOption(id: 'spontaneous', label: 'Go with the flow', icon: Icons.shuffle),
      ],
    ),
    QuickQuestion(
      id: 'social_energy',
      title: 'Your ideal social vibe?',
      subtitle: 'How you prefer to connect',
      emoji: '👥',
      options: [
        QuickOption(id: 'intimate', label: 'Small groups', icon: Icons.group_outlined),
        QuickOption(id: 'social', label: 'Big energy', icon: Icons.groups),
      ],
    ),
    QuickQuestion(
      id: 'experience_priority',
      title: 'What matters most to you?',
      subtitle: 'Your experience focus',
      emoji: '⭐',
      options: [
        QuickOption(id: 'authentic', label: 'Authentic vibes', icon: Icons.favorite_border),
        QuickOption(id: 'aesthetic', label: 'Instagram-worthy', icon: Icons.camera_alt),
      ],
    ),
    QuickQuestion(
      id: 'work_style',
      title: 'Do you work remotely?',
      subtitle: 'For workspace recommendations',
      emoji: '💻',
      options: [
        QuickOption(id: 'yes', label: 'Yes, often', icon: Icons.laptop_mac),
        QuickOption(id: 'no', label: 'Traditional office', icon: Icons.business_center),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create animations for each option
    _slideAnimations = List.generate(
      2, // Max options per question
      (index) => Tween<Offset>(
        begin: Offset(0.0, 0.5 + (index * 0.1)),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(
          index * 0.1,
          0.6 + (index * 0.1),
          curve: Curves.easeOutCubic,
        ),
      )),
    );

    _scaleAnimations = List.generate(
      2,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _scaleController,
        curve: Interval(
          index * 0.2,
          0.6 + (index * 0.2),
          curve: Curves.elasticOut,
        ),
      )),
    );
  }

  void _startAnimations() {
    _slideController.forward();
    _scaleController.forward();
  }

  void _resetAnimations() {
    _slideController.reset();
    _scaleController.reset();
    _startAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _selectOption(QuickOption option) {
    HapticFeedback.selectionClick();
    
    setState(() {
      _responses[_questions[_currentQuestionIndex].id] = option.id;
    });

    // Move to next question after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
        _resetAnimations();
      } else {
        _completePreferences();
      }
    });
  }

  Future<void> _completePreferences() async {
    if (_isProcessing) return;

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
        'contextualPrefs': {
          ..._responses,
          'completedAt': DateTime.now().toIso8601String(),
          'questionOrder': _questions.map((q) => q.id).toList(),
        }
      };

      await _onboardingService.progressToNextStep(onboardingState, stepResponses);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding/social-matching');
      }
    } catch (e) {
      _showError('Failed to save your preferences. Please try again.');
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
    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildQuestionContent(currentQuestion)),
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
                onPressed: () {
                  if (_currentQuestionIndex > 0) {
                    setState(() {
                      _currentQuestionIndex--;
                    });
                    _resetAnimations();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const Spacer(),
              _buildProgressIndicator(),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Preferences',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Just a few quick choices to personalize your experience',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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

  Widget _buildQuestionContent(QuickQuestion question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Question emoji and title
          SlideTransition(
            position: _slideAnimations[0],
            child: FadeTransition(
              opacity: _scaleAnimations[0],
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        question.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    question.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Options
          Column(
            children: question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              
              return SlideTransition(
                position: _slideAnimations[index % _slideAnimations.length],
                child: ScaleTransition(
                  scale: _scaleAnimations[index % _scaleAnimations.length],
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildOptionCard(option),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(QuickOption option) {
    return GestureDetector(
      onTap: () => _selectOption(option),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    
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
          // Progress bar
          Row(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          
          // Skip button
          if (!_isProcessing)
            TextButton(
              onPressed: () {
                // Skip current question and move to next
                if (_currentQuestionIndex < _questions.length - 1) {
                  setState(() {
                    _currentQuestionIndex++;
                  });
                  _resetAnimations();
                } else {
                  _completePreferences();
                }
              },
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          
          if (_isProcessing) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Creating your personalized experience...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

class QuickQuestion {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final List<QuickOption> options;

  QuickQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.options,
  });
}

class QuickOption {
  final String id;
  final String label;
  final IconData icon;

  QuickOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}