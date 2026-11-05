import 'package:flutter/material.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/session_report_export.dart';
import 'package:memex/ui/corrections/view_models/corrections_viewmodel.dart';
import 'package:memex/ui/corrections/widgets/corrections_screen.dart';
import 'package:memex/ui/revisions/view_models/report_revisions_viewmodel.dart';
import 'package:memex/ui/revisions/widgets/report_revisions_screen.dart';
import 'package:provider/provider.dart';
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
        actions: [
          IconButton(
            key: const ValueKey('report_revisions'),
            tooltip: UserStorage.l10n.reportRevisionsTitle,
            icon: const Icon(Icons.history, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReportRevisionsScreen(
                  viewModel: ReportRevisionsViewModel(
                    router: context.read<MemexRouter>(),
                    sessionId: widget.viewModel.sessionId,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('report_corrections'),
            tooltip: UserStorage.l10n.correctionsOpen,
            icon: const Icon(Icons.spellcheck, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CorrectionsScreen(
                  viewModel: CorrectionsViewModel(
                    router: context.read<MemexRouter>(),
                    sessionId: widget.viewModel.sessionId,
                  ),
                ),
              ),
            ),
          ),
        ],
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
              if (!mounted || !context.mounted || result.isError) return;
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
