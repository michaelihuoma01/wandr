import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../models/circle_models.dart'; // Ensure this file exports the Circle class
import '../../models/vibe_tag_models.dart';
import '../../services/enhanced_circle_service.dart';
import '../../services/vibe_tag_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/vibe_selection_widgets.dart';

// ============================================================================
// CIRCLE VIBE BOARD MANAGEMENT SCREEN
// ============================================================================

class CircleVibeBoardManagementScreen extends StatefulWidget {
  final String circleId;
  final VibeCircle circle;

  const CircleVibeBoardManagementScreen({
    super.key,
    required this.circleId,
    required this.circle,
  });

  @override
  State<CircleVibeBoardManagementScreen> createState() => _CircleVibeBoardManagementScreenState();
}

class _CircleVibeBoardManagementScreenState extends State<CircleVibeBoardManagementScreen>
    with TickerProviderStateMixin {
  final EnhancedCircleService _circleService = EnhancedCircleService();
  final VibeTagService _vibeTagService = VibeTagService();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  Map<String, List<VibeBoard>> _vibeBoardsMap = {};
  List<VibeTag> _availableVibes = [];
  bool _isLoading = true;
  bool _isCreatingBoard = false;
  String _selectedVibeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load circle boards organized by vibes
      final vibeBoardsMap = await _circleService.getCircleBoardsByVibe(widget.circleId);
      
      // Load available vibe tags
      final vibes = await _vibeTagService.getAllVibeTags();

      // Create tab controller based on vibe categories
      final vibeCategories = ['all', ...vibeBoardsMap.keys];
      _tabController = TabController(length: vibeCategories.length, vsync: this);

      setState(() {
        _vibeBoardsMap = vibeBoardsMap;
        _availableVibes = vibes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading circle boards: $e');
      setState(() => _isLoading = false);
    }
  }

  void _createNewBoard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateVibeBoardSheet(
        circleId: widget.circleId,
        availableVibes: _availableVibes,
        onBoardCreated: () {
          _loadData(); // Refresh data after creation
        },
      ),
    );
  }

  void _editBoard(VibeBoard board) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditBoardSheet(
        board: board,
        availableVibes: _availableVibes,
        onBoardUpdated: () {
          _loadData(); // Refresh data after update
        },
      ),
    );
  }

  void _deleteBoard(VibeBoard board) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board'),
        content: Text('Are you sure you want to delete "${board.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implement board deletion
              _loadData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vibe Boards'),
            Text(
              widget.circle.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewBoard,
            tooltip: 'Create Board',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tab bar for vibe categories
                if (_vibeBoardsMap.isNotEmpty) _buildVibeTabBar(),
                
                // Board content
                Expanded(
                  child: _vibeBoardsMap.isEmpty
                      ? _buildEmptyState()
                      : _buildBoardContent(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewBoard,
        icon: const Icon(Icons.add),
        label: const Text('New Board'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildVibeTabBar() {
    final vibeCategories = ['All', ..._vibeBoardsMap.keys.map((k) => k.capitalize())];
    
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: vibeCategories.map((category) {
          final count = category == 'All' 
              ? _vibeBoardsMap.values.fold(0, (sum, boards) => sum + boards.length)
              : _vibeBoardsMap[category.toLowerCase()]?.length ?? 0;
          
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoardContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        // All boards
        _buildAllBoardsView(),
        
        // Individual vibe category views
        ..._vibeBoardsMap.entries.map((entry) {
          return _buildVibeBoardsView(entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildAllBoardsView() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _vibeBoardsMap.entries.map((entry) {
            final vibeName = entry.key;
            final boards = entry.value;
            
            if (boards.isEmpty) return const SizedBox.shrink();
            
            return Column(
              children: [
                _buildVibeSectionHeader(vibeName, boards.length),
                const SizedBox(height: 12),
                _buildBoardGrid(boards),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVibeBoardsView(String vibeName, List<VibeBoard> boards) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: boards.isEmpty
          ? _buildEmptyVibeState(vibeName)
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: boards.length,
              itemBuilder: (context, index) {
                return _buildBoardCard(boards[index], vibeName);
              },
            ),
    );
  }

  Widget _buildVibeSectionHeader(String vibeName, int count) {
    final vibeTag = _availableVibes.firstWhere(
      (tag) => tag.id == vibeName,
      orElse: () => VibeTag(
        id: vibeName,
        name: vibeName,
        displayName: vibeName.capitalize(),
        description: '',
        category: 'general',
        synonyms: [],
        color: '#9E9E9E',
        icon: 'tag',
        popularity: 0.5,
        contextWeights: {},
        createdAt: DateTime.now(),
        lastUsed: DateTime.now(),
        usageCount: 0,
      ),
    );

    final vibeColor = Color(int.parse(vibeTag.color.replaceFirst('#', '0xFF')));

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: vibeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconData(vibeTag.icon),
            color: vibeColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vibeTag.displayName} Boards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'board' : 'boards'}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 20),
          onPressed: () => _createBoardForVibe(vibeName),
          tooltip: 'Add ${vibeTag.displayName} Board',
        ),
      ],
    );
  }

  Widget _buildBoardGrid(List<VibeBoard> boards) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        return _buildBoardCard(boards[index], null);
      },
    );
  }

  Widget _buildBoardCard(VibeBoard board, String? vibeName) {
    return GestureDetector(
      onTap: () {
        // Navigate to board detail
      },
      onLongPress: () => _showBoardOptions(board),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Board header with cover image or icon
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: board.coverImageUrl != null
                      ? null
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  image: board.coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(board.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: board.coverImageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.bookmark,
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    : null,
              ),
            ),
            
            // Board details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      board.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${board.places.length} places',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (vibeName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              vibeName.capitalize(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Boards Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Create your first vibe board to start organizing places by mood and theme',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _createNewBoard,
              icon: const Icon(Icons.add),
              label: const Text('Create First Board'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVibeState(String vibeName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'No ${vibeName.capitalize()} Boards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Create a board to organize ${vibeName} places',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () => _createBoardForVibe(vibeName),
              child: Text('Create ${vibeName.capitalize()} Board'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBoardOptions(VibeBoard board) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Board'),
              onTap: () {
                Navigator.of(context).pop();
                _editBoard(board);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Board'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement board sharing
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Board'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement board duplication
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Board', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _deleteBoard(board);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createBoardForVibe(String vibeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateVibeBoardSheet(
        circleId: widget.circleId,
        availableVibes: _availableVibes,
        preselectedVibe: vibeId,
        onBoardCreated: _loadData,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'fireplace': Icons.fireplace,
      'flash': Icons.flash_on,
      'leaf': Icons.local_florist,
      'camera': Icons.camera_alt,
      'square': Icons.crop_square,
      'time': Icons.access_time,
      'people': Icons.people,
      'heart': Icons.favorite,
      'home': Icons.home,
      'compass': Icons.explore,
      'diamond': Icons.diamond,
      'star': Icons.star,
      'heart-outline': Icons.favorite_border,
      'bulb': Icons.lightbulb,
      'leaf-outline': Icons.eco,
      'happy': Icons.sentiment_very_satisfied,
    };
    return iconMap[iconName] ?? Icons.tag;
  }
}

// ============================================================================
// CREATE VIBE BOARD SHEET
// ============================================================================

class CreateVibeBoardSheet extends StatefulWidget {
  final String circleId;
  final List<VibeTag> availableVibes;
  final String? preselectedVibe;
  final VoidCallback onBoardCreated;

  const CreateVibeBoardSheet({
    super.key,
    required this.circleId,
    required this.availableVibes,
    this.preselectedVibe,
    required this.onBoardCreated,
  });

  @override
  State<CreateVibeBoardSheet> createState() => _CreateVibeBoardSheetState();
}

class _CreateVibeBoardSheetState extends State<CreateVibeBoardSheet> {
  final EnhancedCircleService _circleService = EnhancedCircleService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  Set<String> _selectedVibes = {};
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedVibe != null) {
      _selectedVibes = {widget.preselectedVibe!};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createBoard() async {
    if (_nameController.text.trim().isEmpty || _selectedVibes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a name and select at least one vibe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await _circleService.createVibeBoard(
        circleId: widget.circleId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        vibeTagIds: _selectedVibes.toList(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onBoardCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Board created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create board: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Vibe Board',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Board name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Board Name',
                      hintText: 'e.g., Cozy Coffee Spots',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Board description
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'What kind of places will you save here?',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Vibe selection
                  Text(
                    'Select Vibes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: CompactVibeSelector(
                      selectedVibes: _selectedVibes,
                      onSelectionChanged: (vibes) {
                        setState(() => _selectedVibes = vibes);
                      },
                      maxSelections: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Create button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createBoard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Board'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EDIT BOARD SHEET
// ============================================================================

class EditBoardSheet extends StatefulWidget {
  final VibeBoard board;
  final List<VibeTag> availableVibes;
  final VoidCallback onBoardUpdated;

  const EditBoardSheet({
    super.key,
    required this.board,
    required this.availableVibes,
    required this.onBoardUpdated,
  });

  @override
  State<EditBoardSheet> createState() => _EditBoardSheetState();
}

class _EditBoardSheetState extends State<EditBoardSheet> {
  final VibeTagService _vibeTagService = VibeTagService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  Set<String> _selectedVibes = {};
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.board.title;
    _descriptionController.text = widget.board.description!;
    _loadBoardVibes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadBoardVibes() async {
    try {
      final vibeAssociations = await _vibeTagService.getEntityVibeAssociations(
        widget.board.id,
        'board',
      );
      
      setState(() {
        _selectedVibes = vibeAssociations.map((v) => v.vibeTagId).toSet();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading board vibes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBoard() async {
    if (_nameController.text.trim().isEmpty || _selectedVibes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a name and select at least one vibe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // Update board vibes
      await _vibeTagService.associateVibesWithEntity(
        entityId: widget.board.id,
        entityType: 'board',
        vibeTagIds: _selectedVibes.toList(),
        source: 'user_edited',
      );

      // TODO: Update board name and description
      // This would require a board update method in the service

      if (mounted) {
        Navigator.of(context).pop();
        widget.onBoardUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Board updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update board: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Board',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Board name
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Board Name',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Board description
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Vibe selection
                        Text(
                          'Board Vibes',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Expanded(
                          child: CompactVibeSelector(
                            selectedVibes: _selectedVibes,
                            onSelectionChanged: (vibes) {
                              setState(() => _selectedVibes = vibes);
                            },
                            maxSelections: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Update button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateBoard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Update Board'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension helper
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}