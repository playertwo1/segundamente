import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/utils/user_storage.dart';

class RoutineCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const RoutineCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final habitName = data['habit_name'] as String? ?? '';
    final streak = (data['streak'] as num?)?.toInt() ?? 0;
    final rawHistory = data['history'];
    final allHistory = rawHistory is List
        ? rawHistory.map((value) => value == true).toList()
        : List<bool>.filled(7, false);
    final history = allHistory.length > 7
        ? allHistory.sublist(allHistory.length - 7)
        : allHistory;
    final today = DateUtils.dateOnly(DateTime.now());
    final narrowWeekdays = MaterialLocalizations.of(context).narrowWeekdays;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habitName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                UserStorage.l10n.routineStreakDays(streak),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 0; index < history.length; index++)
                Column(
                  children: [
                    Text(
                      narrowWeekdays[today
                              .subtract(
                                Duration(days: history.length - index - 1),
                              )
                              .weekday %
                          7],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: history[index]
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: history[index]
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
