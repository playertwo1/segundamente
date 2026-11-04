import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class HighlightCard extends StatelessWidget {
  final String title;
  final String quoteContent;
  final String? quoteHighlight;
  final String? footer;
  final String? theme;
  final String? date;
  final String? insight;
  final VoidCallback? onTap;

  const HighlightCard({
    super.key,
    this.title = 'DAILY INSIGHT',
    required this.quoteContent,
    this.quoteHighlight,
    this.footer,
    this.theme,
    this.date,
    this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: DAILY INSIGHT | date
            SizedBox(
              height: 26,
              child: Row(
                children: [
                  // Badge
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        letterSpacing: 0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(width: 10),
                    // Vertical divider
                    Container(
                      width: 1,
                      height: 9,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    // Date
                    Text(
                      date!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                        letterSpacing: -0.15,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Opening quote " — use negative margin to pull quote text closer
            Text(
              '\u201C',
              style: GoogleFonts.imbue(
                fontSize: 80,
                fontWeight: FontWeight.w700,
                height: 0.2,
                letterSpacing: 0.4,
                color: AppColors.divider,
              ),
            ),

            // Quote content (no extra spacing — quote height:0.2 keeps it tight)

            // Quote content
            Text(
              quoteContent,
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 38 / 30,
                letterSpacing: 0.4,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // Closing quote "
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '\u201D',
                style: GoogleFonts.imbue(
                  fontSize: 80,
                  fontWeight: FontWeight.w700,
                  height: 0.4,
                  letterSpacing: 0.4,
                  color: AppColors.divider,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer (author)
            if (footer != null)
              Text(
                footer!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 24 / 16,
                  letterSpacing: -0.31,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
