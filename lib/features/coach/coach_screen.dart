import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/eco_motion.dart';
import '../../core/state/providers.dart';
import '../../domain/models/user_profile.dart';
import 'coach_engine.dart';

/// Chat with the offline [RulesCoach]. No network is involved — answers are
/// rules-based and everything stays on this device.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  static const _emptyContext = CoachContext(
    profile: UserProfile(region: 'in'),
    categories: [],
    totalKg: 0,
    totalActions: 0,
    currentStreak: 0,
  );

  static const _suggestions = [
    'Improve my streak',
    'Give me an action',
    'Explain my impact',
    'What should I do today?',
  ];

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromUser: false,
      text: 'Hi! I am your offline climate coach. Ask me about your '
          'streak, new action ideas, or your CO₂e impact.',
    ),
  ];

  bool get _showSuggestions => _messages.length == 1;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(fromUser: true, text: text));
    });
    final context = ref.read(coachContextProvider).value;
    final reply =
        ref.read(coachServiceProvider).reply(text, context ?? _emptyContext);
    setState(() {
      _messages.add(_ChatMessage(fromUser: false, text: reply.message));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: EcoMotion.base,
        curve: EcoMotion.enter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate Coach'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(label: Text('Offline')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_showSuggestions ? 1 : 0),
              itemBuilder: (context, index) {
                if (_showSuggestions && index == _messages.length) {
                  return _Suggestions(
                    suggestions: _suggestions,
                    onPick: _send,
                  );
                }
                return _AnimatedMessage(message: _messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Fully offline — nothing leaves this device.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your streak, ideas, impact…',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _controller.text.trim().isEmpty
                        ? null
                        : () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.suggestions, required this.onPick});

  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try asking',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  label: Text(suggestion),
                  avatar: const Icon(Icons.bolt, size: 16),
                  onPressed: () => onPick(suggestion),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedMessage extends StatefulWidget {
  const _AnimatedMessage({super.key, required this.message});

  final _ChatMessage message;

  @override
  State<_AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<_AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: EcoMotion.fast,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubble = _MessageBubble(message: widget.message);
    if (EcoMotion.reduced(context)) return bubble;
    final curve = CurvedAnimation(parent: _controller, curve: EcoMotion.enter);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curve),
        child: bubble,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fromUser = message.fromUser;
    final bubbleColor =
        fromUser ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final textColor = fromUser ? scheme.onPrimaryContainer : scheme.onSurface;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(fromUser ? 16 : 4),
      bottomRight: Radius.circular(fromUser ? 4 : 16),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!fromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.eco, size: 18, color: scheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.74,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: radius,
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.35,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}
