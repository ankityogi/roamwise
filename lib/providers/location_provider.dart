import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationState {
  final Position? currentPosition;
  final String? currentCity;
  final bool isPermissionGranted;
  final bool isLoading;
  final String? errorMessage;

  LocationState({
    this.currentPosition,
    this.currentCity,
    required this.isPermissionGranted,
    required this.isLoading,
    this.errorMessage,
  });

  factory LocationState.initial() => LocationState(
        currentPosition: null,
        currentCity: null,
        isPermissionGranted: false,
        isLoading: false,
        errorMessage: null,
      );

  LocationState copyWith({
    Position? currentPosition,
    String? currentCity,
    bool? isPermissionGranted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      currentCity: currentCity ?? this.currentCity,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState.initial()) {
    checkPermissionAndFetchLocation();
  }

  Future<void> checkPermissionAndFetchLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Location services are disabled on this device.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            isPermissionGranted: false,
            errorMessage: 'Location permission was denied.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          isPermissionGranted: false,
          errorMessage: 'Location permissions are permanently denied. Please enable them in settings.',
        );
        return;
      }

      // Permissions are granted, fetch location
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Perform reverse geocoding to resolve the city name
      String? city;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
          if (city != null && place.country != null) {
            city = "$city, ${place.country}";
          }
        }
      } catch (geocodingError) {
        // Log error but proceed without breaking coordinates fetching
        print('Reverse geocoding error: $geocodingError');
      }

      state = state.copyWith(
        currentPosition: position,
        currentCity: city,
        isPermissionGranted: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to retrieve location: ${e.toString()}',
      );
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
