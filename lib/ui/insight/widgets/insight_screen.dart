import 'dart:async';
import 'package:memex/ui/core/themes/app_colors.dart';

import 'package:flutter/material.dart';

import 'package:memex/domain/models/knowledge_insight_card.dart';
import 'package:memex/ui/insight/view_models/insight_viewmodel.dart';
import 'insight_detail_page.dart';
import 'package:memex/utils/toast_helper.dart';
import 'package:memex/ui/core/cards/native_widget_factory.dart';
import 'package:memex/ui/core/widgets/html_webview_card.dart';
import 'package:memex/utils/user_storage.dart';

/// Insight screen - global knowledge analytics. Receives [viewModel] from parent (Compass-style).
class InsightScreen extends StatefulWidget {
  final InsightViewModel viewModel;
  final bool isEmbedded;

  const InsightScreen({
    super.key,
    required this.viewModel,
    this.isEmbedded = false,
  });

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  Future<void> _onTogglePin(
    InsightViewModel vm,
    KnowledgeInsightCard item,
  ) async {
    try {
      await vm.togglePin(item);
      if (mounted) {
        ToastHelper.showSuccess(
          context,
          item.isPinned
              ? UserStorage.l10n.unpinned
              : UserStorage.l10n.pinnedStyle,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(
          context,
          UserStorage.l10n.operationFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _saveSortOrder(InsightViewModel vm) async {
    try {
      await vm.saveSortOrder();
      if (mounted) {
        ToastHelper.showSuccess(context, UserStorage.l10n.sortUpdated);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(
          context,
          UserStorage.l10n.sortSaveFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _onDeleteCard(
    InsightViewModel vm,
    KnowledgeInsightCard item,
  ) async {
    try {
      await vm.deleteCard(item);
      if (mounted) {
        ToastHelper.showSuccess(context, UserStorage.l10n.insightCardDeleted);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(
          context,
          UserStorage.l10n.deleteFailedShort(e.toString()),
        );
      }
    }
  }

  Widget _buildPinButton(InsightViewModel vm, KnowledgeInsightCard item) {
    final isPinning = vm.pinningIds.contains(item.id);
    return IconButton(
      tooltip: item.isPinned
          ? UserStorage.l10n.unpinned
          : UserStorage.l10n.pinnedStyle,
      onPressed: isPinning ? null : () => _onTogglePin(vm, item),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: isPinning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
              ),
            )
          : Icon(
              item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              size: 20,
              color:
                  item.isPinned ? AppColors.primary : AppColors.textSecondary,
            ),
    );
  }

  Widget _buildActionOverlay(InsightViewModel vm, KnowledgeInsightCard item) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => vm.setActiveCardId(null),
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 140,
                      child: TextButton.icon(
                        onPressed: () {
                          vm.setActiveCardId(null);
                          vm.setReordering(true);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(140, 56),
                        ),
                        icon: const Icon(Icons.swap_vert_outlined),
                        label: Text(UserStorage.l10n.reorderInsights),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: TextButton.icon(
                        onPressed: vm.isDeleting
                            ? null
                            : () => _onDeleteCard(vm, item),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(140, 56),
                        ),
                        icon: vm.isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: Text(UserStorage.l10n.delete),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: UserStorage.l10n.cancel,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => vm.setActiveCardId(null),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _insightListHeaderCount(InsightViewModel vm) {
    var count = 0;
    if (widget.isEmbedded) count += 1;
    if (!widget.isEmbedded || vm.isReordering) count += 2;
    return count;
  }

  int _insightListItemCount(InsightViewModel vm) {
    final headerCount = _insightListHeaderCount(vm);
    if (vm.isLoading || vm.errorMessage != null) return headerCount + 1;
    final insights = vm.insights;
    if (insights == null || insights.isEmpty) return headerCount + 1;
    return headerCount + insights.length;
  }

  Widget _buildInsightListItem(
    BuildContext context,
    InsightViewModel vm,
    int index,
  ) {
    final headerCount = _insightListHeaderCount(vm);
    var cursor = 0;
    if (widget.isEmbedded) {
      if (index == cursor) return const SizedBox(height: 16);
      cursor += 1;
    }
    if (!widget.isEmbedded || vm.isReordering) {
      if (index == cursor) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!widget.isEmbedded)
              Text(
                UserStorage.l10n.knowledgeInsight,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              )
            else if (vm.isReordering)
              const Spacer(),
            if (vm.isReordering)
              TextButton.icon(
                onPressed: () => _saveSortOrder(vm),
                icon: const Icon(Icons.check),
                label: Text(UserStorage.l10n.completeSort),
              ),
          ],
        );
      }
      cursor += 1;
      if (index == cursor) return const SizedBox(height: 16);
      cursor += 1;
    }

    if (vm.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (vm.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Text(
                vm.errorMessage!,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => vm.loadData(),
                child: Text(UserStorage.l10n.reload),
              ),
            ],
          ),
        ),
      );
    }
    final insights = vm.insights;
    if (insights == null || insights.isEmpty) {
      return _buildPreviewCards();
    }
    final item = insights[index - headerCount];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onLongPress: () => vm.setActiveCardId(item.id),
        child: Stack(
          children: [
            _buildItemCard(
              vm,
              item,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InsightDetailPage.insight(insightId: item.id),
                  ),
                );
              },
            ),
            Positioned(top: 8, right: 8, child: _buildPinButton(vm, item)),
            if (vm.activeCardId == item.id) _buildActionOverlay(vm, item),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    InsightViewModel vm,
    KnowledgeInsightCard item, {
    VoidCallback? onTap,
  }) {
    if (item.widgetType == 'native' && item.widgetTemplate != null) {
      final widget = NativeWidgetFactory.build(
        item.widgetTemplate!,
        item.mergedWidgetData,
      );
      if (widget != null) {
        return GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(absorbing: vm.isReordering, child: widget),
        );
      }
    }
    if (item.widgetType == 'html') {
      if (item.html.isEmpty) {
        if (vm.hasHtmlRenderFailed(item.id)) {
          return SizedBox(
            height: 160,
            child: Center(
              child: TextButton.icon(
                onPressed: () => vm.retryHtmlRendered(item),
                icon: const Icon(Icons.refresh),
                label: Text(UserStorage.l10n.reload),
              ),
            ),
          );
        }
        unawaited(vm.ensureHtmlRendered(item));
        return const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return HtmlWebViewCard(
        html: item.html,
        config: const HtmlWebViewConfig.timeline(),
        onContentTap: onTap,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return LayoutBuilder(
          builder: (context, constraints) {
            final content = Stack(
              children: [
                RefreshIndicator(
                  onRefresh: vm.loadData,
                  child: vm.isReordering
                      ? ReorderableListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 72),
                          onReorder: (oldIndex, newIndex) =>
                              vm.moveItem(oldIndex, newIndex),
                          header: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (!widget.isEmbedded)
                                    Text(
                                      UserStorage.l10n.knowledgeInsight,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  TextButton.icon(
                                    onPressed: () => _saveSortOrder(vm),
                                    icon: const Icon(Icons.check),
                                    label: Text(UserStorage.l10n.completeSort),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                          children: (vm.insights ?? [])
                              .map(
                                (item) => Container(
                                  key: ValueKey(item.id),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Stack(
                                    children: [
                                      _buildItemCard(vm, item),
                                      // Maybe drag handle?
                                      // ReorderableListView provides drag handle by default on long press or handle.
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 72),
                          itemCount: _insightListItemCount(vm),
                          itemBuilder: (context, index) =>
                              _buildInsightListItem(context, vm, index),
                        ),
                ),
              ],
            );

            // Wrap in Scaffold when not embedded
            final wrappedContent = widget.isEmbedded
                ? content
                : Scaffold(
                    backgroundColor: AppColors.background,
                    body: SafeArea(child: content),
                  );

            return wrappedContent;
          },
        );
      },
    );
  }

  /// Preview cards shown when the user has no real insights yet.
  /// Rendered with reduced opacity and a banner hint; non-interactive.
  Widget _buildPreviewCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 24,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            UserStorage.l10n.insightEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            UserStorage.l10n.insightEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
