import 'package:flutter/material.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/ui/revisions/view_models/report_revisions_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

class ReportRevisionsScreen extends StatefulWidget {
  const ReportRevisionsScreen({super.key, required this.viewModel});

  final ReportRevisionsViewModel viewModel;

  @override
  State<ReportRevisionsScreen> createState() => _ReportRevisionsScreenState();
}

class _ReportRevisionsScreenState extends State<ReportRevisionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(l10n.reportRevisionsTitle),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            elevation: 0,
            leading: const AppBackButton(),
          ),
          body: vm.isLoading
              ? const Center(child: AgentLogoLoading())
              : vm.errorMessage != null && vm.revisions.isEmpty
                  ? Center(
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : vm.revisions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              l10n.reportRevisionsEmpty,
                              key: const ValueKey('report_revisions_empty'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: vm.revisions.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: AppColors.divider,
                            height: 24,
                          ),
                          itemBuilder: (context, index) {
                            final rev = vm.revisions[index];
                            final itemLabel = vm.itemLabels[rev.itemId];
                            return _RevisionTile(
                              revision: rev,
                              itemLabel: itemLabel,
                              index: index,
                            );
                          },
                        ),
        );
      },
    );
  }
}

class _RevisionTile extends StatelessWidget {
  const _RevisionTile({
    required this.revision,
    required this.itemLabel,
    required this.index,
  });

  final ReportRevision revision;
  final String? itemLabel;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final fieldLabel = switch (revision.field) {
      'text' => l10n.reportRevisionFieldText,
      'status' => l10n.reportRevisionFieldStatus,
      _ => revision.field,
    };

    return Container(
      key: ValueKey('revision_tile_${revision.itemId}_$index'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  fieldLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (revision.at.isNotEmpty)
                Text(
                  _formatDate(revision.at),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          if (itemLabel != null && itemLabel!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              itemLabel!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                revision.before,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('→', style: TextStyle(color: AppColors.primary)),
              ),
              Text(
                revision.after,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (revision.reason.isNotEmpty && revision.reason != 'não informado') ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.reportRevisionReasonLabel}: ',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    revision.reason,
                    key: ValueKey('revision_reason_${revision.itemId}_$index'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      String pad(int n) => n.toString().padLeft(2, '0');
      return '${pad(dt.day)}/${pad(dt.month)}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }
}
