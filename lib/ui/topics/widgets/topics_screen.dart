import 'package:flutter/material.dart';
import 'package:memex/domain/models/topic.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/ui/topics/view_models/topics_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

const _rowBorder = BoxDecoration(
  border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
);

/// Topics and projects as open rows. Tapping one opens the sessions it holds.
class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key, required this.viewModel});

  final TopicsViewModel viewModel;

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  Future<void> _create() async {
    final input = await _askName(context, isProjectChoice: true);
    if (input == null || !mounted) return;
    final ok =
        await widget.viewModel.create(input.name, isProject: input.isProject);
    if (!ok && mounted) _warn(context);
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
            title: Text(l10n.topicsTitle),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            leading: const AppBackButton(),
            actions: [
              IconButton(
                key: const ValueKey('topic_new'),
                tooltip: l10n.topicNew,
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: _create,
              ),
            ],
          ),
          body: vm.isLoading && vm.topics.isEmpty
              ? const Center(child: AgentLogoLoading())
              : vm.topics.isEmpty
                  ? _message(vm.errorMessage ?? l10n.topicsEmpty)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [for (final t in vm.topics) _row(t)],
                    ),
        );
      },
    );
  }

  Widget _row(Topic topic) {
    final l10n = UserStorage.l10n;
    final kind = topic.isProject ? l10n.topicKindProject : l10n.topicKindTopic;
    final count = l10n.topicSessionCount(topic.sessionIds.length);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${topic.name}, $kind, $count',
      onTap: () => _open(topic.id),
      child: InkWell(
        key: ValueKey('topic_row_${topic.id}'),
        onTap: () => _open(topic.id),
        child: DecoratedBox(
          decoration: _rowBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$kind · $count',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(String topicId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _TopicDetail(viewModel: widget.viewModel, topicId: topicId),
      ),
    );
  }
}

/// Sessions as checkboxes: marked ones belong to the topic.
class _TopicDetail extends StatelessWidget {
  const _TopicDetail({required this.viewModel, required this.topicId});

  final TopicsViewModel viewModel;
  final String topicId;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final topic =
            viewModel.topics.where((t) => t.id == topicId).firstOrNull;
        if (topic == null) {
          return const Scaffold(backgroundColor: AppColors.background);
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(topic.name),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            leading: const AppBackButton(),
            actions: [
              IconButton(
                key: const ValueKey('topic_rename'),
                tooltip: l10n.topicRename,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () async {
                  final input = await _askName(
                    context,
                    initial: topic.name,
                    isProjectChoice: false,
                  );
                  if (input == null || !context.mounted) return;
                  if (!await viewModel.rename(topic.id, input.name) &&
                      context.mounted) {
                    _warn(context);
                  }
                },
              ),
              IconButton(
                key: const ValueKey('topic_delete'),
                tooltip: l10n.delete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textSecondary,
                ),
                onPressed: () async {
                  if (!await _confirmDelete(context, topic.name)) return;
                  await viewModel.delete(topic.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: viewModel.sessions.isEmpty
              ? _message(l10n.topicSessionsEmpty)
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Text(
                        l10n.topicSessionsHint,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    for (final session in viewModel.sessions)
                      DecoratedBox(
                        decoration: _rowBorder,
                        child: CheckboxListTile(
                          key: ValueKey('topic_session_${session.id}'),
                          value: topic.sessionIds.contains(session.id),
                          activeColor: AppColors.primary,
                          checkColor: Colors.black,
                          title: Text(
                            session.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onChanged: (v) => viewModel.setLinked(
                            topic.id,
                            session.id,
                            v ?? false,
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

Widget _message(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );

void _warn(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(UserStorage.l10n.topicNameInvalid)),
  );
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final l10n = UserStorage.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${l10n.delete}: $name'),
      content: Text(l10n.topicDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey('topic_delete_confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<({String name, bool isProject})?> _askName(
  BuildContext context, {
  String initial = '',
  required bool isProjectChoice,
}) {
  final l10n = UserStorage.l10n;
  final controller = TextEditingController(text: initial);
  var isProject = false;
  return showDialog<({String name, bool isProject})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(initial.isEmpty ? l10n.topicNew : l10n.topicRename),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('topic_name_field'),
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.topicNameLabel),
            ),
            if (isProjectChoice)
              CheckboxListTile(
                key: const ValueKey('topic_is_project'),
                contentPadding: EdgeInsets.zero,
                value: isProject,
                activeColor: AppColors.primary,
                checkColor: Colors.black,
                title: Text(l10n.topicIsProject),
                onChanged: (v) => setState(() => isProject = v ?? false),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('topic_name_save'),
            onPressed: () => Navigator.pop(
              context,
              (name: controller.text, isProject: isProject),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}
