import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/ui/glass_card.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String merchant = data['merchant'] ?? 'Merchant';
    final String amount = data['amount']?.toString() ?? '0.00';
    final String location = data['location'] ?? 'Online';
    final List<Map<String, dynamic>> items = (data['items'] as List<dynamic>?)
            ?.map((item) =>
                item is Map<String, dynamic> ? item : <String, dynamic>{})
            .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          // Background simulation for receipt
          GlassCard(
            onTap: onTap,
            padding: EdgeInsets.zero,
            borderRadius: 20,
            child: Column(
              children: [
                // Top Half
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchant,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textTertiary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              amount,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Separator
                _buildDashedLine(),
                // Items
                if (items.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.background, // Slight offset color
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _buildLineItem(
                            items[i]['name'] as String? ?? 'Item ${i + 1}',
                            items[i]['amount']?.toString() ?? '0.00',
                          ),
                        ],
                      ],
                    ),
                  ),
                // Bottom
                Container(
                  height: 12,
                  color: AppColors.background,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(String name, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          price,
          style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: const DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.divider),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    var max = size.width;
    var dashWidth = 5;
    var dashSpace = 3;
    double startX = 0;
    while (startX < max) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
