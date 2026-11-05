import 'package:flutter/material.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/back_button.dart';
import 'package:memex/ui/corrections/view_models/corrections_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

/// Swaps proposed from the term dictionary, as checkboxes. Saving writes a
/// separate file; the imported original is never changed.
class CorrectionsScreen extends StatefulWidget {
  const CorrectionsScreen({super.key, required this.viewModel});

  final CorrectionsViewModel viewModel;

  @override
  State<CorrectionsScreen> createState() => _CorrectionsScreenState();
}

class _CorrectionsScreenState extends State<CorrectionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  Future<void> _save() async {
    final ok = await widget.viewModel.save();
    if (!mounted) return;
    final l10n = UserStorage.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.correctionsSaved : l10n.correctionsRefused),
      ),
    );
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
            title: Text(l10n.correctionsTitle),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            leading: const AppBackButton(),
          ),
          body: vm.isLoading
              ? const Center(child: AgentLogoLoading())
              : vm.rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.correctionsEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: Text(
                            l10n.correctionsHint,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        for (var i = 0; i < vm.rows.length; i++)
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.divider,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: CheckboxListTile(
                              key: ValueKey('correction_$i'),
                              value: vm.marked.contains(i),
                              activeColor: AppColors.primary,
                              checkColor: Colors.black,
                              title: Text(
                                '${vm.rows[i].from} → ${vm.rows[i].to}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(vm.rows[i].segmentId),
                              onChanged: (_) => vm.toggle(i),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: FilledButton(
                            key: const ValueKey('corrections_save'),
                            onPressed: _save,
                            child: Text(l10n.correctionsSave),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}
