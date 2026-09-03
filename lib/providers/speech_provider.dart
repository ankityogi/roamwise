import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechState {
  final bool isListening;
  final String recognizedWords;
  final bool isAvailable;
  final String? errorMessage;

  SpeechState({
    required this.isListening,
    required this.recognizedWords,
    required this.isAvailable,
    this.errorMessage,
  });

  factory SpeechState.initial() => SpeechState(
        isListening: false,
        recognizedWords: '',
        isAvailable: false,
        errorMessage: null,
      );

  SpeechState copyWith({
    bool? isListening,
    String? recognizedWords,
    bool? isAvailable,
    String? errorMessage,
  }) {
    return SpeechState(
      isListening: isListening ?? this.isListening,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      isAvailable: isAvailable ?? this.isAvailable,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SpeechNotifier extends StateNotifier<SpeechState> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  SpeechNotifier() : super(SpeechState.initial()) {
    initSpeech();
  }

  Future<void> initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            state = state.copyWith(isListening: false);
          } else if (status == 'listening') {
            state = state.copyWith(isListening: true);
          }
        },
        onError: (val) {
          state = state.copyWith(
            isListening: false,
            errorMessage: 'Speech error: ${val.errorMsg}',
          );
        },
      );
      state = state.copyWith(isAvailable: available, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        errorMessage: 'Failed to initialize speech recognition: ${e.toString()}',
      );
    }
  }

  Future<void> startListening(Function(String) onWordsRecognized) async {
    if (!state.isAvailable) {
      await initSpeech();
      if (!state.isAvailable) {
        state = state.copyWith(errorMessage: 'Speech recognition is not available on this device.');
        return;
      }
    }

    state = state.copyWith(isListening: true, recognizedWords: '', errorMessage: null);
    
    try {
      await _speech.listen(
        onResult: (result) {
          state = state.copyWith(recognizedWords: result.recognizedWords);
          onWordsRecognized(result.recognizedWords);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Failed to start listening: ${e.toString()}',
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
    state = state.copyWith(isListening: false, recognizedWords: '');
  }
}

final speechProvider = StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  return SpeechNotifier();
});
