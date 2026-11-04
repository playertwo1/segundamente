import 'package:flutter/material.dart';
import 'package:memex/domain/models/session_report_export.dart';
import 'package:memex/ui/chat/view_models/session_report_viewmodel.dart';
import 'package:memex/ui/chat/widgets/session_report_view.dart';
import 'package:memex/utils/result.dart';
import 'package:memex/utils/share_service.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

class SessionReportScreen extends StatefulWidget {
  const SessionReportScreen({super.key, required this.viewModel});

  final SessionReportViewModel viewModel;

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.viewModel.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(UserStorage.l10n.sessionReportTitle),
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final viewModel = widget.viewModel;
          if (viewModel.loading && viewModel.report == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SessionReportView(
            report: viewModel.report,
            errorMessage: viewModel.errorMessage,
            onDraft: viewModel.draft,
            onDraftWithModel: viewModel.draftWithModel,
            usedLocalFallback: viewModel.usedLocalFallback,
            onEdit: viewModel.edit,
            onSetStatus: viewModel.setStatus,
            onExport: (format, itemIds) async {
              final result = await viewModel.export(
                format: format,
                itemIds: itemIds,
              );
              if (!mounted || result.isError) return;
              try {
                await ShareService.shareExistingFile(
                  context,
                  path: result.valueOrThrow,
                  mimeType: reportExportMimeType(format),
                );
              } catch (error) {
                if (!mounted) return;
                viewModel.showError(error);
              }
            },
          );
        },
      ),
    );
  }
}
