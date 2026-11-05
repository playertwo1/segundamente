import 'package:flutter/material.dart';
import 'package:memex/domain/models/card_props.dart';
import 'package:memex/domain/models/saved_view.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/ui/saved_views/view_models/saved_views_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

/// Saved views as open rows. Tapping one closes the screen and returns its
/// tags, so the timeline shows the cards that carry all of them.
class SavedViewsScreen extends StatefulWidget {
  const SavedViewsScreen({super.key, required this.viewModel});

  final SavedViewsViewModel viewModel;

  @override
  State<SavedViewsScreen> createState() => _SavedViewsScreenState();
}

class _SavedViewsScreenState extends State<SavedViewsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  void _warn() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(UserStorage.l10n.savedViewInvalid)),
    );
  }

  Future<void> _create() async {
    final input = await _askNewView(context, widget.viewModel.tagNames);
    if (input == null || !mounted) return;
    if (!await widget.viewModel.create(input.name, input.tags) && mounted) {
      _warn();
    }
  }

  Future<void> _rename(SavedView view) async {
    final name = await _askName(context, view.name);
    if (name == null || !mounted) return;
    if (!await widget.viewModel.rename(view.id, name) && mounted) _warn();
  }

  Future<void> _delete(SavedView view) async {
    final l10n = UserStorage.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.delete}: ${view.name}'),
        content: Text(l10n.savedViewDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('view_delete_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) await widget.viewModel.delete(view.id);
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
            title: Text(l10n.savedViewsTitle),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            leading: const AppBackButton(),
            actions: [
              IconButton(
                key: const ValueKey('view_new'),
                tooltip: l10n.savedViewNew,
                icon: const Icon(Icons.add, color: AppColors.primary),
                onPressed: _create,
              ),
            ],
          ),
          body: vm.isLoading && vm.views.isEmpty
              ? const Center(child: AgentLogoLoading())
              : vm.views.isEmpty
                  ? _message(vm.errorMessage ?? l10n.savedViewsEmpty)
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [for (final v in vm.views) _row(v)],
                    ),
        );
      },
    );
  }

  Widget _row(SavedView view) {
    final l10n = UserStorage.l10n;
    return DecoratedBox(
      decoration: _rowBorder,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: '${view.name}, ${view.tags.map(_tagLabel).join(', ')}',
              onTap: () => Navigator.of(context).pop(view.tags),
              child: InkWell(
                key: ValueKey('view_row_${view.id}'),
                onTap: () => Navigator.of(context).pop(view.tags),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 4, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          view.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          view.tags.map(_tagLabel).join(' + '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('view_rename_${view.id}'),
            tooltip: l10n.topicRename,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _rename(view),
          ),
          IconButton(
            key: ValueKey('view_delete_${view.id}'),
            tooltip: l10n.delete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _delete(view),
          ),
        ],
      ),
    );
  }
}

/// A tag as the user sees it: derived properties get their own words.
String _tagLabel(String tag) {
  final l10n = UserStorage.l10n;
  return switch (propOfTag(tag)) {
    propLink => l10n.propLink,
    propTask => l10n.propTask,
    propOpenTask => l10n.propOpenTask,
    propCode => l10n.propCode,
    _ => tag,
  };
}

const _rowBorder = BoxDecoration(
  border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
);

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

Future<String?> _askName(BuildContext context, String initial) {
  final l10n = UserStorage.l10n;
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.topicRename),
      content: TextField(
        key: const ValueKey('view_name_field'),
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.savedViewNameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const ValueKey('view_name_save'),
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

Future<({String name, List<String> tags})?> _askNewView(
  BuildContext context,
  List<String> tagNames,
) {
  final l10n = UserStorage.l10n;
  final controller = TextEditingController();
  final marked = <String>{};
  return showDialog<({String name, List<String> tags})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.savedViewNew),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('view_name_field'),
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.savedViewNameLabel),
              ),
              const SizedBox(height: 12),
              Text(
                tagNames.isEmpty
                    ? l10n.savedViewNoTags
                    : l10n.savedViewPickTags,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in tagNames)
                      CheckboxListTile(
                        key: ValueKey('view_tag_$tag'),
                        contentPadding: EdgeInsets.zero,
                        value: marked.contains(tag),
                        activeColor: AppColors.primary,
                        checkColor: Colors.black,
                        title: Text(tag),
                        onChanged: (v) => setState(
                          () =>
                              v == true ? marked.add(tag) : marked.remove(tag),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        l10n.savedViewPickProps,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    for (final prop in cardPropNames)
                      CheckboxListTile(
                        key: ValueKey('view_prop_$prop'),
                        contentPadding: EdgeInsets.zero,
                        value: marked.contains(propTag(prop)),
                        activeColor: AppColors.primary,
                        checkColor: Colors.black,
                        title: Text(_tagLabel(propTag(prop))),
                        onChanged: (v) => setState(
                          () => v == true
                              ? marked.add(propTag(prop))
                              : marked.remove(propTag(prop)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('view_save'),
            onPressed: () => Navigator.pop(
              context,
              (name: controller.text, tags: marked.toList()),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}
