import 'package:flutter/material.dart';
import 'package:memex/ui/chat/view_models/session_report_viewmodel.dart';
import 'package:memex/ui/chat/widgets/session_report_view.dart';
import 'package:memex/utils/user_storage.dart';

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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(UserStorage.l10n.sessionReportTitle),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
              onEdit: viewModel.edit,
              onSetStatus: viewModel.setStatus,
          );
        },
      ),
    );
  }
}
