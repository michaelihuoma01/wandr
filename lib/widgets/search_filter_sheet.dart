// lib/widgets/search_filter_sheet.dart
import 'package:flutter/material.dart';

class SearchFilter {
  final double? maxDistance;
  final int? minRating;
  final Set<String> priceLevels;
  final Set<String> placeTypes;
  final SortBy sortBy;
  
  SearchFilter({
    this.maxDistance,
    this.minRating,
    this.priceLevels = const {},
    this.placeTypes = const {},
    this.sortBy = SortBy.distance,
  });
  
  SearchFilter copyWith({
    double? maxDistance,
    int? minRating,
    Set<String>? priceLevels,
    Set<String>? placeTypes,
    SortBy? sortBy,
  }) {
    return SearchFilter(
      maxDistance: maxDistance ?? this.maxDistance,
      minRating: minRating ?? this.minRating,
      priceLevels: priceLevels ?? this.priceLevels,
      placeTypes: placeTypes ?? this.placeTypes,
      sortBy: sortBy ?? this.sortBy,
    );
  }
  
  bool get hasActiveFilters => 
    maxDistance != null || 
    minRating != null || 
    priceLevels.isNotEmpty || 
    placeTypes.isNotEmpty ||
    sortBy != SortBy.distance;
}

enum SortBy {
  distance('Distance', Icons.near_me),
  rating('Rating', Icons.star),
  priceHighToLow('Price (High to Low)', Icons.attach_money),
  priceLowToHigh('Price (Low to High)', Icons.money_off);
  
  final String label;
  final IconData icon;
  
  const SortBy(this.label, this.icon);
}

class SearchFilterSheet extends StatefulWidget {
  final SearchFilter currentFilter;
  final Function(SearchFilter) onFilterChanged;
  
  const SearchFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilter _tempFilter;
  late double _distanceValue;
  late int _ratingValue;
  
  // Common place types
  final List<String> _placeTypes = [
    'restaurant',
    'cafe',
    'bar',
    'hotel',
    'shopping',
    'entertainment',
    'park',
    'museum',
    'tourist attraction',
  ];
  
  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
    _distanceValue = widget.currentFilter.maxDistance ?? 10.0;
    _ratingValue = widget.currentFilter.minRating ?? 0;
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
                  _buildSortSection(),
                  _buildDistanceSection(),
                  _buildRatingSection(),
                  _buildPriceSection(),
                  _buildTypeSection(),
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
            'Filter & Sort',
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
                  _tempFilter = SearchFilter();
                  _distanceValue = 10.0;
                  _ratingValue = 0;
                });
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSortSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...SortBy.values.map((sortOption) => RadioListTile<SortBy>(
            title: Text(sortOption.label),
            secondary: Icon(sortOption.icon),
            value: sortOption,
            groupValue: _tempFilter.sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _tempFilter = _tempFilter.copyWith(sortBy: value);
                });
              }
            },
            contentPadding: EdgeInsets.zero,
          )),
        ],
      ),
    );
  }
  
  Widget _buildDistanceSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Maximum Distance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_distanceValue.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _distanceValue,
            min: 0.5,
            max: 50.0,
            divisions: 99,
            label: '${_distanceValue.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() {
                _distanceValue = value;
                _tempFilter = _tempFilter.copyWith(maxDistance: value);
              });
            },
            activeColor: Theme.of(context).primaryColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.5 km', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('50 km', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Minimum Rating',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0, 3, 4].map((rating) => InkWell(
              onTap: () {
                setState(() {
                  _ratingValue = rating;
                  _tempFilter = _tempFilter.copyWith(
                    minRating: rating == 0 ? null : rating,
                  );
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _ratingValue == rating 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _ratingValue == rating 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rating > 0) ...[
                      Icon(
                        Icons.star,
                        size: 20,
                        color: _ratingValue == rating ? Colors.white : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating+',
                        style: TextStyle(
                          color: _ratingValue == rating ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else
                      Text(
                        'Any',
                        style: TextStyle(
                          color: _ratingValue == rating ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Level',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [r'$', r'$$', r'$$$', r'$$$$'].map((price) => InkWell(
              onTap: () {
                setState(() {
                  final newPriceLevels = Set<String>.from(_tempFilter.priceLevels);
                  if (newPriceLevels.contains(price)) {
                    newPriceLevels.remove(price);
                  } else {
                    newPriceLevels.add(price);
                  }
                  _tempFilter = _tempFilter.copyWith(priceLevels: newPriceLevels);
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _tempFilter.priceLevels.contains(price) 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _tempFilter.priceLevels.contains(price) 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    color: _tempFilter.priceLevels.contains(price) 
                      ? Colors.white 
                      : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Place Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _placeTypes.map((type) {
              final isSelected = _tempFilter.placeTypes.contains(type);
              return FilterChip(
                label: Text(type[0].toUpperCase() + type.substring(1)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    final newTypes = Set<String>.from(_tempFilter.placeTypes);
                    if (selected) {
                      newTypes.add(type);
                    } else {
                      newTypes.remove(type);
                    }
                    _tempFilter = _tempFilter.copyWith(placeTypes: newTypes);
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