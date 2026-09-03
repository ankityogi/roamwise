import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/theme.dart';
import '../providers/explore_provider.dart';
import '../providers/location_provider.dart';
import '../providers/bookmark_provider.dart';

class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({super.key});

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Hotels', 'Dining', 'Sights', 'Transit'];
  
  GoogleMapController? _mapController;
  static const LatLng _defaultLocation = LatLng(21.1702, 72.8311); // Surat, India

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
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#171821"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0D0E12"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#515c6d"}]
    }
  ]
  ''';

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.setMapStyle(_darkMapStyle);
  }

  Set<Marker> _buildMarkers(List<PlaceModel> places) {
    final Set<Marker> markers = {};
    for (int i = 0; i < places.length; i++) {
      final place = places[i];
      if (place.latitude != null && place.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('place_${place.title}_$i'),
            position: LatLng(place.latitude!, place.longitude!),
            infoWindow: InfoWindow(
              title: place.title,
              snippet: '${place.category} • Rating: ${place.rating} • ${place.price}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerHue(place.category),
            ),
          ),
        );
      }
    }
    return markers;
  }

  double _getMarkerHue(String category) {
    switch (category) {
      case 'Hotels':
        return BitmapDescriptor.hueCyan;
      case 'Dining':
        return BitmapDescriptor.hueOrange;
      case 'Sights':
        return BitmapDescriptor.hueViolet;
      case 'Transit':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueMagenta;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize search controller text with current provider search city state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(exploreProvider).searchCity;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hotels':
        return Icons.hotel;
      case 'Dining':
        return Icons.restaurant;
      case 'Sights':
        return Icons.museum;
      case 'Transit':
        return Icons.train;
      default:
        return Icons.location_on;
    }
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(exploreProvider.notifier).updateSearchCity(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreProvider);
    final places = exploreState.places;

    // Listen to location provider changes to auto-update search city and center map camera
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (next.currentCity != null && next.currentCity != previous?.currentCity) {
        _searchController.text = next.currentCity!;
        ref.read(exploreProvider.notifier).updateSearchCity(next.currentCity!);
        if (next.currentPosition != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(next.currentPosition!.latitude, next.currentPosition!.longitude),
              12.0,
            ),
          );
        }
      }
    });

    // Listen to exploreProvider to center camera on first loaded place marker if coordinates exist
    ref.listen<ExploreState>(exploreProvider, (previous, next) {
      if (next.places.isNotEmpty && next.places != previous?.places) {
        final firstPlace = next.places.firstWhere(
          (p) => p.latitude != null && p.longitude != null,
          orElse: () => PlaceModel(title: '', category: '', rating: 0, price: '', distance: ''),
        );
        if (firstPlace.latitude != null && firstPlace.longitude != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(firstPlace.latitude!, firstPlace.longitude!),
              13.0,
            ),
          );
        }
      }
    });

    return Column(
      children: [
        // Top Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _triggerSearch(),
            decoration: InputDecoration(
              hintText: 'Search city (e.g. Surat, Vadodara)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: AppColors.accent),
                onPressed: _triggerSearch,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
          ),
        ),

        // Horizontal Category Chips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = exploreState.selectedCategory == cat;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(exploreProvider.notifier).updateCategory(cat);
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primary.withValues(alpha: 0.3),
                  checkmarkColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Google Maps Preview Window
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              color: AppColors.surface,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: ref.watch(locationProvider).currentPosition != null
                            ? LatLng(
                                ref.watch(locationProvider).currentPosition!.latitude,
                                ref.watch(locationProvider).currentPosition!.longitude,
                              )
                            : _defaultLocation,
                        zoom: 12.0,
                      ),
                      onMapCreated: _onMapCreated,
                      myLocationEnabled: ref.watch(locationProvider).isPermissionGranted,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      markers: _buildMarkers(places),
                    ),
                  ),
                ),
                // Floating Action Map controls
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      _buildMapIconButton(Icons.my_location, () {
                        final locationState = ref.read(locationProvider);
                        if (locationState.currentPosition != null && _mapController != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(
                                locationState.currentPosition!.latitude,
                                locationState.currentPosition!.longitude,
                              ),
                              14.0,
                            ),
                          );
                        } else {
                          ref.read(locationProvider.notifier).checkPermissionAndFetchLocation();
                        }
                      }),
                      const SizedBox(height: 8),
                      _buildMapIconButton(Icons.add, () {
                        _mapController?.animateCamera(CameraUpdate.zoomIn());
                      }),
                      const SizedBox(height: 8),
                      _buildMapIconButton(Icons.remove, () {
                        _mapController?.animateCamera(CameraUpdate.zoomOut());
                      }),
                    ],
                  ),
                ),
                // Location Bar banner overlay
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_searching, color: AppColors.success, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          exploreState.searchCity,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Nearby Location Grid Cards
        Expanded(
          flex: 3,
          child: exploreState.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : exploreState.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          exploreState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    )
                  : places.isEmpty
                      ? const Center(
                          child: Text(
                            'No places found for this search.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: places.length,
                          itemBuilder: (context, index) {
                            final place = places[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(place.category),
                                    color: AppColors.accent,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  place.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(place.distance, style: const TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(width: 8),
                                    const Text('|', style: TextStyle(color: AppColors.cardBorder)),
                                    const SizedBox(width: 8),
                                    Text(place.price, style: const TextStyle(color: AppColors.success)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      place.rating.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    Builder(
                                      builder: (context) {
                                        final bookmarkState = ref.watch(bookmarkProvider);
                                        final isFav = ref.read(bookmarkProvider.notifier).isBookmarked(place.title);
                                        final bookmarkId = ref.read(bookmarkProvider.notifier).getBookmarkId(place.title);
                                        return IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                          icon: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            color: isFav ? Colors.redAccent : AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            final notifier = ref.read(bookmarkProvider.notifier);
                                            if (isFav && bookmarkId != null) {
                                              notifier.deleteBookmark(bookmarkId);
                                            } else {
                                              notifier.addBookmark(place);
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildMapIconButton(IconData icon, VoidCallback onPressed) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
      child: IconButton(
        icon: Icon(icon, size: 18, color: Colors.white),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
