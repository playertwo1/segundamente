import 'package:flutter/material.dart';
import 'package:memex/ui/agent_activity/view_models/agent_activity_viewmodel.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/utils/user_storage.dart';

/// "Atividade em segundo plano" (reference 18): what the agents are doing and
/// what failed, as an open list with thin dividers.
class AgentActivityScreen extends StatefulWidget {
  const AgentActivityScreen({
    super.key,
    required this.viewModel,
    this.onBackToTimeline,
  });

  final AgentActivityViewModel viewModel;

  /// Action of the empty state; defaults to popping the screen.
  final VoidCallback? onBackToTimeline;

  @override
  State<AgentActivityScreen> createState() => _AgentActivityScreenState();
}

class _AgentActivityScreenState extends State<AgentActivityScreen> {
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
        final empty = !vm.loading && vm.isEmpty && !vm.loadFailed;
        return EditorialScaffold(
          title: empty ? l10n.activityMenu : l10n.activityHeading,
          subtitle:
              empty || vm.updatedAt == null ? null : l10n.activityUpdatedNow,
          body: vm.loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(onRefresh: vm.load, child: _content(vm)),
        );
      },
    );
  }

  Widget _content(AgentActivityViewModel vm) {
    final l10n = UserStorage.l10n;
    if (vm.loadFailed) {
      return ListView(
        children: [
          const SizedBox(height: 48),
          Center(
            child: Text(
              l10n.activityLoadFailed,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: vm.load,
            child: Text(
              l10n.retry,
              style: const TextStyle(color: AppColors.primary, fontSize: 16),
            ),
          ),
        ],
      );
    }
    if (vm.isEmpty) return _empty();
    final now = vm.now;
    return ListView(
      children: [
        const Divider(height: 1, color: AppColors.divider),
        for (final item in vm.running) _ActivityRow(item: item, now: now),
        for (final item in vm.failed) _ActivityRow(item: item, now: now),
      ],
    );
  }

  Widget _empty() {
    final l10n = UserStorage.l10n;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 56),
        const Icon(Icons.inbox_outlined, size: 72, color: AppColors.textPrimary),
        const SizedBox(height: 24),
        Text(
          l10n.activityEmptyTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.activityEmptyBody,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        const Divider(height: 1, color: AppColors.divider),
        EditorialRow(
          title: l10n.activityBackToTimeline,
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textPrimary,
          ),
          onTap: widget.onBackToTimeline ??
              () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.now});

  final ActivityItem item;
  final DateTime now;

  static String _title(String type) {
    final l10n = UserStorage.l10n;
    if (type == 'add_task') return l10n.activityTaskAddRecord;
    if (type == 'super_agent_chat_turn_task') return l10n.activityTaskChat;
    if (type == 'comment_agent_task' || type == 'reprocess_comments_task') {
      return l10n.activityTaskComment;
    }
    if (type.startsWith('character_')) return l10n.activityTaskCharacter;
    return l10n.activityTaskOther;
  }

  static String _elapsed(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds < 0 ? 0 : d.inSeconds} s';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    return '${d.inHours} h';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final failed = item.kind == ActivityKind.failed;
    final elapsed = item.elapsed(now);
    final detail = failed
        ? l10n.activityFailedBody
        : [
            if (item.retryCount > 0)
              l10n.activityRetryProgress(item.retryCount, item.maxRetries),
            if (elapsed != null) l10n.activityStartedAgo(_elapsed(elapsed)),
          ].join(' · ');
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: failed
                ? const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.textPrimary,
                    size: 28,
                  )
                : const Padding(
                    padding: EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (failed
                          ? l10n.activitySectionFailed
                          : l10n.activitySectionRunning)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _title(item.type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
