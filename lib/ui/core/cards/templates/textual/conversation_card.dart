import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/utils/user_storage.dart';

class ConversationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const ConversationCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rawMessages = data['messages'];
    final messages = rawMessages is List
        ? rawMessages.whereType<Map>().take(3).toList()
        : const <Map>[];
    final title = data['title']?.toString() ?? '';

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (messages.isEmpty)
            Text(
              UserStorage.l10n.noMessages,
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ...messages.map((message) {
            final sender = message['sender']?.toString() ?? '';
            final isMe = message['isMe'] == true || sender == 'me';
            final speaker = isMe ? UserStorage.l10n.youLabel : sender;
            final text = message['text']?.toString() ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    if (speaker.isNotEmpty)
                      TextSpan(
                        text: '$speaker: ',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    TextSpan(text: text),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
