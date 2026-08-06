import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/config.dart';

class ChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String targetLanguage; // 'JA', 'ES', 'FR'
  final String? errorMessage;

  ChatState({
    required this.messages,
    required this.isLoading,
    required this.targetLanguage,
    this.errorMessage,
  });

  factory ChatState.initial() {
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    return ChatState(
      messages: [
        {
          'isMe': false,
          'text': "Bonjour! I am your RoamWise Travel Assistant. \nHow can I help you explore today? Ask me for nearby sights, translation help, or travel tips!",
          'time': timeStr,
        }
      ],
      isLoading: false,
      targetLanguage: 'JA', // Default selected code
    );
  }

  ChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? targetLanguage,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ChatNotifier() : super(ChatState.initial());

  /// Update active translation target language dropdown selection
  void changeLanguage(String newLanguage) {
    state = state.copyWith(targetLanguage: newLanguage);
  }

  /// Send a new message, record it in local history, and fetch the AI response
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userTime = ChatState._formatTime(DateTime.now());
    final userMessage = {
      'isMe': true,
      'text': text,
      'time': userTime,
    };

    // Append user's message immediately
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      errorMessage: null,
    );

    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        throw Exception('User is not authenticated.');
      }

      // Build history excluding timestamps for backend context
      final historyPayload = state.messages.map((m) => {
        'isMe': m['isMe'],
        'text': m['text'],
      }).toList();

      // Remove the last message (which is the one we are posting right now) from history
      if (historyPayload.isNotEmpty) {
        historyPayload.removeLast();
      }

      final response = await _dio.post(
        '${AppConfig.baseUrl}/chat',
        data: {
          'message': text,
          'targetLanguage': state.targetLanguage,
          'history': historyPayload,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final aiTime = ChatState._formatTime(DateTime.now());
      final aiMessage = {
        'isMe': false,
        'text': response.data['response'] as String,
        'time': aiTime,
      };

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to reach AI Travel Assistant.';
      final aiTime = ChatState._formatTime(DateTime.now());
      final errorMessage = {
        'isMe': false,
        'text': '⚠️ Error: $msg',
        'time': aiTime,
      };

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    } catch (e) {
      final aiTime = ChatState._formatTime(DateTime.now());
      final errorMessage = {
        'isMe': false,
        'text': '⚠️ Error: ${e.toString()}',
        'time': aiTime,
      };

      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }
}

// Global chat provider declaration
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
