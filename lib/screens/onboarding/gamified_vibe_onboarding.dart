// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../models/models.dart';
// import '../../models/circle_models.dart';
// import '../../services/comprehensive_vibe_system.dart';
// import '../../services/unified_circle_service.dart';
// import '../../services/auth_service.dart';
// import '../../services/shared_utilities_service.dart';
// import '../enhanced_home_screen.dart';

// // ============================================================================
// // GAMIFIED VIBE ONBOARDING - Engaging & Brief Flow 🎮
// // "Build Your Vibe Profile" - 3 Quick Steps with Instant Rewards
// // ============================================================================

// class GamifiedVibeOnboarding extends StatefulWidget {
//   const GamifiedVibeOnboarding({super.key});

//   @override
//   State<GamifiedVibeOnboarding> createState() => _GamifiedVibeOnboardingState();
// }

// class _GamifiedVibeOnboardingState extends State<GamifiedVibeOnboarding>
//     with TickerProviderStateMixin {
//   final ComprehensiveVibeSystem _vibeSystem = ComprehensiveVibeSystem();
//   final UnifiedCircleService _circleService = UnifiedCircleService();
//   final AuthService _authService = AuthService();
//   final SharedUtilitiesService _utils = SharedUtilitiesService();

//   late AnimationController _progressController;
//   late AnimationController _celebrationController;
//   late Animation<double> _progressAnimation;
//   late Animation<double> _scaleAnimation;

//   int _currentStep = 0;
//   Set<String> _selectedVibes = {};
//   List<Map<String, dynamic>> _smartSuggestions = [];
//   Map<String, List<Map<String, dynamic>>> _liveRecommendations = {
//     'circles': [],
//     'users': [],
//     'places': [],
//   };
//   bool _isLoading = false;
//   int _vibeScore = 0;

//   static const int _totalSteps = 3;
//   static const int _minVibeSelection = 3;
//   static const int _maxVibeSelection = 8;

//   @override
//   void initState() {
//     super.initState();
//     _setupAnimations();
//     _loadInitialSuggestions();
//   }

//   @override
//   void dispose() {
//     _progressController.dispose();
//     _celebrationController.dispose();
//     super.dispose();
//   }

//   void _setupAnimations() {
//     _progressController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
    
//     _celebrationController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );

//     _progressAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _progressController,
//       curve: Curves.easeInOut,
//     ));

//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.2,
//     ).animate(CurvedAnimation(
//       parent: _celebrationController,
//       curve: Curves.elasticOut,
//     ));
//   }

//   Future<void> _loadInitialSuggestions() async {
//     if (!_utils.isAuthenticated) return;
    
//     setState(() => _isLoading = true);

//     try {
//       _smartSuggestions = await _vibeSystem.getContextualVibeSuggestions(
//         userId: _utils.currentUserId!,
//         limit: 12,
//       );
//     } catch (e) {
//       print('Error loading suggestions: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _updateLiveRecommendations() async {
//     if (_selectedVibes.isEmpty || !_utils.isAuthenticated) return;

//     try {
//       // Get matching circles
//       final compatibleCircles = await _circleService.getVibeCompatibleCircles(
//         _utils.currentUserId!,
//         limit: 5,
//         minCompatibility: 0.3,
//       );
      
//       // Get matching places (simplified for demo)
//       final placeRecommendations = await _vibeSystem.getContextualRecommendations(
//         userId: _utils.currentUserId!,
//         limit: 6,
//       );

//       setState(() {
//         _liveRecommendations['circles'] = compatibleCircles;
//         _liveRecommendations['places'] = placeRecommendations;
//         _vibeScore = (_selectedVibes.length * 10) + 
//                     (compatibleCircles.length * 5) + 
//                     (placeRecommendations.length * 2);
//       });
//     } catch (e) {
//       print('Error updating recommendations: $e');
//     }
//   }

//   void _onVibeToggle(String vibeId) {
//     setState(() {
//       if (_selectedVibes.contains(vibeId)) {
//         _selectedVibes.remove(vibeId);
//       } else {
//         if (_selectedVibes.length >= _maxVibeSelection) {
//           _showVibeLimit();
//           return;
//         }
//         _selectedVibes.add(vibeId);
//         _celebrateVibeSelection();
//       }
//     });

//     // Update recommendations in real-time
//     _updateLiveRecommendations();
    
//     HapticFeedback.selectionClick();
//   }

//   void _celebrateVibeSelection() {
//     _celebrationController.forward().then((_) {
//       _celebrationController.reverse();
//     });
//   }

