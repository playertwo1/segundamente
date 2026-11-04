import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memex/data/repositories/get_knowledge_insight_detail.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/insight_detail_model.dart';
import 'package:memex/ui/core/cards/native_card_factory.dart';
import 'package:memex/ui/core/cards/native_widget_factory.dart';
import 'package:memex/ui/chat/widgets/open_super_agent_dialog.dart';
import 'package:memex/ui/chat/widgets/reference_asset_formatter.dart';
import 'package:memex/ui/timeline/widgets/timeline_card_detail_screen.dart';
import 'package:memex/utils/toast_helper.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/utils/share_service.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

/// Unified AI Insight detail page
class InsightDetailPage extends StatefulWidget {
  final String id;
  final Future<InsightDetailModel> Function(String id)? detailLoader;

  const InsightDetailPage({
    super.key,
    required this.id,
    this.detailLoader,
  });

  /// Factory constructor for insight
  factory InsightDetailPage.insight({required String insightId}) {
    return InsightDetailPage(
      id: insightId,
    );
  }

  @override
  State<InsightDetailPage> createState() => _InsightDetailPageState();
}

class _InsightDetailPageState extends State<InsightDetailPage> {
  InsightDetailModel? _insightDetail;
  bool _isLoading = true;
  String? _errorMessage;
  late final MemexRouter _memexRouter;

