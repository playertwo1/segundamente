import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memex/domain/models/timeline_card_model.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/ui/search/view_models/global_search_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

/// "Buscar" (reference 16): recent searches, results grouped by type and the
/// empty state. Opening a result is delegated so the screen stays free of
/// routing details.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({
    super.key,
    required this.viewModel,
    required this.onOpenCard,
    required this.onOpenFile,
  });

  final GlobalSearchViewModel viewModel;
  final void Function(TimelineCardModel card) onOpenCard;
  final void Function(String filePath) onOpenFile;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  GlobalSearchViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _vm.submit(value);
  }

  void _clear() {
    _controller.clear();
    _vm.onQueryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return EditorialScaffold(
          title: l10n.globalSearchTitle,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _vm.onQueryChanged,
                  onSubmitted: _vm.submit,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.globalSearchHint,
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textPrimary,
                    ),
                    suffixIcon: _vm.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.globalSearchClearQuery,
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                            ),
                            onPressed: _clear,
                          ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: _border(AppColors.textSecondary),
                    focusedBorder: _border(AppColors.primary),
                  ),
                ),
              ),
              Expanded(child: _content()),
            ],
          ),
        );
      },
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: color),
      );

  Widget _content() {
    final l10n = UserStorage.l10n;
    if (!_vm.hasQuery) return _recents();
    if (_vm.searching && _vm.resultCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vm.noResults) return _empty();

    final q = _vm.query.trim();
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.globalSearchResults,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                l10n.globalSearchCount(_vm.resultCount),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        if (_vm.cards.isNotEmpty) ...[
          _group(Icons.layers_outlined, l10n.globalSearchGroupCards),
          for (final card in _vm.cards) _cardRow(card, q),
        ],
        if (_vm.files.isNotEmpty) ...[
          _group(Icons.menu_book_outlined, l10n.globalSearchGroupKnowledge),
          for (final file in _vm.files) _fileRow(file, q),
        ],
      ],
    );
  }

  Widget _group(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardRow(TimelineCardModel card, String q) {
    final raw = card.rawText?.trim() ?? '';
    final title = (card.title?.trim().isNotEmpty ?? false)
        ? card.title!.trim()
        : raw.split('\n').first;
    final stamp = DateFormat('dd/MM · HH:mm').format(card.timestamp.toLocal());
    return _ResultRow(
      key: ValueKey('search-card-${card.id}'),
      icon: Icons.article_outlined,
      title: title,
      query: q,
      subtitle: stamp,
      onTap: () {
        _vm.remember(q);
        widget.onOpenCard(card);
      },
    );
  }

  Widget _fileRow(Map<String, dynamic> file, String q) {
    final name = file['name'] as String? ?? '';
    final path = file['path'] as String? ?? '';
    return _ResultRow(
      key: ValueKey('search-file-$path'),
      icon: Icons.menu_book_outlined,
      title: name,
      query: q,
      subtitle: file['snippet'] as String?,
      onTap: () {
        _vm.remember(q);
        widget.onOpenFile(path);
      },
    );
  }

  Widget _recents() {
    final l10n = UserStorage.l10n;
    if (_vm.recents.isEmpty) return const SizedBox.shrink();
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            l10n.globalSearchRecent,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        for (final recent in _vm.recents)
          EditorialRow(
            leading: const Icon(Icons.search),
            title: recent,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
            ),
            onTap: () => _setQuery(recent),
          ),
        Center(
          child: TextButton(
            onPressed: _vm.clearRecents,
            style: TextButton.styleFrom(minimumSize: const Size(160, 48)),
            child: Text(
              l10n.globalSearchClearRecent,
              style: const TextStyle(color: AppColors.primary, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    final l10n = UserStorage.l10n;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 56),
        const Icon(Icons.search, size: 72, color: AppColors.textPrimary),
        const SizedBox(height: 24),
        Text(
          l10n.globalSearchNoResults,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.globalSearchNoResultsHint,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        Center(
          child: TextButton(
            onPressed: _clear,
            style: TextButton.styleFrom(minimumSize: const Size(160, 48)),
            child: Text(
              l10n.globalSearchClearQuery,
              style: const TextStyle(color: AppColors.primary, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    super.key,
    required this.icon,
    required this.title,
    required this.query,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String query;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlight(title, query),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  /// Title with the first occurrence of the query in amber (selection only).
  static Widget _highlight(String text, String query) {
    const base = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
    final i = query.isEmpty ? -1 : text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) return Text(text, style: base, maxLines: 2);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + query.length),
            style: const TextStyle(color: AppColors.primary),
          ),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
