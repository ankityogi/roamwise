import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/config.dart';

// Client-side representation of recommended places from the AI engine
class PlaceModel {
  final String title;
  final String category;
  final double rating;
  final String price;
  final String distance;

  PlaceModel({
    required this.title,
    required this.category,
    required this.rating,
    required this.price,
    required this.distance,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: json['price'] ?? '',
      distance: json['distance'] ?? '',
    );
  }
}

class ExploreState {
  final List<PlaceModel> places;
  final bool isLoading;
  final String? errorMessage;
  final String searchCity;
  final String selectedCategory;

  ExploreState({
    required this.places,
    required this.isLoading,
    this.errorMessage,
    required this.searchCity,
    required this.selectedCategory,
  });

  factory ExploreState.initial() => ExploreState(
        places: [],
        isLoading: false,
        searchCity: 'Paris, France',
        selectedCategory: 'All',
      );

  ExploreState copyWith({
    List<PlaceModel>? places,
    bool? isLoading,
    String? errorMessage,
    String? searchCity,
    String? selectedCategory,
  }) {
    return ExploreState(
      places: places ?? this.places,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchCity: searchCity ?? this.searchCity,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class ExploreNotifier extends StateNotifier<ExploreState> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ExploreNotifier() : super(ExploreState.initial()) {
    fetchPlaces();
  }

  Future<void> updateSearchCity(String city) async {
    state = state.copyWith(searchCity: city);
    await fetchPlaces();
  }

  Future<void> updateCategory(String category) async {
    state = state.copyWith(selectedCategory: category);
    await fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Session token is missing. Please log in again.');
      }

      final response = await _dio.get(
        '${AppConfig.baseUrl}/explore/places',
        queryParameters: {
          'city': state.searchCity,
          'category': state.selectedCategory,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final List data = response.data as List;
      final places = data.map((p) => PlaceModel.fromJson(p)).toList();
      state = state.copyWith(places: places, isLoading: false);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to load local explore locations.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final exploreProvider = StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  return ExploreNotifier();
});
