import 'package:flutter/material.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class ExperimentalLabPage extends StatelessWidget {
  const ExperimentalLabPage({
    super.key,
    required this.router,
  });

  final MemexRouter router;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.experimentalLab),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              l10n.experimentalLabDescription,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
