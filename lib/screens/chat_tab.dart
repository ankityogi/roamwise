import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/speech_provider.dart';

class ChatTab extends ConsumerStatefulWidget {
  const ChatTab({super.key});

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _animationValue = 1.2;

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _messageController.clear();

    // Scroll to the bottom after sending
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final speechState = ref.watch(speechProvider);
    final isListening = speechState.isListening;

    // Trigger auto-scroll on new messages
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    // Listen to speech recognition errors and display snackbar warnings
    ref.listen(speechProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Column(
      children: [
        // Quick Translator Shortcuts bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.g_translate, color: AppColors.accent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'AI Translator active',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: chatState.targetLanguage,
                dropdownColor: AppColors.surface,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                items: const [
                  DropdownMenuItem(value: 'JA', child: Text('EN ➔ JA (Japanese)')),
                  DropdownMenuItem(value: 'ES', child: Text('EN ➔ ES (Spanish)')),
                  DropdownMenuItem(value: 'FR', child: Text('EN ➔ FR (French)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(chatProvider.notifier).changeLanguage(val);
                  }
                },
              ),
            ],
          ),
        ),

        // Message Thread List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg['isMe'] as bool;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppColors.cardBorder, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['text'] as String,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          msg['time'] as String,
                          style: TextStyle(
                            color: isMe ? Colors.white60 : AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Loading Indicator
        if (chatState.isLoading)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12, left: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.accent),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Assistant is writing...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

        // Input Row
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        IconButton(
                          icon: isListening
                              ? TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 1.0, end: _animationValue),
                                  duration: const Duration(milliseconds: 600),
                                  onEnd: () {
                                    setState(() {
                                      _animationValue = _animationValue == 1.2 ? 0.8 : 1.2;
                                    });
                                  },
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: const Icon(Icons.mic, color: Colors.redAccent),
                                    );
                                  },
                                )
                              : const Icon(Icons.mic, color: AppColors.accent),
                          onPressed: () {
                            final notifier = ref.read(speechProvider.notifier);
                            if (isListening) {
                              notifier.stopListening();
                            } else {
                              notifier.startListening((words) {
                                _messageController.text = words;
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: isListening ? 'Listening...' : 'Ask or translate...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onSubmitted: (v) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