//   void _showVibeLimit() {
//     HapticFeedback.lightImpact();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Max $_maxVibeSelection vibes! Remove one to add another.'),
//         backgroundColor: Colors.orange,
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _nextStep() {
//     if (_currentStep < _totalSteps - 1) {
//       setState(() => _currentStep++);
//       _progressController.forward();
      
//       if (_currentStep == 1) {
//         // Step 2: Show live recommendations
//         _updateLiveRecommendations();
//       }
//     }
//   }

//   void _previousStep() {
//     if (_currentStep > 0) {
//       setState(() => _currentStep--);
//       _progressController.reverse();
//     }
//   }

//   Future<void> _completeOnboarding() async {
//     if (_selectedVibes.length < _minVibeSelection) {
//       _showMinVibesError();
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final currentUser = _authService.currentUser;
//       if (currentUser == null) throw Exception('No user found');

//       // Activate selected vibes
//       await _vibeSystem.activateVibesForUser(
//         userId: currentUser.uid,
//         vibeIds: _selectedVibes.toList(),
//         intensities: Map.fromEntries(
//           _selectedVibes.map((vibe) => MapEntry(vibe, 0.8)),
//         ),
//       );

//       // Show completion celebration
//       if (mounted) {
//         _showCompletionCelebration();
//       }
//     } catch (e) {
//       print('Error completing onboarding: $e');
//       if (mounted) {
//         _showErrorDialog('Setup failed. Please try again.');
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _showMinVibesError() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Pick at least $_minVibeSelection vibes to continue! ✨'),
//         backgroundColor: Colors.deepPurple,
//         behavior: SnackBarBehavior.floating,
//         action: SnackBarAction(
//           label: 'Got it!',
//           textColor: Colors.white,
//           onPressed: () {},
//         ),
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Oops! 😅'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Try Again'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showCompletionCelebration() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('🎉', style: TextStyle(fontSize: 64)),
//             const SizedBox(height: 16),
//             Text(
//               'Vibe Profile Complete!',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.deepPurple,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.deepPurple.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 'Vibe Score: $_vibeScore 🔥',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.deepPurple,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Ready to discover amazing places and connect with your vibe tribe!',
//               style: Theme.of(context).textTheme.bodyMedium,
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//         actions: [
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (context) => const EnhancedHomeScreen()),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               child: const Text('Let\'s Explore! 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildProgressHeader(),
//             Expanded(child: _buildStepContent()),
//             _buildNavigationFooter(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProgressHeader() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Step ${_currentStep + 1} of $_totalSteps',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.deepPurple.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Text(
//                   'Score: $_vibeScore 🔥',
//                   style: const TextStyle(
//                     color: Colors.deepPurple,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           AnimatedBuilder(
//             animation: _progressAnimation,
//             builder: (context, child) {
//               return LinearProgressIndicator(
//                 value: (_currentStep + _progressAnimation.value) / _totalSteps,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
//                 minHeight: 6,
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepContent() {
//     switch (_currentStep) {
//       case 0:
//         return _buildVibeSelectionStep();
//       case 1:
//         return _buildLivePreviewStep();
//       case 2:
//         return _buildCompletionStep();
//       default:
//         return _buildVibeSelectionStep();
//     }
//   }

//   Widget _buildVibeSelectionStep() {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'What\'s your vibe? ✨',
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Pick $_minVibeSelection-$_maxVibeSelection vibes that match your energy',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 20),
//           _buildVibeCounter(),
//           const SizedBox(height: 16),
//           Expanded(
//             child: _isLoading 
//                 ? const Center(child: CircularProgressIndicator())
//                 : _buildVibeGrid(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVibeCounter() {
//     return Row(
//       children: [
//         Expanded(
//           child: Text(
//             '${_selectedVibes.length} selected',
//             style: TextStyle(
//               color: _selectedVibes.length >= _minVibeSelection 
//                   ? Colors.green 
//                   : Colors.orange,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         if (_selectedVibes.isNotEmpty)
//           TextButton(
//             onPressed: () {
//               setState(() => _selectedVibes.clear());
//               _updateLiveRecommendations();
//             },
//             child: const Text('Clear All'),
//           ),
//       ],
//     );
//   }

//   Widget _buildVibeGrid() {
//     return GridView.builder(
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 2.2,
//       ),
//       itemCount: _smartSuggestions.length,
//       itemBuilder: (context, index) {
//         final suggestion = _smartSuggestions[index];
//         final vibeId = suggestion['vibeId'] as String;
//         final vibeData = suggestion['vibeData'] as Map<String, dynamic>;
//         final isSelected = _selectedVibes.contains(vibeId);
//         final isNew = suggestion['isNew'] as bool? ?? true;

//         return AnimatedBuilder(
//           animation: _scaleAnimation,
//           builder: (context, child) {
//             return Transform.scale(
//               scale: isSelected ? _scaleAnimation.value : 1.0,
//               child: GestureDetector(
//                 onTap: () => _onVibeToggle(vibeId),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: isSelected 
//                         ? Colors.deepPurple.withOpacity(0.1)
//                         : Colors.white,
//                     border: Border.all(
//                       color: isSelected 
//                           ? Colors.deepPurple
//                           : Colors.grey[300]!,
//                       width: isSelected ? 2 : 1,
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
//                         blurRadius: isSelected ? 12 : 6,
//                         offset: const Offset(0, 3),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: isSelected 
//                                   ? Colors.deepPurple.withOpacity(0.1)
//                                   : Colors.grey[100],
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               ComprehensiveVibeSystem.vibeCategories[vibeData['category']]?['emoji'] ?? '✨',
//                               style: const TextStyle(fontSize: 20),
//                             ),
//                           ),
//                           if (isSelected)
//                             Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: const BoxDecoration(
//                                 color: Colors.deepPurple,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.check,
//                                 color: Colors.white,
//                                 size: 14,
//                               ),
//                             ),
//                           if (isNew && !isSelected)
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: Colors.orange,
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: const Text(
//                                 'NEW',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                       const Spacer(),
//                       Text(
//                         vibeData['displayName'],
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                           color: isSelected ? Colors.deepPurple : Colors.grey[800],
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         vibeData['description'],
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 11,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildLivePreviewStep() {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Your Vibe Magic! 🔮',
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'See what you\'ll discover with your selected vibes',
//             style: TextStyle(color: Colors.grey[600], fontSize: 16),
//           ),
//           const SizedBox(height: 20),
//           _buildSelectedVibesChips(),
//           const SizedBox(height: 20),
//           Expanded(child: _buildRecommendationsPreviews()),
//         ],
//       ),
//     );
//   }

//   Widget _buildSelectedVibesChips() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Your Selected Vibes:',
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: _selectedVibes.map((vibeId) {
//             final vibeData = ComprehensiveVibeSystem.comprehensiveVibeTags[vibeId];
//             if (vibeData == null) return const SizedBox.shrink();
            
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.deepPurple.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     ComprehensiveVibeSystem.vibeCategories[vibeData['category']]?['emoji'] ?? '✨',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     vibeData['displayName'],
//                     style: const TextStyle(
//                       color: Colors.deepPurple,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildRecommendationsPreviews() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildRecommendationSection(
//             title: '🎯 Perfect Circles for You',
//             items: _liveRecommendations['circles'] ?? [],
//             emptyMessage: 'Finding your vibe tribe...',
//           ),
//           const SizedBox(height: 20),
//           _buildRecommendationSection(
//             title: '📍 Places You\'ll Love',
//             items: _liveRecommendations['places'] ?? [],
//             emptyMessage: 'Discovering amazing spots...',
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecommendationSection({
//     required String title,
//     required List<Map<String, dynamic>> items,
//     required String emptyMessage,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         if (items.isEmpty)
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 const CircularProgressIndicator(strokeWidth: 2),
//                 const SizedBox(width: 12),
//                 Text(emptyMessage),
//               ],
//             ),
//           )
//         else
//           SizedBox(
//             height: 100,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: items.length,
//               itemBuilder: (context, index) {
//                 final item = items[index];
//                 return Container(
//                   width: 160,
//                   margin: const EdgeInsets.only(right: 12),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.grey[300]!),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item['name'] ?? item['title'] ?? 'Amazing Place',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         item['description'] ?? 'Perfect match for your vibes!',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 10,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const Spacer(),
//                       Row(
//                         children: [
//                           Icon(Icons.star, color: Colors.orange, size: 12),
//                           const SizedBox(width: 2),
//                           Text(
//                             '${(0.7 + (index * 0.1)).toStringAsFixed(1)} match',
//                             style: const TextStyle(fontSize: 10),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildCompletionStep() {
//     return Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text('🎉', style: TextStyle(fontSize: 80)),
//           const SizedBox(height: 24),
//           Text(
//             'You\'re All Set!',
//             style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Your vibe profile is ready to connect you with amazing places, people, and experiences!',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 16,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 32),
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   'Final Vibe Score',
//                   style: TextStyle(
//                     color: Colors.deepPurple,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '$_vibeScore 🔥',
//                   style: const TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.deepPurple,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   '${_selectedVibes.length} active vibes • ${_liveRecommendations['circles']?.length ?? 0} matching circles',
//                   style: TextStyle(
//                     color: Colors.deepPurple.withOpacity(0.7),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavigationFooter() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           if (_currentStep > 0)
//             Expanded(
//               child: OutlinedButton(
//                 onPressed: _previousStep,
//                 style: OutlinedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   side: const BorderSide(color: Colors.deepPurple),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: const Text('Back'),
//               ),
//             ),
          
//           if (_currentStep > 0) const SizedBox(width: 16),
          
//           Expanded(
//             flex: 2,
//             child: ElevatedButton(
//               onPressed: _isLoading ? null : () {
//                 if (_currentStep == _totalSteps - 1) {
//                   _completeOnboarding();
//                 } else if (_currentStep == 0 && _selectedVibes.length < _minVibeSelection) {
//                   _showMinVibesError();
//                 } else {
//                   _nextStep();
//                 }
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 disabledBackgroundColor: Colors.grey[300],
//               ),
//               child: _isLoading
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : Text(
//                       _getButtonText(),
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getButtonText() {
//     switch (_currentStep) {
//       case 0:
//         return _selectedVibes.length >= _minVibeSelection 
//             ? 'See My Matches! ✨' 
//             : 'Pick ${_minVibeSelection - _selectedVibes.length} More';
//       case 1:
//         return 'Looking Good! 🚀';
//       case 2:
//         return 'Start Exploring! 🎉';
//       default:
//         return 'Continue';
//     }
//   }
// }