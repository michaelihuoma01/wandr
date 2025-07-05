import 'package:flutter/material.dart';
import 'package:myapp/models/models.dart';
import 'package:myapp/screens/edit_itinerary_screen.dart';
import 'package:myapp/screens/enhanced_vibe_list_result_screen.dart';
import 'package:myapp/services/vibe_service.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/services/search_service.dart';
import 'package:myapp/services/board_service.dart';
import 'package:myapp/widgets/place_card.dart';

class VibeListResultScreen extends StatefulWidget {
  final VibeList vibeList;

  const VibeListResultScreen({super.key, required this.vibeList});

  @override
  State<VibeListResultScreen> createState() => _VibeListResultScreenState();
}

class _VibeListResultScreenState extends State<VibeListResultScreen> with TickerProviderStateMixin {
  final VibeService _vibeService = VibeService();
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();
  final BoardService _boardService = BoardService();
  bool _isSaving = false;
  
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _headerSlideAnimation = Tween<Offset>(begin: const Offset(0.0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildHeader(),
          if (widget.vibeList.isMultiStop && widget.vibeList.itineraryStops != null)
            _buildItineraryView()
          else
            _buildSimpleListView(),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.vibeList.isMultiStop ? 'Your Itinerary' : 'Your Vibe',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black87),
          onPressed: _showShareOptions,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'save_to_journal',
              child: Row(
                children: [
                  Icon(Icons.book),
                  SizedBox(width: 8),
                  Text('Save to Journal'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'regenerate',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Regenerate'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _headerSlideAnimation,
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.vibeList.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          if (widget.vibeList.specialOccasion != null && 
                              widget.vibeList.specialOccasion != 'none') ...[
                            const SizedBox(height: 8),
                            _buildSpecialOccasionBadge(),
                          ],
                        ],
                      ),
                    ),
                    _buildVibeTypeChip(),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  widget.vibeList.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Enhanced stats row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatChip(
                      Icons.place,
                      '${widget.vibeList.places.length} ${widget.vibeList.isMultiStop ? 'stops' : 'place'}',
                      Colors.blue,
                    ),
                    _buildStatChip(
                      Icons.access_time,
                      _formatDuration(widget.vibeList.estimatedDuration),
                      Colors.green,
                    ),
                    if (widget.vibeList.groupType != null)
                      _buildStatChip(
                        _getGroupIcon(widget.vibeList.groupType!),
                        _getGroupLabel(widget.vibeList.groupType!),
                        Colors.purple,
                      ),
                    _buildStatChip(
                      Icons.calendar_today,
                      _formatDate(widget.vibeList.createdAt),
                      Colors.orange,
                    ),
                  ],
                ),
                
                // Tags
                if (widget.vibeList.tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.vibeList.tags.take(5).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialOccasionBadge() {
    final occasion = widget.vibeList.specialOccasion!;
    String emoji = '🎉';
    String label = occasion.replaceAll('_', ' ').toUpperCase();
    
    switch (occasion) {
      case 'birthday':
        emoji = '🎂';
        break;
      case 'date_night':
        emoji = '💕';
        label = 'DATE NIGHT';
        break;
      case 'first_date':
        emoji = '✨';
        label = 'FIRST DATE';
        break;
      case 'anniversary':
        emoji = '💐';
        break;
      case 'team_dinner':
        emoji = '👔';
        label = 'TEAM EVENT';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.purple.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryView() {
    final stops = widget.vibeList.itineraryStops!;
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Your Itinerary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Follow this journey for the perfect experience',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Itinerary timeline
            ...stops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              final isLast = index == stops.length - 1;
              
              return AnimatedBuilder(
                animation: _listAnimationController,
                builder: (context, child) {
                  final delay = index * 0.1;
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(delay, 1.0, curve: Curves.easeOut),
                    ),
                  );
                  
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.5, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: _buildItineraryStop(stop, index, isLast),
                    ),
                  );
                },
              );
            }).toList(),
            
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryStop(ItineraryStop stop, int index, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 80,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor.withValues(alpha: 0.5),
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTimeSlotColor(stop.timeSlot).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getTimeSlotColor(stop.timeSlot).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTimeSlotIcon(stop.timeSlot),
                            size: 16,
                            color: _getTimeSlotColor(stop.timeSlot),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stop.timeSlot.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getTimeSlotColor(stop.timeSlot),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        stop.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Description
                if (stop.description != null)
                  Text(
                    stop.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Place card
                PlaceCard(
                  place: stop.place,
                  currentPosition: _locationService.currentPosition!,
                  processImageUrl: _searchService.processImageUrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleListView() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vibeList.places.length == 1 ? 'Your Perfect Spot' : 'Your Places',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.vibeList.places.length == 1 
                  ? 'The perfect place for your experience'
                  : 'Great places that match your vibe',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Simple list of places
            ...widget.vibeList.places.asMap().entries.map((entry) {
              final index = entry.key;
              final place = entry.value;
              
              return AnimatedBuilder(
                animation: _listAnimationController,
                builder: (context, child) {
                  final delay = index * 0.15;
                  final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _listAnimationController,
                      curve: Interval(delay, 1.0, curve: Curves.easeOut),
                    ),
                  );
                  
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.3, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: PlaceCard(
                          place: place,
                          currentPosition: _locationService.currentPosition!,
                          processImageUrl: _searchService.processImageUrl,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
    );
  }

  Color _getTimeSlotColor(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return Colors.orange;
      case 'afternoon':
        return Colors.blue;
      case 'evening':
        return Colors.purple;
      case 'night':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getTimeSlotIcon(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_cloudy;
      case 'evening':
        return Icons.brightness_6;
      case 'night':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  IconData _getGroupIcon(String groupType) {
    switch (groupType) {
      case 'solo':
        return Icons.person;
      case 'couple':
        return Icons.favorite;
      case 'small_group':
        return Icons.group;
      case 'large_group':
        return Icons.groups;
      default:
        return Icons.people;
    }
  }

  String _getGroupLabel(String groupType) {
    switch (groupType) {
      case 'solo':
        return 'Solo';
      case 'couple':
        return 'Couple';
      case 'small_group':
        return 'Small Group';
      case 'large_group':
        return 'Large Group';
      default:
        return 'Group';
    }
  }

  Widget _buildVibeTypeChip() {
    String emoji;
    Color color;
    
    switch (widget.vibeList.vibeType) {
      case 'romantic':
        emoji = '💕';
        color = Colors.pink;
        break;
      case 'adventurous':
        emoji = '🚀';
        color = Colors.orange;
        break;
      case 'morning':
        emoji = '☀️';
        color = Colors.yellow;
        break;
      case 'evening':
        emoji = '🌅';
        color = Colors.purple;
        break;
      case 'night':
        emoji = '🌙';
        color = Colors.indigo;
        break;
      default:
        emoji = '✨';
        color = Theme.of(context).primaryColor;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            widget.vibeList.vibeType.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saveToJournal,
              icon: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.book),
              label: Text(_isSaving ? 'Saving...' : 'Save to Journal'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _startJourney,
              icon: const Icon(Icons.navigation),
              label: Text(widget.vibeList.isMultiStop ? 'Start Itinerary' : 'Start Journey'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save_to_journal':
        _saveToJournal();
        break;
      case 'regenerate':
        _regenerateVibeList();
        break;
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share Your ${widget.vibeList.isMultiStop ? 'Itinerary' : 'Vibe'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.blue),
              title: const Text('Share with Circles'),
              subtitle: const Text('Send to your friend groups'),
              onTap: () {
                Navigator.pop(context);
                _shareWithCircles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.green),
              title: const Text('Copy Link'),
              subtitle: const Text('Copy shareable link'),
              onTap: () {
                Navigator.pop(context);
                _copyLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.orange),
              title: const Text('Share Externally'),
              subtitle: const Text('Share via other apps'),
              onTap: () {
                Navigator.pop(context);
                _shareExternally();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToJournal() async {
    if (widget.vibeList.isMultiStop) {
      _showSaveItineraryDialog();
    } else {
      _showSaveBoardDialog();
    }
  }

  void _showSaveBoardDialog() {
    final TextEditingController nameController = TextEditingController(text: widget.vibeList.title);
    final TextEditingController descController = TextEditingController(text: widget.vibeList.description);
    final TextEditingController tagsController = TextEditingController(text: widget.vibeList.tags.join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Save to Board'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Board Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveBoardToFirestore(
                nameController.text,
                descController.text,
                tagsController.text.split(',').map((e) => e.trim()).toList(),
              );
            },
            child: const Text('Save Board'),
          ),
        ],
      ),
    );
  }

  void _showSaveItineraryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItineraryScreen(vibeList: widget.vibeList),
      ),
    );
  }

  Future<void> _saveBoardToFirestore(String name, String description, List<String> tags) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _boardService.saveVibeListAsBoard(
        vibeList: widget.vibeList,
        name: name,
        description: description,
        customTags: tags,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.vibeList.isMultiStop ? 'Itinerary' : 'Board'} saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _startJourney() {
    if (widget.vibeList.places.isNotEmpty) {
      final firstPlace = widget.vibeList.places.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting ${widget.vibeList.isMultiStop ? 'itinerary' : 'journey'} to ${firstPlace.name}'),
          action: SnackBarAction(
            label: 'Navigate',
            onPressed: () {
              // Open maps app or navigation
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _regenerateVibeList() {
    Navigator.pop(context);
  }

  void _shareWithCircles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Circle sharing coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareExternally() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('External sharing coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}