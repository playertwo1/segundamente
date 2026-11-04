import 'package:flutter/material.dart';
import 'package:memex/ui/knowledge/view_models/knowledge_base_viewmodel.dart';
import 'package:memex/ui/knowledge/widgets/knowledge/knowledge_file_card.dart';
import 'package:memex/ui/knowledge/widgets/knowledge_search_delegate.dart';
import 'package:memex/utils/user_storage.dart';
import 'knowledge_directory_page.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/core/widgets/memex_brand_title.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'knowledge_file_page.dart';

/// Knowledge base page. Receives [viewModel] from parent (Compass-style).
class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({
    super.key,
    required this.viewModel,
    this.onMenuTap,
  });

  final KnowledgeBaseViewModel viewModel;
  final VoidCallback? onMenuTap;

  @override
  State<KnowledgeBaseScreen> createState() => KnowledgeBaseScreenState();
}

class KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to top and refresh (e.g. pull-to-refresh or double-tap nav)
  void scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    if (mounted) widget.viewModel.fetchData();
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
            leading: widget.onMenuTap == null
                ? null
                : IconButton(
                    onPressed: widget.onMenuTap,
                    tooltip: UserStorage.l10n.navMenu,
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                  ),
            automaticallyImplyLeading: false,
            title: const MemexBrandTitle(),
            backgroundColor: AppColors.background,
            surfaceTintColor: AppColors.background,
            elevation: 0,
            centerTitle: false,
            actions: [
              GestureDetector(
                onTap: () {
                  showSearch(
                    context: context,
                    delegate: KnowledgeSearchDelegate(),
                  );
                },
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.search,
                      color: AppColors.textSecondary, size: 24),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => vm.fetchData(),
            child: vm.isLoading
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: const Center(child: AgentLogoLoading()),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuidesSection(context, vm),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildParaGrid(context, vm),
                        ),
                        if (vm.additionalRootFolders.isNotEmpty ||
                            vm.rootLevelFiles.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildAdditionalRootItems(context, vm),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRecentChangesHeader(),
                              const SizedBox(height: 8),
                              _buildRecentChangesList(vm),
                            ],
                          ),
                        ),
                        const SizedBox(
                            height: 160), // Bottom padding for nav bar
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildGuidesSection(
    BuildContext context,
    KnowledgeBaseViewModel vm,
  ) {
    final guideFolders = vm.additionalRootFolders.where((item) {
      final label = '${item['name'] ?? ''} ${item['path'] ?? ''}'.toLowerCase();
      return label.contains('guia') || label.contains('guide');
    }).toList();
    final guideFiles = _guideFiles(vm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorialSectionLabel(UserStorage.l10n.guides),
        if (guideFolders.isEmpty && guideFiles.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              UserStorage.l10n.noGuidesSaved,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ...guideFolders.map((item) {
          final name = (item['name'] ?? item['path'] ?? '').toString();
          final path = (item['path'] ?? name).toString();
          return EditorialRow(
            title: name,
            leading: const Icon(Icons.folder_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToFolder(context, path: path),
          );
        }),
        ...guideFiles.map((item) {
          final name = (item['name'] ?? item['path'] ?? '').toString();
          final path = (item['path'] ?? name).toString();
          return EditorialRow(
            title: isLegacyGuideName(name)
                ? UserStorage.l10n.userGuideTitle
                : name,
            subtitle: UserStorage.l10n.markdownFileType,
            leading: const Icon(Icons.description_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => KnowledgeFilePage(filePath: path),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// P.A.R.A. as a grouped editorial list (D-017, board 01).
  Widget _buildParaGrid(BuildContext context, KnowledgeBaseViewModel vm) {
    final l10n = UserStorage.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParaRow(
          title: l10n.pkmCategoryProject,
          desc: l10n.pkmCategoryProjectSubtitle,
          count: vm.countItems('Projects'),
          icon: Icons.track_changes_outlined,
          onTap: () => _navigateToFolder(context, path: 'Projects'),
        ),
        _buildParaRow(
          title: l10n.pkmCategoryArea,
          desc: l10n.pkmCategoryAreaSubtitle,
          count: vm.countItems('Areas'),
          icon: Icons.grid_view_outlined,
          onTap: () => _navigateToFolder(context, path: 'Areas'),
        ),
        _buildParaRow(
          title: l10n.pkmCategoryResource,
          desc: l10n.pkmCategoryResourceSubtitle,
          count: vm.countItems('Resources'),
          icon: Icons.layers_outlined,
          onTap: () => _navigateToFolder(context, path: 'Resources'),
        ),
        _buildParaRow(
          title: l10n.pkmCategoryArchive,
          desc: l10n.pkmCategoryArchiveSubtitle,
          count: vm.countItems('Archives'),
          icon: Icons.inbox_outlined,
          onTap: () => _navigateToFolder(context, path: 'Archives'),
        ),
      ],
    );
  }

  Widget _buildParaRow({
    required String title,
    required String desc,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _KnowledgeListRow(
      icon: icon,
      title: title,
      subtitle: desc,
      count: count,
      onTap: onTap,
    );
  }

  Widget _buildAdditionalRootItems(
    BuildContext context,
    KnowledgeBaseViewModel vm,
  ) {
    return Column(
      children: [
        ...vm.additionalRootFolders
            .where((folder) => !_isGuideItem(folder))
            .map((folder) => _buildRootFolderCard(context, folder)),
        ...vm.rootLevelFiles
            .where((file) => !_isGuideItem(file))
            .map((file) => KnowledgeFileCard(item: file)),
      ],
    );
  }

  List<Map<String, dynamic>> _guideFiles(KnowledgeBaseViewModel vm) =>
      [...vm.rootLevelFiles, ...vm.resourcesFiles].where(_isGuideItem).toList();

  bool _isGuideItem(Map<String, dynamic> item) {
    final label = '${item['name'] ?? ''} ${item['path'] ?? ''}'.toLowerCase();
    return label.contains('guia') || label.contains('guide');
  }

  Widget _buildRootFolderCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final name = (item['name'] ?? item['path'] ?? '').toString();
    final path = (item['path'] ?? name).toString();
    final count = item['item_count'] ?? 0;

    return _KnowledgeListRow(
      icon: Icons.folder_outlined,
      title: name,
      count: count is int ? count : int.tryParse('$count') ?? 0,
      onTap: () => _navigateToFolder(context, path: path),
    );
  }

  Widget _buildRecentChangesHeader() {
    return Text(
      UserStorage.l10n.recentChanges.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildRecentChangesList(KnowledgeBaseViewModel vm) {
    // Only files already listed under GUIAS are hidden here.
    final guidePaths = _guideFiles(vm).map((f) => f['path']).toSet();
    final recentFiles =
        vm.recentFiles.where((file) => !guidePaths.contains(file['path']));
    if (recentFiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Text(UserStorage.l10n.noRecentChangesInThreeDays,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      );
    }

    return Column(
      children: recentFiles.map((file) => KnowledgeFileCard(item: file)).toList(),
    );
  }

  void _navigateToFolder(BuildContext context, {required String path}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeDirectoryPage(path: path),
      ),
    );
  }
}

/// One editorial row: outline icon, label, optional subtitle, count, chevron.
class _KnowledgeListRow extends StatelessWidget {
  const _KnowledgeListRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 56,
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
