import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vibe_tag_models.dart';
import '../services/vibe_tag_service.dart';

// ============================================================================
// VIBE TAG CHIP - Individual selectable vibe tag
// ============================================================================

class VibeTagChip extends StatelessWidget {
  final VibeTag vibeTag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDescription;
  final double size;
  final bool enabled;

  const VibeTagChip({
    super.key,
    required this.vibeTag,
    required this.isSelected,
    required this.onTap,
    this.showDescription = false,
    this.size = 1.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(vibeTag.color.replaceFirst('#', '0xFF')));
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: enabled ? () {
        HapticFeedback.selectionClick();
        onTap();
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: 16.0 * size,
          vertical: 8.0 * size,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0 * size),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8.0 * size,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconData(vibeTag.icon),
              size: 16.0 * size,
              color: isSelected ? color : color.withOpacity(0.7),
            ),
            SizedBox(width: 6.0 * size),
            Text(
              vibeTag.displayName,
              style: TextStyle(
                fontSize: 12.0 * size,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (showDescription) ...[
              SizedBox(width: 4.0 * size),
              Icon(
                Icons.info_outline,
                size: 12.0 * size,
                color: color.withOpacity(0.5),
              ),
            ],
          ],
        ),
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
// VIBE CATEGORY SECTION - Groups vibe tags by category
// ============================================================================

class VibeCategorySection extends StatelessWidget {
  final VibeCategory category;
  final List<VibeTag> vibeTags;
  final Set<String> selectedVibes;
  final Function(String) onVibeToggle;
  final int? maxSelections;
  final bool enabled;

