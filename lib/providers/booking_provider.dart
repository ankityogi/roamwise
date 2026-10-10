import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import '../utils/config.dart';

class BookingState {
  final bool isLoading;
  final bool isSubmitting;
  final bool isOfflineData;
  final List<BookingModel> bookings;
  final BookingModel? lastConfirmedBooking;
  final String? errorMessage;
  final String? successMessage;

  BookingState({
    required this.isLoading,
    required this.isSubmitting,
    this.isOfflineData = false,
    required this.bookings,
    this.lastConfirmedBooking,
    this.errorMessage,
    this.successMessage,
  });

  factory BookingState.initial() {
    return BookingState(
      isLoading: false,
      isSubmitting: false,
      isOfflineData: false,
      bookings: [],
    );
  }

  BookingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isOfflineData,
    List<BookingModel>? bookings,
    BookingModel? lastConfirmedBooking,
    String? errorMessage,
    String? successMessage,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isOfflineData: isOfflineData ?? this.isOfflineData,
      bookings: bookings ?? this.bookings,
      lastConfirmedBooking: lastConfirmedBooking ?? this.lastConfirmedBooking,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _cachedBookingsKey = 'roamwise_cached_bookings';

  BookingNotifier() : super(BookingState.initial()) {
    _loadCachedBookings();
    fetchMyBookings();
  }

  Future<void> _loadCachedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cachedBookingsKey);
      if (cachedJson != null && state.bookings.isEmpty) {
        final List list = jsonDecode(cachedJson);
        final cached = list.map((b) => BookingModel.fromJson(b)).toList();
        state = state.copyWith(bookings: cached, isOfflineData: true);
      }
    } catch (_) {}
  }

  Future<void> _saveCachedBookings(List<BookingModel> bookings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(bookings.map((b) => b.toJson()).toList());
      await prefs.setString(_cachedBookingsKey, encoded);
    } catch (_) {}
  }

  Future<void> fetchMyBookings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        await _loadCachedBookings();
        state = state.copyWith(isLoading: false);
        return;
      }

      final response = await _dio.get(
        '${AppConfig.baseUrl}/bookings/my-bookings',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final list = (response.data as List? ?? [])
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(isLoading: false, bookings: list, isOfflineData: false);
      _saveCachedBookings(list);
    } catch (e) {
      await _loadCachedBookings();
      state = state.copyWith(
        isLoading: false,
        isOfflineData: true,
        errorMessage: 'Unable to connect. Showing cached reservations.',
      );
    }
  }

  Future<BookingModel?> createReservation({
    required Map<String, dynamic> hotelData,
    required String roomType,
    required double pricePerNight,
    required int numberOfRooms,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int adults,
    required int children,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    String specialRequests = '',
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('You must be logged in to complete a hotel booking.');
      }

      final response = await _dio.post(
        '${AppConfig.baseUrl}/bookings',
        data: {
          'hotel': hotelData,
          'roomType': roomType,
          'pricePerNight': pricePerNight,
          'numberOfRooms': numberOfRooms,
          'checkInDate': checkInDate.toIso8601String(),
          'checkOutDate': checkOutDate.toIso8601String(),
          'guests': {
            'adults': adults,
            'children': children,
          },
          'contactDetails': {
            'name': guestName,
            'email': guestEmail,
            'phone': guestPhone,
          },
          'specialRequests': specialRequests,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final newBooking = BookingModel.fromJson(response.data['booking']);
      final updatedList = [newBooking, ...state.bookings];

      state = state.copyWith(
        isSubmitting: false,
        bookings: updatedList,
        lastConfirmedBooking: newBooking,
        successMessage: 'Reservation confirmed successfully!',
      );

      return newBooking;
    } catch (e) {
      String msg = 'Failed to confirm reservation. Please try again.';
      if (e is DioException && e.response?.data != null && e.response?.data['message'] != null) {
        msg = e.response!.data['message'].toString();
      }
      state = state.copyWith(isSubmitting: false, errorMessage: msg);
      return null;
    }
  }

  Future<bool> cancelReservation(String bookingId) async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return false;

      await _dio.post(
        '${AppConfig.baseUrl}/bookings/$bookingId/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Update local state to cancelled
      final updated = state.bookings.map((b) {
        if (b.id == bookingId) {
          return BookingModel(
            id: b.id,
            bookingReference: b.bookingReference,
            hotelTitle: b.hotelTitle,
            hotelImage: b.hotelImage,
            hotelLocation: b.hotelLocation,
            hotelRating: b.hotelRating,
            roomType: b.roomType,
            pricePerNight: b.pricePerNight,
            numberOfRooms: b.numberOfRooms,
            checkInDate: b.checkInDate,
            checkOutDate: b.checkOutDate,
            numberOfNights: b.numberOfNights,
            guests: b.guests,
            contactDetails: b.contactDetails,
            specialRequests: b.specialRequests,
            pricing: b.pricing,
            status: 'cancelled',
            createdAt: b.createdAt,
          );
        }
        return b;
      }).toList();

      state = state.copyWith(bookings: updated, successMessage: 'Booking cancelled.');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to cancel booking.');
      return false;
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier();
});
