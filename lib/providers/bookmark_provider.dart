import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/config.dart';
import 'explore_provider.dart';
import 'auth_provider.dart';

class BookmarkModel {
  final String id;
  final String title;
  final String category;
  final double rating;
  final String price;
  final String distance;
  final double latitude;
  final double longitude;

  BookmarkModel({
    required this.id,
    required this.title,
    required this.category,
    required this.rating,
    required this.price,
    required this.distance,
    required this.latitude,
    required this.longitude,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: json['price'] ?? '',
      distance: json['distance'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'rating': rating,
      'price': price,
      'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class BookmarkState {
  final List<BookmarkModel> bookmarks;
  final bool isLoading;
  final String? errorMessage;

  BookmarkState({
    required this.bookmarks,
    required this.isLoading,
    this.errorMessage,
  });

  factory BookmarkState.initial() => BookmarkState(
        bookmarks: [],
        isLoading: false,
        errorMessage: null,
      );

  BookmarkState copyWith({
    List<BookmarkModel>? bookmarks,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Ref _ref;

  BookmarkNotifier(this._ref) : super(BookmarkState.initial()) {
    fetchBookmarks();
  }

  bool isBookmarked(String title) {
    return state.bookmarks.any((b) => b.title.toLowerCase() == title.toLowerCase());
  }

  String? getBookmarkId(String title) {
    try {
      return state.bookmarks.firstWhere((b) => b.title.toLowerCase() == title.toLowerCase()).id;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchBookmarks() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Session token is missing.');
      }

      final response = await _dio.get(
        '${AppConfig.baseUrl}/bookmarks',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final List data = response.data as List;
      final bookmarks = data.map((b) => BookmarkModel.fromJson(b)).toList();
      state = state.copyWith(bookmarks: bookmarks, isLoading: false);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to load bookmarks.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addBookmark(PlaceModel place) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Session token is missing.');
      }

      final response = await _dio.post(
        '${AppConfig.baseUrl}/bookmarks',
        data: {
          'title': place.title,
          'category': place.category,
          'rating': place.rating,
          'price': place.price,
          'distance': place.distance,
          'latitude': place.latitude ?? 0.0,
          'longitude': place.longitude ?? 0.0,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final newBookmark = BookmarkModel.fromJson(response.data);
      state = state.copyWith(
        bookmarks: [newBookmark, ...state.bookmarks],
        isLoading: false,
      );

      // Sync active stats counters
      _ref.read(authProvider.notifier).checkAuthStatus();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to save place bookmark.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('Session token is missing.');
      }

      await _dio.delete(
        '${AppConfig.baseUrl}/bookmarks/$bookmarkId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      state = state.copyWith(
        bookmarks: state.bookmarks.where((b) => b.id != bookmarkId).toList(),
        isLoading: false,
      );

      // Sync active stats counters
      _ref.read(authProvider.notifier).checkAuthStatus();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to delete bookmark.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final bookmarkProvider = StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  return BookmarkNotifier(ref);
});
