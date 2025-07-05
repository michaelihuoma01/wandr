import 'package:flutter/material.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/services/vibe_service.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/screens/vibe_list_result_screen.dart';
import 'package:myapp/screens/enhanced_vibe_list_result_screen.dart';

class VibeQuizScreen extends StatefulWidget {
  const VibeQuizScreen({super.key});

  @override
  State<VibeQuizScreen> createState() => _VibeQuizScreenState();
}

class _VibeQuizScreenState extends State<VibeQuizScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  final Map<String, dynamic> _answers = {};
  final VibeService _vibeService = VibeService();
  final AuthService _authService = AuthService();
  bool _isGenerating = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final List<QuizStep> _steps = [
    // Step 1: Group Type & Occasion (Combined)
    QuizStep(
      id: 'group_and_occasion',
      title: 'Who\'s joining and what\'s the occasion?',
      subtitle: 'Tell us about your group and if it\'s a special event',
      questions: [
        QuizQuestion(
          id: 'group_type',
          question: 'Who are you planning this for?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption('solo', 'Just me', '🧘', 'Solo adventure'),
            QuizOption('couple', 'Me & my partner', '💕', 'Couple\'s time'),
            QuizOption('small_group', '3-5 friends', '👥', 'Small group'),
            QuizOption('large_group', '6+ people', '🎉', 'Large group'),
          ],
        ),
        QuizQuestion(
          id: 'special_occasion',
          question: 'Is this for a special occasion?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption('none', 'Just having fun', '😊', 'Casual hangout'),
            QuizOption('date_night', 'Date night', '💕', 'Romantic evening'),
            QuizOption('first_date', 'First date', '✨', 'Getting to know each other'),
            QuizOption('birthday', 'Birthday celebration', '🎂', 'Party time'),
            QuizOption('anniversary', 'Anniversary', '💐', 'Special milestone'),
            QuizOption('team_dinner', 'Team/work event', '👔', 'Professional gathering'),
            QuizOption('celebration', 'General celebration', '🎊', 'Something to celebrate'),
          ],
        ),
      ],
    ),
    
    // Step 2: Spot Type & Time
    QuizStep(
      id: 'experience_type',
      title: 'What kind of experience do you want?',
      subtitle: 'Single destination or multiple stops?',
      questions: [
        QuizQuestion(
          id: 'spot_type',
          question: 'How many places do you want to visit?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption('single', 'One perfect spot', '🎯', 'Focus on one great place'),
            QuizOption('multiple', 'Multiple stops', '🗺️', 'Create an itinerary'),
          ],
        ),
        QuizQuestion(
          id: 'time_preference',
          question: 'What time works best?',
          type: QuestionType.singleChoice,
          options: [
            QuizOption('morning', 'Morning vibes', '☀️', '6AM - 11AM'),
            QuizOption('midday', 'Afternoon energy', '🌞', '11AM - 4PM'),
            QuizOption('evening', 'Golden hour', '🌅', '4PM - 7PM'),
            QuizOption('night', 'Night scene', '🌙', '7PM - 12AM'),
            QuizOption('full_day', 'All day adventure', '📅', 'Morning to night'),
          ],
        ),
      ],
    ),
    
    // Step 3: Vibe & Places (Combined)
    QuizStep(
      id: 'vibe_and_places',
      title: 'What\'s your vibe?',
      subtitle: 'Choose your mood and favorite types of places',
      questions: [
        QuizQuestion(
          id: 'vibe_style',
          question: 'What mood are you going for?',
          type: QuestionType.multiChoice,
          options: [
            QuizOption('romantic', 'Romantic & intimate', '💕', 'Perfect for connection'),
            QuizOption('adventurous', 'Adventurous & unique', '🚀', 'Try something new'),
            QuizOption('relaxing', 'Calm & peaceful', '🧘', 'Unwind and chill'),
            QuizOption('social', 'Social & lively', '🎉', 'Meet people and have fun'),
            QuizOption('cultural', 'Cultural & inspiring', '🎨', 'Art, history, learning'),
            QuizOption('energetic', 'High energy & active', '⚡', 'Get moving and energized'),
          ],
        ),
        QuizQuestion(
          id: 'place_types',
          question: 'What types of places do you love?',
          type: QuestionType.multiChoice,
          options: [
            QuizOption('food', 'Restaurants & cafes', '🍽️', 'Great food experiences'),
            QuizOption('drinks', 'Bars & lounges', '🍸', 'Cocktails and conversations'),
            QuizOption('entertainment', 'Shows & entertainment', '🎭', 'Live performances'),
            QuizOption('culture', 'Museums & galleries', '🏛️', 'Art and culture'),
            QuizOption('nature', 'Parks & outdoors', '🌳', 'Fresh air and nature'),
            QuizOption('shopping', 'Shopping & markets', '🛍️', 'Retail therapy'),
            QuizOption('wellness', 'Spas & wellness', '💆', 'Self-care and relaxation'),
            QuizOption('nightlife', 'Clubs & nightlife', '🕺', 'Dance the night away'),
          ],
        ),
      ],
    ),
    
    // Step 4: Budget Preference
    QuizStep(
      id: 'budget',
      title: 'What\'s your budget like?',
      subtitle: 'Choose your spending comfort level',
      questions: [
        QuizQuestion(
          id: 'budget',
          question: 'Select your budget preference',
          type: QuestionType.singleChoice,
          options: [
            QuizOption('\$', 'Budget-friendly', '💰', 'Great value options'),
            QuizOption('\$\$', 'Moderate spending', '💳', 'Mid-range places'),
            QuizOption('\$\$\$', 'Premium experience', '💎', 'High-end options'),
            QuizOption('no_preference', 'Money\'s no object', '🤷', 'Best of the best'),
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vibe Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: _isGenerating ? _buildGeneratingView() : _buildStepView(),
            ),
            if (!_isGenerating) _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentStep + 1) / _steps.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepView() {
    final step = _steps[_currentStep];
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  itemCount: step.questions.length,
                  itemBuilder: (context, questionIndex) {
                    final question = step.questions[questionIndex];
                    return _buildQuestion(question, questionIndex);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(QuizQuestion question, int questionIndex) {
    return Container(
      margin: EdgeInsets.only(bottom: questionIndex < _steps[_currentStep].questions.length - 1 ? 32 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ...question.options.map((option) => _buildOptionCard(question, option)),
        ],
      ),
    );
  }

  Widget _buildOptionCard(QuizQuestion question, QuizOption option) {
    final isSelected = question.type == QuestionType.multiChoice
        ? (_answers[question.id] as List<String>?)?.contains(option.value) ?? false
        : _answers[question.id] == option.value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectOption(question, option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.white,
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
                blurRadius: isSelected ? 15 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    option.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[800],
                      ),
                    ),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '✨ Creating your perfect vibe list...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We\'re finding the best spots that match your vibe',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getGeneratingTip(),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGeneratingTip() {
    final tips = [
      'Pro tip: Save great spots to your journal for later!',
      'Tip: You can share your vibe list with friends',
      'Did you know? We personalize based on your preferences',
      'Fun fact: Each vibe list is unique to your choices',
    ];
    return tips[DateTime.now().millisecond % tips.length];
  }

  Widget _buildNavigationButtons() {
    final canGoNext = _canProceedToNext();
    final isLastStep = _currentStep == _steps.length - 1;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back', style: TextStyle(fontSize: 16)),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canGoNext ? (isLastStep ? _generateVibeList : _goNext) : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                isLastStep ? 'Generate My Vibe List ✨' : 'Continue',
                style: const TextStyle(
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

  bool _canProceedToNext() {
    final step = _steps[_currentStep];
    for (final question in step.questions) {
      if (!_answers.containsKey(question.id)) {
        return false;
      }
      if (question.type == QuestionType.multiChoice) {
        final answers = _answers[question.id] as List<String>?;
        if (answers == null || answers.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _selectOption(QuizQuestion question, QuizOption option) {
    setState(() {
      if (question.type == QuestionType.multiChoice) {
        final currentAnswers = (_answers[question.id] as List<String>?) ?? <String>[];
        if (currentAnswers.contains(option.value)) {
          currentAnswers.remove(option.value);
        } else {
          currentAnswers.add(option.value);
        }
        _answers[question.id] = currentAnswers;
      } else {
        _answers[question.id] = option.value;
      }
    });
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animateTransition();
    }
  }

  void _goNext() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animateTransition();
    }
  }

  void _animateTransition() {
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _generateVibeList() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final preferences = _convertAnswersToPreferences();
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final vibeList = await _vibeService.generateVibeList(
        preferences: preferences,
        userId: user.uid,
      );

      if (vibeList != null && mounted) {
        // Choose the appropriate screen based on whether enhanced categories are available
        final hasEnhancedCategories = vibeList.enhancedCategories != null && 
                                      vibeList.enhancedCategories!.isNotEmpty;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => hasEnhancedCategories 
              ? EnhancedVibeListResultScreen(vibeList: vibeList)
              : VibeListResultScreen(vibeList: vibeList),
          ),
        );
      } else {
        _showErrorDialog('Failed to generate vibe list. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  VibePreferences _convertAnswersToPreferences() {
    final vibeStyles = (_answers['vibe_style'] as List<String>?) ?? [];
    final placeTypes = (_answers['place_types'] as List<String>?) ?? ['food'];
    
    // Enhanced place type mapping
    final mappedPlaceTypes = <String>[];
    for (final type in placeTypes) {
      switch (type) {
        case 'food':
          mappedPlaceTypes.addAll(['restaurant', 'cafe', 'bakery']);
          break;
        case 'drinks':
          mappedPlaceTypes.addAll(['bar', 'lounge', 'wine_bar']);
          break;
        case 'entertainment':
          mappedPlaceTypes.addAll(['movie_theater', 'bowling_alley', 'amusement_park']);
          break;
        case 'culture':
          mappedPlaceTypes.addAll(['museum', 'art_gallery', 'library', 'theater']);
          break;
        case 'nature':
          mappedPlaceTypes.addAll(['park', 'beach', 'hiking_area', 'garden']);
          break;
        case 'shopping':
          mappedPlaceTypes.addAll(['shopping_mall', 'store', 'market']);
          break;
        case 'wellness':
          mappedPlaceTypes.addAll(['spa', 'gym', 'yoga_studio']);
          break;
        case 'nightlife':
          mappedPlaceTypes.addAll(['night_club', 'dance_club', 'karaoke']);
          break;
      }
    }

    // Multi-spot categories for multiple stops with smart time-based suggestions
    List<String>? multiSpotCategories;
    if (_answers['spot_type'] == 'multiple') {
      multiSpotCategories = _generateSmartMultiSpotCategories();
    }

    return VibePreferences(
      preferredVibes: vibeStyles,
      preferredPlaceTypes: mappedPlaceTypes,
      maxDistance: 25,
      maxDuration: null, // Remove duration constraint
      priceLevel: _answers['budget'] == 'no_preference' ? null : _answers['budget'],
      minRating: 3.5,
      groupType: _answers['group_type'],
      spotType: _answers['spot_type'],
      specialOccasion: _answers['special_occasion'],
      multiSpotCategories: multiSpotCategories,
    );
  }

  List<String> _generateSmartMultiSpotCategories() {
    final occasion = _answers['special_occasion'];
    final timePreference = _answers['time_preference'];
    final placeTypes = (_answers['place_types'] as List<String>?) ?? [];
    
    // Special occasion-based categories
    if (occasion != null && occasion != 'none') {
      switch (occasion) {
        case 'birthday':
          return ['brunch', 'activity', 'dinner', 'nightlife'];
        case 'date_night':
          return ['cocktails', 'dinner', 'dessert'];
        case 'first_date':
          return ['coffee', 'casual dining', 'activity'];
        case 'anniversary':
          return ['champagne bar', 'fine dining', 'romantic lounge'];
        case 'team_dinner':
          return ['welcome drinks', 'group dining', 'after party'];
        case 'celebration':
          return ['aperitif', 'celebration dinner', 'party venue'];
      }
    }
    
    // Time-based smart suggestions
    switch (timePreference) {
      case 'morning':
        return ['breakfast spot', 'coffee & pastries', 'morning activity'];
      case 'midday':
        return ['brunch', 'lunch venue', 'afternoon cafe'];
      case 'evening':
        return ['sunset drinks', 'dinner', 'evening lounge'];
      case 'night':
        return ['cocktail bar', 'late dinner', 'nightlife'];
      case 'full_day':
        return ['morning cafe', 'lunch spot', 'dinner venue', 'night cap'];
      default:
        // Fallback based on place types
        if (placeTypes.contains('drinks')) {
          return ['aperitif', 'main venue', 'after party'];
        } else if (placeTypes.contains('food')) {
          return ['starter spot', 'main dining', 'dessert place'];
        } else {
          return ['first stop', 'main activity', 'wind down'];
        }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oops!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// Enhanced data classes
class QuizStep {
  final String id;
  final String title;
  final String subtitle;
  final List<QuizQuestion> questions;

  QuizStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.questions,
  });
}

class QuizQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<QuizOption> options;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
  });
}

class QuizOption {
  final String value;
  final String label;
  final String emoji;
  final String description;

  QuizOption(this.value, this.label, this.emoji, this.description);
}

enum QuestionType {
  singleChoice,
  multiChoice,
}