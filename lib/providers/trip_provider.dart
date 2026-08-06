import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/trip_model.dart';
import '../utils/config.dart';
import 'auth_provider.dart';

class TripState {
  final List<TripModel> trips;
  final bool isLoading;
  final String? errorMessage;

  TripState({
    required this.trips,
    required this.isLoading,
    this.errorMessage,
  });

  factory TripState.initial() => TripState(trips: [], isLoading: false);

  TripState copyWith({
    List<TripModel>? trips,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TripState(
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  final Ref _ref;
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  TripNotifier(this._ref) : super(TripState.initial()) {
    // Automatically load trips list on initialization
    fetchTrips();
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
      state = state.copyWith(trips: trips, isLoading: false);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to load travel itineraries.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
