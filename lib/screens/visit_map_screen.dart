// lib/screens/visit_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/visit_models.dart';
import '../services/visit_service.dart';
import '../services/location_service.dart';

class VisitMapScreen extends StatefulWidget {
  final VisitFilter filter;

  const VisitMapScreen({
    super.key,
    required this.filter,
  });

  @override
  State<VisitMapScreen> createState() => _VisitMapScreenState();
}

class _VisitMapScreenState extends State<VisitMapScreen> {
  final VisitService _visitService = VisitService();
  final LocationService _locationService = LocationService();
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  PlaceVisit? _selectedVisit;
  
  // Default to Dubai coordinates
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(25.2048, 55.2708),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Try to get current location
    final locationResult = await _locationService.getCurrentLocation();
    if (locationResult.success && locationResult.position != null) {
      setState(() {
        _initialPosition = CameraPosition(
          target: LatLng(
            locationResult.position!.latitude,
            locationResult.position!.longitude,
          ),
          zoom: 12,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<PlaceVisit>>(
          stream: _visitService.getVisitHistory(filter: widget.filter),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _updateMarkers(snapshot.data!);
            }

            return GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) {
                _mapController = controller;
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  _fitMapToVisits(snapshot.data!);
                }
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              mapType: MapType.normal,
            );
          },
        ),
        if (_selectedVisit != null) _buildVisitCard(),
        _buildMapControls(),
      ],
    );
  }

  void _updateMarkers(List<PlaceVisit> visits) {
    final markers = <Marker>{};
    
    for (final visit in visits) {
      final category = PlaceCategory.fromString(visit.placeCategory);
      
      markers.add(
        Marker(
          markerId: MarkerId(visit.id),
          position: LatLng(visit.latitude, visit.longitude),
          infoWindow: InfoWindow(
            title: visit.placeName,
            snippet: '${category.emoji} ${visit.placeType}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            visit.isManualCheckIn 
                ? BitmapDescriptor.hueViolet 
                : BitmapDescriptor.hueBlue,
          ),
          onTap: () {
            setState(() {
              _selectedVisit = visit;
            });
          },
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _fitMapToVisits(List<PlaceVisit> visits) {
    if (visits.isEmpty || _mapController == null) return;

    final bounds = _calculateBounds(visits);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  LatLngBounds _calculateBounds(List<PlaceVisit> visits) {
    double minLat = visits.first.latitude;
    double maxLat = visits.first.latitude;
    double minLng = visits.first.longitude;
    double maxLng = visits.first.longitude;

    for (final visit in visits) {
      minLat = minLat > visit.latitude ? visit.latitude : minLat;
      maxLat = maxLat < visit.latitude ? visit.latitude : maxLat;
      minLng = minLng > visit.longitude ? visit.longitude : minLng;
      maxLng = maxLng < visit.longitude ? visit.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildVisitCard() {
    final visit = _selectedVisit!;
    final category = PlaceCategory.fromString(visit.placeCategory);
    
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.placeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          visit.placeType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedVisit = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatVisitTime(visit.visitTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!visit.isManualCheckIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Auto-detected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                ],
              ),
              if (visit.vibes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: visit.vibes.take(3).map((vibeId) {
                    final vibe = VibeConstants.getVibeById(vibeId);
                    return Chip(
                      label: Text(
                        '${vibe?.emoji ?? ''} ${vibe?.name ?? vibeId}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _navigateToPlace(visit);
                      },
                      icon: const Icon(Icons.directions, size: 16),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to visit details
                      },
                      icon: const Icon(Icons.info, size: 16),
                      label: const Text('Details'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: () {
              _showMapTypeDialog();
            },
            backgroundColor: Colors.white,
            child: Icon(Icons.layers, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            mini: true,
            onPressed: () {
              _showLegend();
            },
            backgroundColor: Colors.white,
            child: Icon(Icons.info_outline, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Normal'),
              onTap: () {
                _mapController?.setMapStyle(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Satellite'),
              onTap: () {
                // TODO: Implement satellite view
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Terrain'),
              onTap: () {
                // TODO: Implement terrain view
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLegend() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Legend',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.purple,
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Text('Manual Check-in'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 30,
                ),
                const SizedBox(width: 12),
                const Text('Auto-detected Visit'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...PlaceCategory.values.map((category) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(category.displayName),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _formatVisitTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _navigateToPlace(PlaceVisit visit) {
    // TODO: Implement navigation to place
  }
}