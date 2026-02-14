import 'package:flutter/material.dart';
import 'package:maxima_rpg/config/theme.dart';

/// Types of chat messages with different visual styling.
enum ChatMessageType {
  master,  // Gold, italic – Dungeon Master narration
  system,  // Gray – system/info messages
  player,  // White – player chat
  combat,  // Red – combat results
}

/// A single chat message with metadata.
class ChatMessage {
  final ChatMessageType type;
  final String sender;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.type,
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

/// Scrollable message list widget with auto-scroll and styled message types.
class ChatWidget extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController? scrollController;

  const ChatWidget({
    super.key,
    required this.messages,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RPGColors.black,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return _buildMessageTile(messages[index]);
        },
      ),
    );
  }

  /// Builds a single message tile styled according to its type.
  Widget _buildMessageTile(ChatMessage message) {
    TextStyle textStyle;
    TextStyle senderStyle;
    String prefix;
    EdgeInsets padding;

    switch (message.type) {
      case ChatMessageType.master:
        textStyle = RPGTextStyles.masterNarration;
        senderStyle = RPGTextStyles.masterNarration.copyWith(
          fontWeight: FontWeight.w800,
        );
        prefix = '[Maestro]';
        padding = const EdgeInsets.symmetric(vertical: 6, horizontal: 8);
        break;

      case ChatMessageType.system:
        textStyle = RPGTextStyles.systemMessage;
        senderStyle = RPGTextStyles.systemMessage.copyWith(
          fontWeight: FontWeight.w600,
        );
        prefix = '[Sistema]';
        padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8);
        break;

      case ChatMessageType.combat:
        textStyle = RPGTextStyles.combatMessage;
        senderStyle = RPGTextStyles.combatMessage.copyWith(
          fontWeight: FontWeight.w900,
        );
        prefix = '[Combate]';
        padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 8);
        break;

      case ChatMessageType.player:
        textStyle = RPGTextStyles.playerChat;
        senderStyle = RPGTextStyles.playerChat.copyWith(
          fontWeight: FontWeight.w700,
          color: RPGColors.purpleLight,
        );
        prefix = '[${message.sender}]';
        padding = const EdgeInsets.symmetric(vertical: 2, horizontal: 8);
        break;
    }

    // Master messages get a special background container.
    if (message.type == ChatMessageType.master) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: padding,
        decoration: BoxDecoration(
          color: RPGColors.darkGray.withOpacity(0.6),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: RPGColors.gold.withOpacity(0.6),
              width: 3,
            ),
          ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$prefix ', style: senderStyle),
              TextSpan(text: message.text, style: textStyle),
            ],
          ),
        ),
      );
    }

    // Combat messages get a red-tinted background.
    if (message.type == ChatMessageType.combat) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: padding,
        decoration: BoxDecoration(
          color: RPGColors.darkRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(text: '$prefix ', style: senderStyle),
              TextSpan(text: message.text, style: textStyle),
            ],
          ),
        ),
      );
    }

    // Default: system and player messages.
    return Padding(
      padding: padding,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$prefix ', style: senderStyle),
            TextSpan(text: message.text, style: textStyle),
          ],
        ),
      ),
    );
  }
}

/// A self-contained chat input field with a send button.
/// Can be used standalone outside of [ChatWidget].
class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Escribe un mensaje...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: RPGColors.darkGray,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: RPGTextStyles.playerChat,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle:
                    TextStyle(color: RPGColors.grayText.withOpacity(0.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: RPGColors.darkPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: RPGColors.darkPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: RPGColors.gold, width: 2),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: RPGColors.darkPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: RPGColors.gold,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