  const VibeCategorySection({
    super.key,
    required this.category,
    required this.vibeTags,
    required this.selectedVibes,
    required this.onVibeToggle,
    this.maxSelections,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = Color(int.parse(category.color.replaceFirst('#', '0xFF')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(category.icon),
                  size: 20,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                    Text(
                      category.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Vibe chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vibeTags.map((vibeTag) {
              final isSelected = selectedVibes.contains(vibeTag.id);
              final canSelect = enabled && (isSelected || maxSelections == null || selectedVibes.length < maxSelections!);
              
              return VibeTagChip(
                vibeTag: vibeTag,
                isSelected: isSelected,
                enabled: canSelect,
                onTap: () => onVibeToggle(vibeTag.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'flash': Icons.flash_on,
      'camera': Icons.camera_alt,
      'people': Icons.people,
      'compass': Icons.explore,
      'happy': Icons.sentiment_very_satisfied,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

// ============================================================================
// VIBE SELECTION GRID - Complete vibe selection interface
// ============================================================================

class VibeSelectionGrid extends StatefulWidget {
  final Set<String> initialSelectedVibes;
  final Function(Set<String>) onSelectionChanged;
  final int? maxSelections;
  final int? minSelections;
  final bool enabled;
  final String? title;
  final String? subtitle;
  final bool showSearch;

  const VibeSelectionGrid({
    super.key,
    this.initialSelectedVibes = const {},
    required this.onSelectionChanged,
    this.maxSelections,
    this.minSelections,
    this.enabled = true,
    this.title,
    this.subtitle,
    this.showSearch = false,
  });

  @override
  State<VibeSelectionGrid> createState() => _VibeSelectionGridState();
}

class _VibeSelectionGridState extends State<VibeSelectionGrid> {
  final VibeTagService _vibeTagService = VibeTagService();
  final TextEditingController _searchController = TextEditingController();
  
  Set<String> _selectedVibes = {};
  List<VibeCategory> _categories = [];
  Map<String, List<VibeTag>> _categorizedTags = {};
  List<VibeTag> _filteredTags = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedVibes = Set.from(widget.initialSelectedVibes);
    _loadVibeData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVibeData() async {
    try {
      setState(() => _isLoading = true);
      
      await _vibeTagService.initializeVibeSystem();
      final allTags = await _vibeTagService.getAllVibeTags();
      
      // Group tags by category
      final categorizedTags = <String, List<VibeTag>>{};
      for (final tag in allTags) {
        if (!categorizedTags.containsKey(tag.category)) {
          categorizedTags[tag.category] = [];
        }
        categorizedTags[tag.category]!.add(tag);
      }

      // Create category objects (simplified - in real app, fetch from Firestore)
      final categories = PredefinedVibeTags.categories.entries.map((entry) {
        final categoryData = entry.value;
        return VibeCategory(
          id: entry.key,
          name: entry.key,
          displayName: categoryData['displayName'],
          description: categoryData['description'],
          color: categoryData['color'],
          icon: categoryData['icon'],
          sortOrder: categoryData['sortOrder'],
          vibeTagIds: categorizedTags[entry.key]?.map((t) => t.id).toList() ?? [],
        );
      }).toList();

      categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      setState(() {
        _categories = categories;
        _categorizedTags = categorizedTags;
        _filteredTags = allTags;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vibe data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredTags = _categorizedTags.values.expand((tags) => tags).toList();
      } else {
        _filteredTags = _categorizedTags.values
            .expand((tags) => tags)
            .where((tag) =>
                tag.displayName.toLowerCase().contains(_searchQuery) ||
                tag.description.toLowerCase().contains(_searchQuery) ||
                tag.synonyms.any((s) => s.toLowerCase().contains(_searchQuery)))
            .toList();
      }
    });
  }

  void _toggleVibe(String vibeId) {
    if (!widget.enabled) return;

    setState(() {
      if (_selectedVibes.contains(vibeId)) {
        _selectedVibes.remove(vibeId);
      } else {
        if (widget.maxSelections == null || _selectedVibes.length < widget.maxSelections!) {
          _selectedVibes.add(vibeId);
        }
      }
    });

    widget.onSelectionChanged(_selectedVibes);
  }

  bool get _isValidSelection {
    final minMet = widget.minSelections == null || _selectedVibes.length >= widget.minSelections!;
    final maxMet = widget.maxSelections == null || _selectedVibes.length <= widget.maxSelections!;
    return minMet && maxMet;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        if (widget.title != null || widget.subtitle != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Selection counter and search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Selection counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isValidSelection ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isValidSelection ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isValidSelection ? Icons.check_circle : Icons.info,
                      size: 16,
                      color: _isValidSelection ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_selectedVibes.length}${widget.maxSelections != null ? '/${widget.maxSelections}' : ''} selected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isValidSelection ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Search toggle
              if (widget.showSearch)
                IconButton(
                  icon: Icon(_searchQuery.isNotEmpty ? Icons.clear : Icons.search),
                  onPressed: () {
                    if (_searchQuery.isNotEmpty) {
                      _searchController.clear();
                    }
                  },
                ),
            ],
          ),
        ),

        // Search field
        if (widget.showSearch && _searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vibes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Vibe categories or search results
        Expanded(
          child: _searchQuery.isEmpty ? _buildCategoryView() : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildCategoryView() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final categoryTags = _categorizedTags[category.id] ?? [];
        
        if (categoryTags.isEmpty) return const SizedBox.shrink();
        
        return VibeCategorySection(
          category: category,
          vibeTags: categoryTags,
          selectedVibes: _selectedVibes,
          onVibeToggle: _toggleVibe,
          maxSelections: widget.maxSelections,
          enabled: widget.enabled,
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_filteredTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No vibes found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _filteredTags.map((vibeTag) {
          final isSelected = _selectedVibes.contains(vibeTag.id);
          final canSelect = widget.enabled && (isSelected || widget.maxSelections == null || _selectedVibes.length < widget.maxSelections!);
          
          return VibeTagChip(
            vibeTag: vibeTag,
            isSelected: isSelected,
            enabled: canSelect,
            showDescription: true,
            onTap: () => _toggleVibe(vibeTag.id),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// COMPACT VIBE SELECTOR - For smaller spaces (circle creation, etc.)
// ============================================================================

class CompactVibeSelector extends StatefulWidget {
  final Set<String> selectedVibes;
  final Function(Set<String>) onSelectionChanged;
  final int maxSelections;
  final String? label;

  const CompactVibeSelector({
    super.key,
    required this.selectedVibes,
    required this.onSelectionChanged,
    this.maxSelections = 3,
    this.label,
  });

  @override
  State<CompactVibeSelector> createState() => _CompactVibeSelectorState();
}

class _CompactVibeSelectorState extends State<CompactVibeSelector> {
  final VibeTagService _vibeTagService = VibeTagService();
  List<VibeTag> _popularVibes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPopularVibes();
  }

  Future<void> _loadPopularVibes() async {
    try {
      final allTags = await _vibeTagService.getAllVibeTags();
      
      // Sort by popularity and take top 12
      allTags.sort((a, b) => b.popularity.compareTo(a.popularity));
      
      setState(() {
        _popularVibes = allTags.take(12).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading popular vibes: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleVibe(String vibeId) {
    final newSelection = Set<String>.from(widget.selectedVibes);
    
    if (newSelection.contains(vibeId)) {
      newSelection.remove(vibeId);
    } else if (newSelection.length < widget.maxSelections) {
      newSelection.add(vibeId);
    }
    
    widget.onSelectionChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularVibes.map((vibeTag) {
            final isSelected = widget.selectedVibes.contains(vibeTag.id);
            final canSelect = isSelected || widget.selectedVibes.length < widget.maxSelections;
            
            return VibeTagChip(
              vibeTag: vibeTag,
              isSelected: isSelected,
              enabled: canSelect,
              size: 0.9, // Slightly smaller for compact view
              onTap: () => _toggleVibe(vibeTag.id),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '${widget.selectedVibes.length}/${widget.maxSelections} vibes selected',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}