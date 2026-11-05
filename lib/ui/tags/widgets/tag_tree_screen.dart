import 'package:flutter/material.dart';
import 'package:memex/domain/models/tag_tree.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/ui/tags/view_models/tag_tree_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

/// Tags as a tree (`area/projeto` under `area`) with card counts. Tapping a
/// row closes the screen and returns that tag to filter the timeline; the
/// chevron only opens or closes the branch.
class TagTreeScreen extends StatefulWidget {
  const TagTreeScreen({super.key, required this.viewModel});

  final TagTreeViewModel viewModel;

  @override
  State<TagTreeScreen> createState() => _TagTreeScreenState();
}

class _TagTreeScreenState extends State<TagTreeScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(UserStorage.l10n.tagTreeTitle),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            leading: const AppBackButton(),
          ),
          body: _body(vm),
        );
      },
    );
  }

  Widget _body(TagTreeViewModel vm) {
    if (vm.isLoading && vm.roots.isEmpty) {
      return const Center(child: AgentLogoLoading());
    }
    if (vm.roots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            vm.errorMessage ?? UserStorage.l10n.tagTreeEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final rows = <Widget>[];
    void add(TagTreeNode node, int depth) {
      rows.add(_row(vm, node, depth));
      if (vm.expanded.contains(node.path)) {
        for (final child in node.children) {
          add(child, depth + 1);
        }
      }
    }

    for (final root in vm.roots) {
      add(root, 0);
    }
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: rows);
  }

  Widget _row(TagTreeViewModel vm, TagTreeNode node, int depth) {
    final hasChildren = node.children.isNotEmpty;
    final open = vm.expanded.contains(node.path);
    final material = MaterialLocalizations.of(context);
    return DecoratedBox(
      key: ValueKey('tag_row_${node.path}'),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 12.0 + 20.0 * depth),
          SizedBox(
            width: 48,
            height: 56,
            child: hasChildren
                ? IconButton(
                    key: ValueKey('tag_toggle_${node.path}'),
                    tooltip: open
                        ? material.expandedIconTapHint
                        : material.collapsedIconTapHint,
                    icon: Icon(
                      open ? Icons.expand_more : Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => vm.toggle(node.path),
                  )
                : null,
          ),
          Expanded(
            child: Semantics(
              button: true,
              excludeSemantics: true,
              label: '${node.path}, '
                  '${UserStorage.l10n.globalSearchCount(node.count)}',
              onTap: () => Navigator.of(context).pop(node.path),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(node.path),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          node.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${node.count}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
