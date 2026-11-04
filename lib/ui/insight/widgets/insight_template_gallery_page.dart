import 'package:flutter/material.dart';
import 'package:memex/ui/core/cards/native_widget_factory.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

@visibleForTesting
String insightTemplateBuildError(String templateId) =>
    UserStorage.l10n.operationFailed(templateId);

class InsightTemplateGalleryPage extends StatelessWidget {
  const InsightTemplateGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = UserStorage.l10n.insightTemplateGalleryItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          UserStorage.l10n.insightTemplateGalleryTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final item in items)
            _buildSection(item.label, item.templateId, item.data),
        ],
      ),
    );
  }

  Widget _buildSection(
      String label, String templateId, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 22),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        NativeWidgetFactory.build(templateId, data) ??
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.red.shade50,
              child: Text(insightTemplateBuildError(templateId)),
            ),
      ],
    );
  }
}
