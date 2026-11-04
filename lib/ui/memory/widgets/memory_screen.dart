import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/memory/view_models/memory_viewmodel.dart';
import 'package:memex/utils/user_storage.dart';

@visibleForTesting
String formatMemoryListDate(dynamic isoValue) {
  if (isoValue == null) return '';
  try {
    final date = DateTime.parse(isoValue.toString()).toLocal();
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}

/// Memory screen. Receives [viewModel] from parent (Compass-style).
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key, required this.viewModel});

  final MemoryViewModel viewModel;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.viewModel.loadMemory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        return EditorialScaffold(
          title: UserStorage.l10n.memoryTitle,
          body: _buildBody(vm),
        );
      },
    );
  }

  Widget _buildBody(MemoryViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: AgentLogoLoading());
    }

    if (vm.error != null) {
      return Center(
        child: Text(
          UserStorage.l10n.errorLoadingMemory(vm.error!),
          style: const TextStyle(color: AppColors.danger),
        ),
      );
    }

    final archived = vm.memoryData?['archived_memory'] as String? ?? '';
    final buffer = (vm.memoryData?['recent_buffer'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppColors.divider,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: UserStorage.l10n.longTermProfile),
              Tab(text: UserStorage.l10n.recentBuffer),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildArchivedView(archived),
                _buildRecentView(buffer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedView(String content) {
    if (content.isEmpty) {
      return Center(
        child: Text(
          UserStorage.l10n.memoryNoLongTermYet,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
          h2: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
          h3: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary),
          p: const TextStyle(
              fontSize: 15, color: AppColors.textSecondary, height: 1.5),
          listBullet: const TextStyle(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildRecentView(List<Map<String, dynamic>> buffer) {
    if (buffer.isEmpty) {
      return Center(
        child: Text(
          UserStorage.l10n.memoryNoRecentBuffer,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final reversedBuffer = buffer.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: reversedBuffer.length,
      itemBuilder: (context, index) {
        final item = reversedBuffer[index];
        return EditorialRow(
          title: item['subject'] ?? UserStorage.l10n.memoryGeneralSubject,
          subtitle: item['content'] ?? '',
          trailing: Text(
            _formatDate(item['created_at']),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic isoValue) => formatMemoryListDate(isoValue);
}
