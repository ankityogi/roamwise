import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/trip_model.dart';
import '../utils/theme.dart';

class ItineraryRouteMapScreen extends StatefulWidget {
  final TripModel trip;
  final int initialDayIndex;

  const ItineraryRouteMapScreen({
    super.key,
    required this.trip,
    this.initialDayIndex = 0,
  });

  @override
  State<ItineraryRouteMapScreen> createState() => _ItineraryRouteMapScreenState();
}

class _ItineraryRouteMapScreenState extends State<ItineraryRouteMapScreen> {
  late int _selectedDayIndex;
  GoogleMapController? _mapController;
  final PageController _pageController = PageController(viewportFraction: 0.88);

  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#171821"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#171821"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8A8B9C"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#FFFFFF"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#00F0FF"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#1b1d2a"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#2C2E3E"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#21222e"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8A8B9C"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#8A2BE2"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0D0E12"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.initialDayIndex.clamp(
      0,
      widget.trip.itinerarySchedule.isNotEmpty ? widget.trip.itinerarySchedule.length - 1 : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<TimelineEventModel> get _currentDayEvents {
    if (widget.trip.itinerarySchedule.isEmpty || _selectedDayIndex >= widget.trip.itinerarySchedule.length) {
      return [];
    }
    return widget.trip.itinerarySchedule[_selectedDayIndex].events;
  }

  // Generate fallback coordinates centered around destination if missing
  LatLng _resolveEventCoordinates(TimelineEventModel event, int index) {
    if (event.latitude != null && event.longitude != null) {
      return LatLng(event.latitude!, event.longitude!);
    }
    // Deterministic fallback based on destination hash
    final baseLat = 21.1702 + (widget.trip.destination.hashCode % 1000) / 100.0;
    final baseLng = 72.8311 + (widget.trip.destination.hashCode % 1000) / 100.0;
    return LatLng(baseLat + (index * 0.012), baseLng + (index * 0.015));
  }

  Set<Marker> _buildDayMarkers() {
    final Set<Marker> markers = {};
    final events = _currentDayEvents;

    for (int i = 0; i < events.length; i++) {
      final ev = events[i];
      final pos = _resolveEventCoordinates(ev, i);

      markers.add(
        Marker(
          markerId: MarkerId('event_marker_${_selectedDayIndex}_$i'),
          position: pos,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${ev.title}',
            snippet: '${ev.time} • ${ev.description}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0
                ? BitmapDescriptor.hueGreen
                : (i == events.length - 1 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueCyan),
          ),
          onTap: () {
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildRoutePolylines() {
    final events = _currentDayEvents;
    if (events.length < 2) return {};

    final List<LatLng> points = [];
    for (int i = 0; i < events.length; i++) {
      points.add(_resolveEventCoordinates(events[i], i));
    }

    return {
      Polyline(
        polylineId: PolylineId('route_day_$_selectedDayIndex'),
        points: points,
        color: AppColors.accent,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  void _fitMapToPoints() {
    if (_mapController == null || _currentDayEvents.isEmpty) return;

    final events = _currentDayEvents;
    if (events.length == 1) {
      final singlePos = _resolveEventCoordinates(events.first, 0);
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(singlePos, 14));
      return;
    }

    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (int i = 0; i < events.length; i++) {
      final pos = _resolveEventCoordinates(events[i], i);
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.trip.itinerarySchedule;
    final events = _currentDayEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.trip.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            Text(
              '${widget.trip.destination} • Route Map',
              style: const TextStyle(color: AppColors.accent, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Google Map with Route
          GoogleMap(
            style: _darkMapStyle,
            initialCameraPosition: CameraPosition(
              target: events.isNotEmpty
                  ? _resolveEventCoordinates(events.first, 0)
                  : const LatLng(21.1702, 72.8311),
              zoom: 13.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 300), _fitMapToPoints);
            },
            markers: _buildDayMarkers(),
            polylines: _buildRoutePolylines(),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Top Day Selector Chips
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: schedule.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedDayIndex == index;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('Day ${schedule[index].dayNumber}'),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedDayIndex = index;
                          });
                          Future.delayed(const Duration(milliseconds: 200), _fitMapToPoints);
                        }
                      },
                      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.accent : AppColors.cardBorder,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Swipable Event Cards Carousel
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: events.isEmpty
                ? const SizedBox()
                : SizedBox(
                    height: 165,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: events.length,
                      onPageChanged: (index) {
                        final pos = _resolveEventCoordinates(events[index], index);
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(pos, 15),
                        );
                      },
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final isFirst = index == 0;
                        final isLast = index == events.length - 1;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isFirst
                                  ? AppColors.success.withValues(alpha: 0.6)
                                  : (isLast ? Colors.redAccent.withValues(alpha: 0.6) : AppColors.accent.withValues(alpha: 0.4)),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isFirst
                                        ? AppColors.success
                                        : (isLast ? Colors.redAccent : AppColors.primary),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      event.time,
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (index < events.length - 1)
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_walk, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '~${10 + (index * 5)} min walk',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  event.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
