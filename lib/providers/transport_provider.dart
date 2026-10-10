import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transport_model.dart';
import '../utils/config.dart';

class TransportState {
  final List<TransportModel> transports;
  final bool isLoading;
  final String? errorMessage;

  TransportState({
    this.transports = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TransportState copyWith({
    List<TransportModel>? transports,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TransportState(
      transports: transports ?? this.transports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TransportNotifier extends StateNotifier<TransportState> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _cacheKey = 'cached_roamwise_transports_v1';

  TransportNotifier() : super(TransportState()) {
    _loadFromLocalCache();
    fetchTransports();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && state.transports.isEmpty) {
        final List list = jsonDecode(cachedJson);
        final loaded = list.map((item) => TransportModel.fromJson(item)).toList();
        state = state.copyWith(transports: loaded);
      }
    } catch (_) {}
  }

  Future<void> _saveToLocalCache(List<TransportModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(list.map((t) => t.toJson()).toList());
      await prefs.setString(_cacheKey, jsonString);
    } catch (_) {}
  }

  Future<void> fetchTransports() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final token = await _getToken();
      final response = await _dio.get(
        '${AppConfig.baseUrl}/transports',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data as List;
        final list = data.map((json) => TransportModel.fromJson(json)).toList();
        state = state.copyWith(transports: list, isLoading: false);
        _saveToLocalCache(list);
      }
    } catch (e) {
      if (state.transports.isEmpty) {
        await _loadFromLocalCache();
      }
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createTransport({
    required String transportType,
    required String carrier,
    required String transitNumber,
    required String departureCity,
    required String arrivalCity,
    String? departureCode,
    String? arrivalCode,
    String? departureTerminal,
    String? departureGate,
    DateTime? departureTime,
    DateTime? arrivalTime,
    String? seatNumber,
    String? seatClass,
    String? passengerName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final payload = {
      'transportType': transportType,
      'carrier': carrier,
      'transitNumber': transitNumber,
      'departureCity': departureCity,
      'departureCode': departureCode ?? departureCity.substring(0, 3).toUpperCase(),
      'departureTerminal': departureTerminal ?? 'T1',
      'departureGate': departureGate ?? 'A12',
      'departureTime': departureTime?.toIso8601String() ?? DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'arrivalCity': arrivalCity,
      'arrivalCode': arrivalCode ?? arrivalCity.substring(0, 3).toUpperCase(),
      'arrivalTerminal': 'T2',
      'arrivalGate': 'B4',
      'arrivalTime': arrivalTime?.toIso8601String() ?? DateTime.now().add(const Duration(days: 2, hours: 4)).toIso8601String(),
      'seatNumber': seatNumber ?? '14A',
      'seatClass': seatClass ?? 'Economy',
      'passengerName': passengerName ?? 'Alex Morgan',
    };

    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${AppConfig.baseUrl}/transports',
        data: payload,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        final newTransport = TransportModel.fromJson(response.data);
        final updated = [newTransport, ...state.transports];
        state = state.copyWith(transports: updated, isLoading: false);
        _saveToLocalCache(updated);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Network connection failed.');
      return false;
    }
  }

  Future<String?> refreshLiveStatus(String transportId) async {
    try {
      final token = await _getToken();
      final response = await _dio.post(
        '${AppConfig.baseUrl}/transports/$transportId/live-lookup',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final updatedTransport = TransportModel.fromJson(data['transport']);
        final updatedList = state.transports.map((t) => t.id == transportId ? updatedTransport : t).toList();
        state = state.copyWith(transports: updatedList);
        _saveToLocalCache(updatedList);
        return data['updateMessage']?.toString() ?? 'Status updated to ${updatedTransport.status}';
      }
    } catch (_) {}
    return null;
  }

  Future<void> deleteTransport(String transportId) async {
    final prev = state.transports;
    state = state.copyWith(transports: prev.where((t) => t.id != transportId).toList());
    _saveToLocalCache(state.transports);

    try {
      final token = await _getToken();
      await _dio.delete(
        '${AppConfig.baseUrl}/transports/$transportId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (_) {
      state = state.copyWith(transports: prev);
    }
  }
}

final transportProvider = StateNotifierProvider<TransportNotifier, TransportState>((ref) {
  return TransportNotifier();
});
