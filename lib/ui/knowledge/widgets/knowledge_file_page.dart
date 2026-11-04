import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/domain/models/timeline_card_model.dart';
import 'package:memex/ui/timeline/widgets/timeline_card_detail_screen.dart';
import 'package:memex/ui/core/cards/templates/classic_card.dart';
import 'package:path/path.dart' as path;
import 'package:memex/utils/logger.dart';
import 'package:memex/utils/share_service.dart';
import 'package:memex/utils/toast_helper.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

final _logger = getLogger('KnowledgeFilePage');

class KnowledgeFilePage extends StatefulWidget {
  final String filePath;

  /// Defaults to the app router; tests pass a fake.
  final MemexRouter? router;

  const KnowledgeFilePage({super.key, required this.filePath, this.router});

  @override
  State<KnowledgeFilePage> createState() => _KnowledgeFilePageState();
}

class _KnowledgeFilePageState extends State<KnowledgeFilePage> {
  late final MemexRouter _memexRouter = widget.router ?? MemexRouter();
  String _content = '';
  List<String> _factIds = [];
  List<TimelineCardModel> _sourceCards = [];
  bool _isLoading = true;
  bool _isLoadingCards = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    setState(() => _isLoading = true);
    try {
      // 1. Read file content
      final response = await _memexRouter.readPkmFile(widget.filePath);
      final content = response['content'] as String? ?? '';

      // 2. Parse fact_ids
      final ids = _extractFactIds(content);

      if (mounted) {
        setState(() {
          _content = content;
          _factIds = ids;
          _isLoading = false;
        });
      }

      // 3. Fetch cards if any
      if (ids.isNotEmpty) {
        _fetchSourceCards(ids);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ToastHelper.showError(context, e);
      }
    }
  }

  List<String> _extractFactIds(String content) {
    final regex = RegExp(r'<!--\s*fact_id:\s*(.*?)\s*-->');
    return regex
        .allMatches(content)
        .map((m) => m.group(1)!.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> _fetchSourceCards(List<String> ids) async {
    if (mounted) setState(() => _isLoadingCards = true);
    try {
      final cards = await _memexRouter.fetchCardByIds(ids);
      if (mounted) {
        setState(() {
          _sourceCards = _dedupeSourceCards(cards);
          _isLoadingCards = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCards = false);
      _logger.warning('Error fetching source cards: $e');
    }
  }

  List<TimelineCardModel> _dedupeSourceCards(List<TimelineCardModel> cards) {
    final seen = <String>{};
    return cards.where((card) => seen.add(card.id)).toList();
  }

  int get _uniqueFactIdCount => _factIds.toSet().length;

  Future<void> _downloadFile() async {
    if (_isLoading || _isDownloading) return;

    setState(() => _isDownloading = true);
    try {
      await ShareService.shareTextAsFile(
        context,
        fileName: path.basename(widget.filePath),
        content: _content,
        mimeType: 'text/markdown',
        text: UserStorage.l10n.sharedFromMemex,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to download knowledge file: $e', e, stackTrace);
      if (mounted) {
        ToastHelper.showError(
          context,
          UserStorage.l10n.downloadFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _preprocessMarkdown(String content) {
    // Replace <!-- fact_id: ... --> with a visible link/badge format that we can intercept
    // We use a custom scheme 'fact:' to identify these links
    return content.replaceAllMapped(RegExp(r'<!--\s*fact_id:\s*(.*?)\s*-->'),
        (match) {
      final id = match.group(1);
      return '[source 🔗](fact:$id)';
    });
  }

  /// Title of the reader: the first `# ` heading, else the file name.
  String get _title {
    if (isLegacyGuideName(path.basename(widget.filePath))) {
      return UserStorage.l10n.userGuideTitle;
    }
    final match = RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(_content);
    final heading = match?.group(1)?.trim();
    if (heading != null && heading.isNotEmpty) return heading;
    return path.basenameWithoutExtension(widget.filePath);
  }

  /// Body without the heading already shown as the page title.
  String get _body {
    final match = RegExp(r'^#\s+(.+)\n?', multiLine: true).firstMatch(_content);
    if (match == null) return _content;
    return _content.replaceRange(match.start, match.end, '');
  }

  int get _readingMinutes {
    final words = RegExp(r'\S+').allMatches(_content).length;
    return words <= 0 ? 1 : (words / 200).ceil();
  }

  MarkdownStyleSheet get _markdownStyle {
    const body = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: AppColors.textPrimary,
    );
    return MarkdownStyleSheet(
      p: body,
      listBullet: body,
      h1: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      h2: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      h3: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      a: const TextStyle(color: AppColors.primary),
      blockquote: const TextStyle(
        fontSize: 16,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primary, width: 2)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return EditorialScaffold(
      title:
          _isLoading ? path.basenameWithoutExtension(widget.filePath) : _title,
      subtitle: _isLoading ? null : l10n.knowledgeReaderMeta(_readingMinutes),
      bottom: _isLoading
          ? null
          : TextButton.icon(
              key: const ValueKey('knowledge_file_download_button'),
              onPressed: _isDownloading ? null : _downloadFile,
              style: TextButton.styleFrom(minimumSize: const Size(160, 48)),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.ios_share,
                      color: AppColors.textPrimary,
                    ),
              label: Text(
                l10n.knowledgeReaderShare,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
      body: _isLoading
          ? const Center(child: AgentLogoLoading())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: MarkdownBody(
                      data: _preprocessMarkdown(_body),
                      selectable: true,
                      styleSheet: _markdownStyle,
                      onTapLink: (text, href, title) {
                        if (href != null && href.startsWith('fact:')) {
                          _scrollToCardOrOpen(href.substring(5));
                        }
                      },
                    ),
                  ),
                  if (_factIds.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.link,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.sourceTraceWithCount(_uniqueFactIdCount),
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoadingCards)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sourceCards.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildSourceCard(_sourceCards[index]),
                      ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSourceCard(TimelineCardModel card) {
    // Map TimelineCardModel to ClassicCard data structure
    // Logic adapted from TimelinePage long-press Classic Mode
    final audioAssets = card.assets?.where((a) => a.isAudio).toList() ?? [];

    final classicData = <String, dynamic>{
      'content': card.rawText ?? '',
      'images':
          card.assets?.where((a) => a.isImage).map((a) => a.url).toList() ?? [],
      'audioUrl': audioAssets.isNotEmpty ? audioAssets.first.url : null,
      'tags': [], // Force text-only/clean look without tags for Source Trace
      'status': card.status,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Original Input • Time
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                UserStorage.l10n.originalInput,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.circle, size: 4, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                card.displayTime(UserStorage.l10n),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        // Card Content
        ClassicCard(
          data: classicData,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimelineCardDetailScreen(cardId: card.id),
              ),
            );
          },
        ),
      ],
    );
  }

  void _scrollToCardOrOpen(String id) {
    // If card is already in the list at bottom, maybe highlight it?
    // Or just open detail page directly.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimelineCardDetailScreen(cardId: id),
      ),
    );
  }
}

/// Seeded guide file names (EN and PT) shown under the neutral "Guia de uso".
bool isLegacyGuideName(String name) =>
    const {'memex guide.md', 'guia do memex.md'}.contains(name.toLowerCase());
