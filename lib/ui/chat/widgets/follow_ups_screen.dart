import 'package:flutter/material.dart';
import 'package:memex/ui/chat/view_models/follow_ups_viewmodel.dart';
import 'package:memex/ui/chat/widgets/follow_ups_view.dart';
import 'package:memex/ui/revisions/view_models/report_revisions_viewmodel.dart';
import 'package:memex/ui/revisions/widgets/report_revisions_screen.dart';
import 'package:memex/utils/toast_helper.dart';
import 'package:memex/utils/user_storage.dart';

class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key, required this.viewModel});

  final FollowUpsViewModel viewModel;

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
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
      appBar: AppBar(
        title: Text(UserStorage.l10n.followUpsTitle),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final viewModel = widget.viewModel;
          if (viewModel.loading && viewModel.hits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null && viewModel.hits.isEmpty) {
            return Center(child: Text(viewModel.errorMessage!));
          }
          return FollowUpsView(
            hits: viewModel.hits,
            textChanges: viewModel.textChanges,
            onSearch: viewModel.search,
            onAddToCalendar: (hit) async {
              final opened = await viewModel.addToCalendar(hit);
              if (!opened && context.mounted) {
                ToastHelper.showError(
                  context,
                  UserStorage.l10n.addToCalendarFailed,
                );
              }
            },
            onOpenRevisions: (hit) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReportRevisionsScreen(
                    viewModel: ReportRevisionsViewModel(
                      router: widget.viewModel.router,
                      sessionId: hit.sessionId,
                      itemId: hit.item.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