  @override
  void initState() {
    super.initState();
    _memexRouter = MemexRouter();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detailLoader =
          widget.detailLoader ?? _memexRouter.fetchInsightDetail;
      final detail = await detailLoader(widget.id);
      if (!mounted) return;
      setState(() {
        _insightDetail = detail;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is KnowledgeInsightNotFoundException
          ? UserStorage.l10n.insightUnavailableMessage
          : UserStorage.l10n.loadDetailFailedRetry;
      setState(() {
        _errorMessage = message;
      });
      ToastHelper.showError(context, message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Get metadata
  InsightMetadataModel? get _metadata {
    return _insightDetail?.insight;
  }

  // Get content
  String get _content {
    return _insightDetail?.content ?? '';
  }

  Widget _buildInsightMarkdown(String content, TextStyle style) {
    return MarkdownBody(
      data: content,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: style,
        strong: style.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        em: style.copyWith(fontStyle: FontStyle.italic),
        listBullet: style.copyWith(color: AppColors.textSecondary),
        code: TextStyle(
          fontSize: (style.fontSize ?? 14) - 1,
          color: AppColors.textSecondary,
          backgroundColor: AppColors.background,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Get related cards
  List<RelatedCardModel> get _relatedCards {
    return _insightDetail?.relatedCards ?? [];
  }

  Future<void> _shareInsight() async {
    if (_metadata == null) return;
    ToastHelper.showInfo(context, UserStorage.l10n.processingEllipsis);

    final shareWidget = Container(
      width: 400,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 390, // Standard mobile width to ensure matching layout
            child: _insightDetail?.widgetType == 'native' &&
                    _insightDetail?.widgetTemplate != null
                ? NativeWidgetFactory.build(
                    _insightDetail!.widgetTemplate!,
                    Map<String, dynamic>.from(_insightDetail!.widgetData ?? {})
                      ..addAll({
                        'title': _metadata?.title,
                        'insight': _content,
                        if (_relatedCards.isNotEmpty)
                          'related_fact_ids':
                              _relatedCards.map((c) => c.id).toList(),
                      }),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );

    // Build detail-style widget mirroring the insight detail page layout
    final detailWidget = _buildShareDetailWidget();

    await ShareService.shareWidgetAsPoster(
      context,
      shareWidget,
      detailContent: detailWidget,
    );
  }

  void _showChatDialog() {
    if (_metadata == null || _insightDetail == null) return;

    final metadata = _metadata!;

    openSuperAgentDialog(
      context,
      sceneId: widget.id,
      initialRefs: [
        {
          'title': metadata.title,
          'content': _buildInsightReferenceContent(_insightDetail!),
          'type': 'knowledge_insight_card',
        }
      ],
    );
  }

  String _buildInsightReferenceContent(InsightDetailModel detail) {
    final metadata = detail.insight;
    final buffer = StringBuffer()
      ..writeln('Reference Type: knowledge_insight_card')
      ..writeln(
          'Target Insight ID: ${metadata.id.isNotEmpty ? metadata.id : widget.id}')
      ..writeln('Title: ${metadata.title}')
      ..writeln('Insight Type: ${metadata.type}');

    if (detail.content.isNotEmpty) {
      buffer.writeln('Insight Content:\n${detail.content}');
    }
    if (detail.widgetTemplate != null) {
      buffer.writeln('Widget Template ID: ${detail.widgetTemplate}');
    }
    if (detail.widgetData != null) {
      buffer.writeln('Widget Data: ${detail.widgetData}');
    }
    if (detail.relatedCards.isNotEmpty) {
      buffer.writeln('Related Timeline Cards:');
      for (final card in detail.relatedCards) {
        buffer.writeln(_buildRelatedCardReference(card));
      }
    }

    return buffer.toString();
  }

  String _buildRelatedCardReference(RelatedCardModel card) {
    final buffer = StringBuffer()
      ..writeln('- Card ID: ${card.id}')
      ..writeln('  Title: ${card.title ?? ''}');

    if (card.rawText != null && card.rawText!.isNotEmpty) {
      buffer.writeln('  Record Content: ${card.rawText}');
    }
    if (card.tags.isNotEmpty) {
      buffer.writeln('  Tags: ${card.tags.join(', ')}');
    }
    if (card.assets != null && card.assets!.isNotEmpty) {
      buffer.writeln('  Assets:');
      for (final asset in card.assets!) {
        buffer.writeln(
          '    - ${asset.type}: ${formatAssetReferenceForAgent(asset)}',
        );
      }
    }

    return buffer.toString().trimRight();
  }

  /// Builds a long-form detail widget for the "detail style" share image.
  /// Mirrors the insight detail page layout: native widget card → insight
  /// comment → related cards.
  Widget _buildShareDetailWidget() {
    return Container(
      width: 400,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Native widget card (detail view)
          if (_insightDetail?.widgetType == 'native' &&
              _insightDetail?.widgetTemplate != null &&
              _insightDetail?.widgetData != null) ...[
            NativeWidgetFactory.buildDetail(
                  _insightDetail!.widgetTemplate!,
                  _insightDetail!.widgetData!,
                ) ??
                const SizedBox.shrink(),

            // 2. Insight comment below card (same as detail page)
            if (_content.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _content,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.6,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ] else if (_content.isNotEmpty) ...[
            // Fallback: plain text content
            Text(
              _content,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.7,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 32),
          ],

          // 3. Related cards section (same as detail page)
          if (_relatedCards.isNotEmpty) ...[
            Text(
              UserStorage.l10n.relatedRecordsCount(_relatedCards.length),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._relatedCards.map((card) {
              final displayConfigs = card.uiConfigs;
              if (displayConfigs.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayConfigs.map((config) {
                    if (config.templateId == 'legacy_html') {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: NativeCardFactory.build(
                        status: card.status,
                        templateId: config.templateId,
                        data: config.data,
                        title: card.title ?? '',
                        tags: card.tags,
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    if (_isLoading) {
      return EditorialScaffold(
        title: l10n.aiInsightDetail,
        body: const Center(child: AgentLogoLoading()),
      );
    }

    if (_errorMessage != null || _metadata == null) {
      return EditorialScaffold(
        title: l10n.aiInsightDetail,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 32, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? l10n.loadFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fetchDetail,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(l10n.reload),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _insightDetail!;
    final children = <Widget>[];
    if (detail.widgetType == 'native' &&
        detail.widgetTemplate != null &&
        detail.widgetData != null) {
      children.add(
        NativeWidgetFactory.buildDetail(
              detail.widgetTemplate!,
              detail.widgetData!,
            ) ??
            const SizedBox.shrink(),
      );
      if (_content.isNotEmpty) {
        children.addAll([
          const SizedBox(height: 20),
          _buildInsightMarkdown(
            _content,
            GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ]);
      }
    } else if (_content.isNotEmpty) {
      children.add(
        _buildInsightMarkdown(
          _content,
          GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.55,
          ),
        ),
      );
    }

    if (_relatedCards.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 24),
        EditorialSectionLabel(
          l10n.relatedRecordsCount(_relatedCards.length),
          horizontalPadding: 0,
        ),
        const SizedBox(height: 8),
        ..._relatedCards.map((card) {
          return _RelatedCardItem(
            card: card,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TimelineCardDetailScreen(cardId: card.id),
              ),
            ),
          );
        }),
      ]);
    } else {
      children.addAll([
        const SizedBox(height: 24),
        Text(
          l10n.noRelatedRecords,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ]);
    }

    final metadata = _metadata!;
    return EditorialScaffold(
      title: metadata.title,
      subtitle: l10n.aiInsightDetail,
      actions: [
        IconButton(
          tooltip: l10n.knowledgeReaderShare,
          onPressed: _shareInsight,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.ios_share_outlined),
        ),
        IconButton(
          tooltip: l10n.chatWithSegundaMente,
          onPressed: _showChatDialog,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: children,
      ),
    );
  }
}

class _RelatedCardItem extends StatelessWidget {
  final RelatedCardModel card;
  final VoidCallback onTap;

  const _RelatedCardItem({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Only show native cards
    final displayConfigs = card.uiConfigs;

    if (displayConfigs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayConfigs.map((config) {
          if (config.templateId == 'legacy_html') {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: NativeCardFactory.build(
              status: card.status,
              templateId: config.templateId,
              data: config.data,
              title: card.title ?? '',
              tags: card.tags,
              onTap: onTap,
            ),
          );
        }).toList(),
      ),
    );
  }
}
