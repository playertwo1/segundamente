import 'package:flutter/material.dart';
import 'package:memex/domain/models/glossary.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/ui/glossary/view_models/glossary_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

/// Names, acronyms and products as open rows, with a preview of the text
/// that is added to the model request.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key, required this.viewModel});

  final GlossaryViewModel viewModel;

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final ok = await widget.viewModel.add(_controller.text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UserStorage.l10n.glossaryRejected)),
      );
    }
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
            title: Text(l10n.glossaryTitle),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            leading: const AppBackButton(),
          ),
          body: vm.isLoading && vm.terms.isEmpty
              ? const Center(child: AgentLogoLoading())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const ValueKey('glossary_field'),
                              controller: _controller,
                              onSubmitted: (_) => _add(),
                              decoration: InputDecoration(
                                labelText: l10n.glossaryAddLabel,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('glossary_add'),
                            onPressed: _add,
                            child: Text(l10n.glossaryAdd),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Text(
                        l10n.glossaryCount(vm.terms.length, glossaryMaxTerms),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (vm.terms.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          vm.errorMessage ?? l10n.glossaryEmpty,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    for (final term in vm.terms) _row(vm, term),
                    _preview(vm),
                  ],
                ),
        );
      },
    );
  }

  Widget _row(GlossaryViewModel vm, String term) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                term,
                style: const TextStyle(
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('glossary_remove_$term'),
            tooltip: UserStorage.l10n.glossaryRemove(term),
            icon: const Icon(
              Icons.close,
              color: AppColors.textSecondary,
            ),
            onPressed: () => vm.remove(term),
          ),
        ],
      ),
    );
  }

  Widget _preview(GlossaryViewModel vm) {
    final l10n = UserStorage.l10n;
    final text = vm.preview;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.glossaryPreviewTitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            key: const ValueKey('glossary_preview'),
            text.isEmpty ? l10n.glossaryPreviewNone : text,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
