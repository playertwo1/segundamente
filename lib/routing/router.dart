// Copyright 2024 The Memex team. All rights reserved.
// Compass-aligned: GoRouter for declarative routing.
// ViewModels are created in route builders and passed to screens.

import 'package:memex/ui/knowledge/widgets/knowledge_file_page.dart';
import 'package:memex/ui/search/view_models/global_search_viewmodel.dart';
import 'package:memex/ui/search/widgets/global_search_screen.dart';
import 'package:memex/ui/agent_activity/view_models/agent_activity_viewmodel.dart';
import 'package:memex/ui/agent_activity/widgets/agent_activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/ui/memory/view_models/memory_viewmodel.dart';
import 'package:memex/ui/memory/widgets/memory_screen.dart';
import 'package:memex/ui/character/widgets/character_config_screen.dart';
import 'package:memex/ui/character/widgets/tavern_import_screen.dart';
import 'package:memex/ui/character/view_models/character_viewmodel.dart';
import 'package:memex/ui/character/view_models/character_edit_viewmodel.dart';
import 'package:memex/ui/character/view_models/persona_chat_viewmodel.dart';
import 'package:memex/ui/character/widgets/persona_chat_screen.dart';
import 'package:memex/ui/calendar/view_models/calendar_viewmodel.dart';
import 'package:memex/ui/calendar/widgets/calendar_screen.dart';
import 'package:memex/ui/tags/view_models/tag_tree_viewmodel.dart';
import 'package:memex/ui/tags/widgets/tag_tree_screen.dart';
import 'package:memex/ui/topics/view_models/topics_viewmodel.dart';
import 'package:memex/ui/topics/widgets/topics_screen.dart';
import 'package:memex/ui/chat/view_models/chat_viewmodel.dart';
import 'package:memex/ui/chat/widgets/chat_history_screen.dart';
import 'package:memex/ui/timeline/widgets/timeline_card_detail_screen.dart';
import 'package:memex/ui/settings/widgets/personal_center_screen.dart';
import 'package:memex/ui/user_setup/widgets/user_setup_screen.dart';
import 'package:memex/routing/routes.dart';
import 'package:memex/domain/models/character_model.dart';

/// Creates the app [GoRouter]. Root content is built by [rootBuilder].
GoRouter createAppRouter(
  GlobalKey<NavigatorState> navigatorKey,
  Widget Function() rootBuilder,
) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => rootBuilder(),
      ),
      GoRoute(
        path: AppRoutes.userSetup,
        builder: (context, state) => UserSetupScreen(
          onUserCreated: () {
            context.go(AppRoutes.home);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => GlobalSearchScreen(
          viewModel: GlobalSearchViewModel(router: context.read<MemexRouter>()),
          onOpenCard: (card) =>
              context.push('${AppRoutes.timelineCardDetail}/${card.id}'),
          onOpenFile: (path) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => KnowledgeFilePage(filePath: path),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.activity,
        builder: (context, state) => AgentActivityScreen(
          viewModel:
              AgentActivityViewModel(router: context.read<MemexRouter>()),
          onBackToTimeline: () => context.go(AppRoutes.home),
        ),
      ),
      GoRoute(
        path: AppRoutes.memory,
        builder: (context, state) {
          final vm = MemoryViewModel(router: context.read<MemexRouter>());
          vm.loadMemory();
          return MemoryScreen(viewModel: vm);
        },
      ),
      GoRoute(
        path: AppRoutes.characterConfig,
        builder: (context, state) {
          final vm = CharacterViewModel(router: context.read<MemexRouter>());
          return CharacterConfigScreen(viewModel: vm);
        },
      ),
      GoRoute(
        path: AppRoutes.characterEdit,
        builder: (context, state) {
          final character = state.extra as CharacterModel?;
          return CharacterEditPage(
            viewModel: CharacterEditViewModel(
              router: context.read<MemexRouter>(),
              character: character,
            ),
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.personaChat}/:characterId',
        builder: (context, state) {
          final characterId = state.pathParameters['characterId'] ?? '';
          return PersonaChatScreen(
            viewModel: PersonaChatViewModel(
              router: context.read<MemexRouter>(),
              initialCharacterId: characterId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tags,
        builder: (context, state) => TagTreeScreen(
          viewModel: TagTreeViewModel(router: context.read<MemexRouter>()),
        ),
      ),
      GoRoute(
        path: AppRoutes.topics,
        builder: (context, state) => TopicsScreen(
          viewModel: TopicsViewModel(router: context.read<MemexRouter>()),
        ),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) {
          final initialDate = state.extra as DateTime? ?? DateTime.now();
          final vm = CalendarViewModel(
            router: context.read<MemexRouter>(),
            initialDate: initialDate,
          );
          vm.fetchMonthData(DateTime(initialDate.year, initialDate.month));
          return CalendarScreen(initialDate: initialDate, viewModel: vm);
        },
      ),
      GoRoute(
        path: AppRoutes.chatHistory,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final agentName = extra['agentName'] as String?;
          final title = extra['title'] as String?;
          final vm = ChatViewModel(
            router: context.read<MemexRouter>(),
            agentName: agentName,
          );
          return ChatHistoryScreen(
            viewModel: vm,
            agentName: agentName,
            title: title,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.timelineCardDetail}/:id',
        builder: (context, state) {
          final cardId = state.pathParameters['id'] ?? '';
          return TimelineCardDetailScreen(cardId: cardId);
        },
      ),
      GoRoute(
        path: AppRoutes.personalCenter,
        builder: (_, __) => const PersonalCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.tavernImport,
        builder: (_, __) => const TavernImportScreen(),
      ),
    ],
  );
}
