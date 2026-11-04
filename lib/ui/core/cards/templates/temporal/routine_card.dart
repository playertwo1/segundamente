import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class RoutineCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const RoutineCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String habitName = data['habit_name'] ?? 'Routine';
    final int streak = (data['streak'] as num?)?.toInt() ?? 0;
    final List<bool> history =
        (data['history'] as List<dynamic>?)?.cast<bool>() ??
            List.filled(7, false);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: streak label + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT STREAK',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$streak',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DAYS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: const Center(
                  child: Icon(Icons.replay, color: AppColors.primary, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // History bars
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: history.map((completed) {
              return Container(
                width: 8,
                height: 28,
                decoration: BoxDecoration(
                  color: completed ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Habit name
          Text(
            habitName,
            style: const TextStyle(
              fontFamily: 'PingFang SC',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
