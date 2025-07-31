// lib/widgets/visit_filter_sheet.dart
import 'package:flutter/material.dart';
import '../models/visit_models.dart';

class VisitFilterSheet extends StatefulWidget {
  final VisitFilter currentFilter;
  final Function(VisitFilter) onFilterChanged;

  const VisitFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<VisitFilterSheet> createState() => _VisitFilterSheetState();
}

class _VisitFilterSheetState extends State<VisitFilterSheet> {
  late VisitFilter _tempFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
    _startDate = widget.currentFilter.startDate;
    _endDate = widget.currentFilter.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(),
                  _buildVibeSection(),
                  _buildDateSection(),
                  _buildOtherFilters(),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Text(
            'Filter Visits',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_tempFilter.hasActiveFilters)
            TextButton(
              onPressed: () {
                setState(() {
                  _tempFilter = VisitFilter();
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlaceCategory.values.map((category) {
              final isSelected = _tempFilter.categories.contains(category);
              return FilterChip(
                label: Text('${category.emoji} ${category.displayName}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    final newCategories = Set<PlaceCategory>.from(_tempFilter.categories);
                    if (selected) {
                      newCategories.add(category);
                    } else {
                      newCategories.remove(category);
                    }
                    _tempFilter = _tempFilter.copyWith(categories: newCategories);
                  });
                },
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vibes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Group vibes by category
          ...['mood', 'atmosphere', 'crowd', 'style'].map((category) {
            final categoryVibes = VibeConstants.allVibes
                .where((vibe) => vibe.category == category)
                .toList();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category[0].toUpperCase() + category.substring(1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryVibes.map((vibe) {
                    final isSelected = _tempFilter.vibes.contains(vibe.id);
                    return FilterChip(
                      label: Text('${vibe.icon} ${vibe.name}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          final newVibes = Set<String>.from(_tempFilter.vibes);
                          if (selected) {
                            newVibes.add(vibe.id);
                          } else {
                            newVibes.remove(vibe.id);
                          }
                          _tempFilter = _tempFilter.copyWith(vibes: newVibes);
                        });
                      },
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      checkmarkColor: Theme.of(context).primaryColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  label: 'From',
                  date: _startDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                        _tempFilter = _tempFilter.copyWith(startDate: picked);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  label: 'To',
                  date: _endDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                        _tempFilter = _tempFilter.copyWith(endDate: picked);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : label,
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Other Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Manual Check-ins Only'),
            subtitle: const Text('Show only places you manually checked into'),
            value: _tempFilter.showOnlyManualCheckIns,
            onChanged: (value) {
              setState(() {
                _tempFilter = _tempFilter.copyWith(showOnlyManualCheckIns: value);
              });
            },
            activeColor: Theme.of(context).primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onFilterChanged(_tempFilter);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}