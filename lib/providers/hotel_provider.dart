import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/hotel_model.dart';
import '../utils/config.dart';

class HotelState {
  final bool isLoading;
  final List<HotelModel> hotels;
  final String searchCity;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestsCount;
  final String? errorMessage;

  HotelState({
    required this.isLoading,
    required this.hotels,
    required this.searchCity,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestsCount,
    this.errorMessage,
  });

  factory HotelState.initial() {
    final now = DateTime.now();
    return HotelState(
      isLoading: false,
      hotels: [],
      searchCity: 'Surat',
      checkInDate: now,
      checkOutDate: now.add(const Duration(days: 1)),
      guestsCount: 2,
    );
  }

  HotelState copyWith({
    bool? isLoading,
    List<HotelModel>? hotels,
    String? searchCity,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guestsCount,
    String? errorMessage,
  }) {
    return HotelState(
      isLoading: isLoading ?? this.isLoading,
      hotels: hotels ?? this.hotels,
      searchCity: searchCity ?? this.searchCity,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      guestsCount: guestsCount ?? this.guestsCount,
      errorMessage: errorMessage,
    );
  }
}

class HotelNotifier extends StateNotifier<HotelState> {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  HotelNotifier() : super(HotelState.initial()) {
    fetchHotels('Surat');
  }

  Future<void> fetchHotels([String? city]) async {
    final queryCity = city ?? state.searchCity;
    state = state.copyWith(isLoading: true, searchCity: queryCity, errorMessage: null);

    try {
      final response = await _dio.get(
        '${AppConfig.baseUrl}/hotels',
        queryParameters: {'city': queryCity},
      );

      final list = (response.data as List? ?? [])
          .map((item) => HotelModel.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, hotels: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load hotels. Showing cached or fallback options.',
      );
    }
  }

  void updateDates(DateTime checkIn, DateTime checkOut) {
    state = state.copyWith(checkInDate: checkIn, checkOutDate: checkOut);
  }

  void updateGuests(int guests) {
    state = state.copyWith(guestsCount: guests);
  }
}

final hotelProvider = StateNotifierProvider<HotelNotifier, HotelState>((ref) {
  return HotelNotifier();
});
