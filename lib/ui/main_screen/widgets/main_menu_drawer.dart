import 'package:flutter/material.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/memex_brand_title.dart';
import 'package:memex/utils/user_storage.dart';

/// Main destinations, opened from the header menu. Replaces the persistent
/// bottom bar (D-017): short list, literal names, icon always with a label.
class MainMenuDrawer extends StatelessWidget {
  const MainMenuDrawer({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.onOpenChat,
    required this.onOpenChatHistory,
    required this.onOpenCalendar,
    required this.onOpenMemory,
    required this.onOpenActivity,
    required this.onOpenProfile,
  });

  final int currentTab;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenChatHistory;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenMemory;
  final VoidCallback onOpenActivity;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    // Close the drawer before acting, so pushed routes and sheets sit on top.
    VoidCallback close(VoidCallback action) => () {
          Navigator.of(context).pop();
          action();
        };

    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: MemexBrandTitle(),
              ),
            ),
            _MenuItem(
              icon: Icons.home_outlined,
              label: l10n.navTimeline,
              selected: currentTab == 0,
              onTap: close(() => onSelectTab(0)),
            ),
            _MenuItem(
              icon: Icons.folder_open_outlined,
              label: l10n.navKnowledge,
              selected: currentTab == 1,
              onTap: close(() => onSelectTab(1)),
            ),
            _MenuItem(
              icon: Icons.calendar_today_outlined,
              label: l10n.calendar,
              onTap: close(onOpenCalendar),
            ),
            _MenuItem(
              icon: Icons.bookmark_border,
              label: l10n.memoryTitle,
              onTap: close(onOpenMemory),
            ),
            _MenuItem(
              icon: Icons.sync_outlined,
              label: l10n.activityMenu,
              onTap: close(onOpenActivity),
            ),
            _MenuItem(
              icon: Icons.chat_bubble_outline,
              label: l10n.navChat,
              onTap: close(onOpenChat),
            ),
            _MenuItem(
              icon: Icons.history,
              label: l10n.chatHistory,
              onTap: close(onOpenChatHistory),
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: l10n.navProfile,
              onTap: close(onOpenProfile),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textPrimary;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minTileHeight: 56,
        selected: selected,
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            color: color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
