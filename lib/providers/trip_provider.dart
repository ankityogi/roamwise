import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../utils/config.dart';
import 'auth_provider.dart';

class TripState {
  final List<TripModel> trips;
  final bool isLoading;
  final bool isOfflineData;
  final String? errorMessage;

  TripState({
    required this.trips,
    required this.isLoading,
    this.isOfflineData = false,
    this.errorMessage,
  });

  factory TripState.initial() => TripState(trips: [], isLoading: false);

  TripState copyWith({
    List<TripModel>? trips,
    bool? isLoading,
    bool? isOfflineData,
    String? errorMessage,
  }) {
    return TripState(
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      isOfflineData: isOfflineData ?? this.isOfflineData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  final Ref _ref;
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _cachedTripsKey = 'roamwise_cached_trips';

  TripNotifier(this._ref) : super(TripState.initial()) {
    // Automatically load cached trips first, then fetch live
    _loadCachedTrips();
    fetchTrips();
  }

  Future<void> _loadCachedTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachedTripsKey);
      if (cachedJson != null && state.trips.isEmpty) {
        final List list = jsonDecode(cachedJson);
        final cached = list.map((t) => TripModel.fromJson(t)).toList();
        state = state.copyWith(trips: cached, isOfflineData: true);
      }
    } catch (_) {}
  }

  Future<void> _saveCachedTrips(List<TripModel> trips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(trips.map((t) => t.toJson()).toList());
      await prefs.setString(_cachedTripsKey, encoded);
    } catch (_) {}
  }

  /// Helper to retrieve JWT token from secure storage and throw if missing
  Future<String> _getToken() async {
    final token = await _storage.read(key: 'token');
    if (token == null) {
      throw Exception('Session token is missing. Please log in again.');
    }
    return token;
  }

  /// Fetch all saved itineraries for the logged-in user
  Future<void> fetchTrips() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '${AppConfig.baseUrl}/trips',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final List data = response.data as List;
      final trips = data.map((t) => TripModel.fromJson(t)).toList();
      state = state.copyWith(trips: trips, isLoading: false, isOfflineData: false);
      _saveCachedTrips(trips);
    } on DioException catch (e) {
      // Fallback to offline cached trips if network failed
      await _loadCachedTrips();
      final msg = e.response?.data['message'] ?? 'Network offline. Showing cached itineraries.';
      state = state.copyWith(isLoading: false, isOfflineData: true, errorMessage: msg);
    } catch (e) {
      await _loadCachedTrips();
      state = state.copyWith(isLoading: false, isOfflineData: true, errorMessage: e.toString());
    }
  }

  /// Request Gemini to generate a travel itinerary, and append it to user saved list
  Future<bool> generateTrip(String destination, int daysCount, String travelStyle) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${AppConfig.baseUrl}/trips/generate',
        data: {
          'destination': destination,
          'daysCount': daysCount,
          'travelStyle': travelStyle,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final newTrip = TripModel.fromJson(response.data);
      state = state.copyWith(
        trips: [newTrip, ...state.trips],
        isLoading: false,
      );

      // Refresh authentication provider state to synchronize profile travelStats count
      _ref.read(authProvider.notifier).checkAuthStatus();
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to generate itinerary with AI.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Join a shared trip using an invite code
  Future<bool> joinTripByCode(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${AppConfig.baseUrl}/trips/join',
        data: {'inviteCode': code.trim().toUpperCase()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final joinedTrip = TripModel.fromJson(response.data);
      final exists = state.trips.any((t) => t.id == joinedTrip.id);
      if (!exists) {
        state = state.copyWith(
          trips: [joinedTrip, ...state.trips],
          isLoading: false,
        );
      } else {
        final updated = state.trips.map((t) => t.id == joinedTrip.id ? joinedTrip : t).toList();
        state = state.copyWith(trips: updated, isLoading: false);
      }
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to join trip with invite code.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Add a custom activity/event to a trip
  Future<bool> addCustomEvent(String tripId, int dayNumber, String time, String title, String description) async {
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${AppConfig.baseUrl}/trips/$tripId/events',
        data: {
          'dayNumber': dayNumber,
          'time': time,
          'title': title,
          'description': description,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final updatedTrip = TripModel.fromJson(response.data);
      final updated = state.trips.map((t) => t.id == updatedTrip.id ? updatedTrip : t).toList();
      state = state.copyWith(trips: updated);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add custom activity: $e');
      return false;
    }
  }

  /// Toggle upvote on a specific itinerary activity
  Future<void> toggleVote(String tripId, String eventId) async {
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${AppConfig.baseUrl}/trips/$tripId/events/$eventId/vote',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final updatedTrip = TripModel.fromJson(response.data);
      final updated = state.trips.map((t) => t.id == updatedTrip.id ? updatedTrip : t).toList();
      state = state.copyWith(trips: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to vote: $e');
    }
  }

  /// Delete a saved travel itinerary
  Future<void> deleteTrip(String tripId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _getToken();
      await _dio.delete(
        '${AppConfig.baseUrl}/trips/$tripId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final updatedTrips = state.trips.where((t) => t.id != tripId).toList();
      state = state.copyWith(trips: updatedTrips, isLoading: false);

      // Refresh authentication provider state to synchronize profile travelStats count
      _ref.read(authProvider.notifier).checkAuthStatus();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to delete itinerary.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Global trip provider declarations
final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier(ref);
});
