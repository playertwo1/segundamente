import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:memex/domain/models/character_model.dart';
import 'package:memex/domain/models/character_message.dart';
import 'package:memex/domain/models/character_emoji.dart';
import 'package:memex/domain/models/persona_chat.dart';
import 'package:memex/ui/character/view_models/persona_chat_viewmodel.dart';
import 'package:memex/ui/core/widgets/character_avatar.dart';
import 'package:memex/ui/core/widgets/local_image.dart';
import 'package:memex/utils/user_storage.dart';

const _personaBackground = Color(0xFF000000);
const _personaPanel = Color(0xFF111113);
const _personaPanelRaised = Color(0xFF1C1C1E);
const _personaPanelSoft = Color(0xFF171719);
const _personaText = Color(0xFFF5F1EA);
const _personaTextSecondary = Color(0xFFA09D98);
const _personaTextQuiet = Color(0xFF797671);
const _personaLine = Color(0xFF29292C);
const _personaLineStrong = Color(0xFF3A3A3F);
const _personaAccent = Color(0xFFFF8A3D);
const _personaAccentSoft = Color(0xFF27170D);
const _personaOnAccent = Color(0xFF1B1008);

final _cachedMarkdownStyle = MarkdownStyleSheet(
  p: const TextStyle(
    fontSize: 14,
    height: 1.5,
    color: _personaText,
  ),
  strong: const TextStyle(
    fontWeight: FontWeight.w700,
    color: _personaText,
  ),
  em: const TextStyle(fontStyle: FontStyle.italic),
  listBullet: const TextStyle(color: _personaAccent),
  code: const TextStyle(
    fontSize: 13,
    color: _personaText,
    backgroundColor: _personaPanelSoft,
    fontFamily: 'monospace',
  ),
  codeblockDecoration: BoxDecoration(
    color: _personaPanelSoft,
    borderRadius: BorderRadius.circular(8),
  ),
);

/// 1-on-1 chat screen with an AI companion character.
class PersonaChatScreen extends StatefulWidget {
  final PersonaChatViewModel viewModel;
  const PersonaChatScreen({super.key, required this.viewModel});

  @override
  State<PersonaChatScreen> createState() => _PersonaChatScreenState();
}

class _PersonaChatScreenState extends State<PersonaChatScreen> {
  final _textController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();
  String? _lastObservedCharacterId;
  int? _lastNewestMessageId;
  String? _lastPresentedError;

  PersonaChatViewModel get _viewModel => widget.viewModel;
  String get _currentCharacterId => _viewModel.currentCharacterId;
  CharacterModel? get _character => _viewModel.character;
  List<PersonaChatMessageModel> get _messages => _viewModel.messages;
  bool get _isLoading => _viewModel.isLoading;
  bool get _isReplying => _viewModel.isReplying;
  bool get _hasMoreHistory => _viewModel.hasMoreHistory;
  bool get _isLoadingMore => _viewModel.isLoadingMore;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    unawaited(_viewModel.init());
    _scrollController.addListener(_onScroll);
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final newestMessageId = _messages.firstOrNull?.id;
    final shouldScroll = shouldAutoScrollPersonaChat(
      previousCharacterId: _lastObservedCharacterId,
      currentCharacterId: _currentCharacterId,
      previousNewestMessageId: _lastNewestMessageId,
      currentNewestMessageId: newestMessageId,
    );
    _lastObservedCharacterId = _currentCharacterId;
    _lastNewestMessageId = newestMessageId;
    if (shouldScroll) {
      _scrollToBottom();
    }
    final error = _viewModel.errorMessage;
    if (error != null && error != _lastPresentedError) {
      _lastPresentedError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      });
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggered when user scrolls toward the top (older messages).
  /// Since the list is reversed, maxScrollExtent = oldest direction.
  void _onScroll() {
    if (!_hasMoreHistory || _isLoadingMore) return;
    final pos = _scrollController.position;
    // Trigger load when within 20% of the top (maxScrollExtent in reversed list)
    if (pos.pixels >= pos.maxScrollExtent * 0.8) {
      _loadMoreHistory();
    }
  }

  /// Loads the next page of older messages and prepends them to the list.
  Future<void> _loadMoreHistory() async {
    await _viewModel.loadMoreHistory();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final sent = await _viewModel.sendMessage(text);
    if (!sent && mounted && _textController.text.isEmpty) {
      _textController.text = text;
      _textController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  void _closeChat() {
    _inputFocusNode.unfocus();
    Navigator.pop(context);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      await markPersonaChatReadAfterOpen(
        hasScrollClients: _scrollController.hasClients,
        scrollToLatest: () => _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        ),
        markRead: () async {
          if (mounted) {
            await _viewModel.markVisibleMessagesRead();
          }
        },
      );
    });
  }

  Future<void> _switchCharacter() async {
    final enabled = await _viewModel.loadEnabledCharacters();
    if (enabled.length <= 1 || !mounted) return;

    final selected = await _CharacterSwitcherSheet.show(
      context,
      characters: enabled,
      currentId: _currentCharacterId,
    );

    if (selected != null && selected.id != _currentCharacterId && mounted) {
      await _viewModel.switchCharacter(selected.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _inputFocusNode.unfocus();
      },
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: _personaBackground,
            body: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _personaAccent),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: _ChatBackground(character: _character),
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).padding.top),
                          _buildHeader(),
                          Expanded(
                            child: PersonaChatKeyboardDismissRegion(
                              focusNode: _inputFocusNode,
                              child: _buildMessageList(),
                            ),
                          ),
                          _buildInputBar(),
                        ],
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final character = _character;
    final l10n = UserStorage.l10n;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _personaBackground,
        border: Border(bottom: BorderSide(color: _personaLine)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.sendBack,
            onPressed: _closeChat,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _personaText,
              size: 17,
            ),
          ),
          if (character != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Tooltip(
                message: l10n.switchCompanion,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _switchCharacter,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CharacterAvatar(
                            avatar: character.avatar,
                            name: character.name,
                            size: 42,
                            backgroundColor: _personaPanelSoft,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  character.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    height: 20 / 17,
                                    fontWeight: FontWeight.w600,
                                    color: _personaText,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (character.tags.isNotEmpty)
                                  Text(
                                    character.tags.take(3).join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 17 / 13,
                                      color: _personaTextSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 19,
                            color: _personaTextSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final showTypingIndicator = _isReplying;
    final extraItems = showTypingIndicator ? 1 : 0;
    // Extra item at the tail (top of reversed list) for load-more indicator
    final loadMoreItem = (_hasMoreHistory || _isLoadingMore) ? 1 : 0;
    final itemCount = _messages.length + extraItems + loadMoreItem;

    if (_messages.isEmpty && extraItems == 0) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Typing indicator at the bottom (index 0 in reversed list).
        if (extraItems == 1 && index == 0) {
          return _buildTypingIndicator();
        }

        // Load-more indicator at the top (last index in reversed list)
        if (loadMoreItem == 1 && index == itemCount - 1) {
          return _buildLoadMoreIndicator();
        }

        final messageIndex = _messageIndexForListIndex(
          listIndex: index,
          extraItems: extraItems,
        );
        final msg = _messages[messageIndex];
        final showDate = _shouldShowDateDivider(
          messageIndex,
          _messages,
        );
        final olderMessage = messageIndex + 1 < _messages.length
            ? _messages[messageIndex + 1]
            : null;
        final showCharacterAvatar =
            msg.isFromCharacter && olderMessage?.isFromCharacter != true;

        return Column(
          children: [
            if (showDate) _buildDateDivider(msg.timestamp),
            if (msg.messageType == PersonaChatMessageTypes.emoji)
              _buildEmojiMessage(
                emoji: msg.content,
                isCharacter: msg.isFromCharacter,
              )
            else if (msg.messageType == PersonaChatMessageTypes.action)
              _buildActionMessage(text: msg.content)
            else
              _buildBubble(
                text: msg.content,
                isCharacter: msg.isFromCharacter,
                time: DateFormat('HH:mm', UserStorage.l10n.localeName)
                    .format(msg.timestamp),
                showCharacterAvatar: showCharacterAvatar,
              ),
          ],
        );
      },
    );
  }

  int _messageIndexForListIndex({
    required int listIndex,
    required int extraItems,
  }) {
    return personaChatMessageIndexForReversedList(
      listIndex: listIndex,
      extraItems: extraItems,
    );
  }

  bool _shouldShowDateDivider(
    int messageIndex,
    List<PersonaChatMessageModel> messages,
  ) {
    // Always show timestamp for the oldest loaded message
    if (messageIndex == messages.length - 1) return true;
    // Show timestamp when gap between adjacent messages exceeds 10 minutes
    // (WeChat/WhatsApp convention)
    final current = messages[messageIndex].timestamp;
    final previous = messages[messageIndex + 1].timestamp;
    return current.difference(previous).inMinutes.abs() >= 10;
  }

  Widget _buildEmptyState() {
    return PersonaChatEmptyState(character: _character);
  }

  Widget _buildDateDivider(DateTime date) {
    final label = _formatTimeDivider(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _personaPanelSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _personaLine),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _personaTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Formats a timestamp for the chat time divider, following WeChat conventions:
  /// - Today: "HH:mm"
  /// - Yesterday: "昨天 HH:mm" / "Yesterday HH:mm"
  /// - This week (within 7 days): "周三 HH:mm" / "Wed HH:mm"
  /// - This year: "3月15日 HH:mm" / "Mar 15 HH:mm"
  /// - Older: "2024年3月15日 HH:mm" / "Mar 15, 2024 HH:mm"
  String _formatTimeDivider(DateTime date) {
    final now = DateTime.now();
    final locale = UserStorage.l10n.localeName;
    final time = DateFormat('HH:mm', locale).format(date);

    if (_isSameDay(date, now)) {
      return time;
    }

    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return '${UserStorage.l10n.yesterday} $time';
    }

    final daysAgo = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;

    if (daysAgo < 7) {
      final weekday = DateFormat.E(locale).format(date);
      return '$weekday $time';
    }

    if (date.year == now.year) {
      return '${DateFormat.MMMd(locale).format(date)} $time';
    }

    return '${DateFormat.yMMMd(locale).format(date)} $time';
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: _personaAccent,
            ),
          ),
        ),
      );
    }
    // Invisible sentinel — the scroll listener handles triggering the load.
    return const SizedBox(height: 1);
  }

  /// Renders a narrative / action description message.
  /// No speech bubble — italic text centred with a subtle divider style,
  /// matching the roleplay convention for stage directions.
  Widget _buildActionMessage({required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: _personaLine,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: _personaTextSecondary,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 0.5,
              color: _personaLine,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiMessage({
    required String emoji,
    required bool isCharacter,
  }) {
    final glyph = PersonaChatEmojiGlyph(emoji: emoji);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCharacter) ...[
            _FramedCharacterAvatar(
              avatar: _character?.avatar,
              name: _character?.name ?? '',
              size: 27,
            ),
            const SizedBox(width: 8),
          ] else
            const Spacer(),
          Flexible(child: glyph),
          if (isCharacter) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isCharacter,
    required String time,
    required bool showCharacterAvatar,
  }) {
    return PersonaChatMessageBubble(
      text: text,
      isCharacter: isCharacter,
      time: time,
      characterAvatar: _character?.avatar,
      characterName: _character?.name ?? '',
      showCharacterAvatar: showCharacterAvatar,
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        label: UserStorage.l10n.personaChatThinking,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FramedCharacterAvatar(
              avatar: _character?.avatar,
              name: _character?.name ?? '',
              size: 27,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: _personaPanelRaised,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ExcludeSemantics(child: _TypingDots()),
                  const SizedBox(width: 10),
                  Text(
                    UserStorage.l10n.personaChatThinking,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _personaTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return PersonaChatInputBar(
      controller: _textController,
      focusNode: _inputFocusNode,
      onSend: _sendMessage,
      hintText: UserStorage.l10n.personaChatInputHint,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

@visibleForTesting
class PersonaChatEmptyState extends StatelessWidget {
  const PersonaChatEmptyState({super.key, required this.character});

  final CharacterModel? character;

  @override
  Widget build(BuildContext context) {
    final greeting = character?.firstMessage?.trim();
    final tags = character?.tags
        .where((tag) => tag.trim().isNotEmpty)
        .take(3)
        .join(' · ');

    return ColoredBox(
      color: _personaBackground,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (character != null)
                    CharacterAvatar(
                      avatar: character!.avatar,
                      name: character!.name,
                      size: 120,
                      backgroundColor: _personaPanel,
                    ),
                  if (tags?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 24),
                    Text(
                      tags!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 15 / 11,
                        color: _personaTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    UserStorage.l10n.personaChatWelcomeTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      height: 32 / 27,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      color: _personaText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _personaAccentSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _personaLineStrong),
                      ),
                      child: Text(
                        greeting?.isNotEmpty == true
                            ? greeting!
                            : UserStorage.l10n.personaChatWelcomeHint,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _personaTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class PersonaChatMessageBubble extends StatelessWidget {
  const PersonaChatMessageBubble({
    super.key,
    required this.text,
    required this.isCharacter,
    required this.time,
    required this.characterAvatar,
    required this.characterName,
    required this.showCharacterAvatar,
  });

  final String text;
  final bool isCharacter;
  final String time;
  final String? characterAvatar;
  final String characterName;
  final bool showCharacterAvatar;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.76;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isCharacter
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCharacterAvatar)
                  _FramedCharacterAvatar(
                    avatar: characterAvatar,
                    name: characterName,
                    size: 27,
                  )
                else
                  const SizedBox(width: 27, height: 27),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: _CharacterMessageFrame(
                          child: MarkdownBody(
                            data: text,
                            selectable: true,
                            softLineBreak: true,
                            styleSheet: _cachedMarkdownStyle,
                          ),
                        ),
                      ),
                      _MessageTime(time: time, alignment: Alignment.centerLeft),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: _personaAccent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(5),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                          ),
                          child: SelectableText(
                            text,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: _personaOnAccent,
                            ),
                          ),
                        ),
                        _MessageTime(
                          time: time,
                          alignment: Alignment.centerRight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MessageTime extends StatelessWidget {
  const _MessageTime({required this.time, required this.alignment});

  final String time;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Align(
        alignment: alignment,
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 9,
            height: 13 / 9,
            color: _personaTextQuiet,
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
class PersonaChatKeyboardDismissRegion extends StatelessWidget {
  const PersonaChatKeyboardDismissRegion({
    super.key,
    required this.focusNode,
    required this.child,
  });

  final FocusNode focusNode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: focusNode.unfocus,
      child: child,
    );
  }
}

@visibleForTesting
class PersonaChatEmojiGlyph extends StatelessWidget {
  const PersonaChatEmojiGlyph({super.key, required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final fluentEmoji = CharacterEmoji.fromGlyph(emoji);
    return Semantics(
      label: 'Emoji message: $emoji',
      image: fluentEmoji != null,
      child: ExcludeSemantics(
        child: fluentEmoji == null
            ? Text(
                emoji,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.15,
                  letterSpacing: 0,
                ),
              )
            : Image.asset(
                'assets/fluent_emoji/${fluentEmoji.assetFileName}',
                width: 36,
                height: 36,
                filterQuality: FilterQuality.high,
              ),
      ),
    );
  }
}

@visibleForTesting
int personaChatMessageIndexForReversedList({
  required int listIndex,
  required int extraItems,
}) {
  return listIndex - extraItems;
}

@visibleForTesting
bool shouldAutoScrollPersonaChat({
  required String? previousCharacterId,
  required String currentCharacterId,
  required int? previousNewestMessageId,
  required int? currentNewestMessageId,
}) {
  return previousCharacterId != currentCharacterId ||
      previousNewestMessageId != currentNewestMessageId;
}

@visibleForTesting
Future<void> markPersonaChatReadAfterOpen({
  required bool hasScrollClients,
  required Future<void> Function() scrollToLatest,
  required Future<void> Function() markRead,
}) async {
  if (hasScrollClients) {
    await scrollToLatest();
  }
  await markRead();
}

class _ChatBackground extends StatelessWidget {
  const _ChatBackground({required this.character});

  final CharacterModel? character;

  @override
  Widget build(BuildContext context) {
    final bgPath = character?.chatBackground;
    final hasCustomBg =
        bgPath != null && bgPath.isNotEmpty && File(bgPath).existsSync();
    if (!hasCustomBg) return const ColoredBox(color: _personaBackground);

    return Stack(
      children: [
        Positioned.fill(child: LocalImage(url: bgPath, fit: BoxFit.cover)),
        const Positioned.fill(
          child: ColoredBox(color: Color(0xC6000000)),
        ),
      ],
    );
  }
}

class _CharacterMessageFrame extends StatelessWidget {
  const _CharacterMessageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.76,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: _personaPanelRaised,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: child,
    );
  }
}

class _FramedCharacterAvatar extends StatelessWidget {
  const _FramedCharacterAvatar({
    required this.avatar,
    required this.name,
    required this.size,
  });

  final String? avatar;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _personaBackground,
        border: Border.all(color: _personaLine),
      ),
      child: CharacterAvatar(
        avatar: avatar,
        name: name,
        size: size - 2,
        backgroundColor: _personaPanelSoft,
      ),
    );
  }
}

@visibleForTesting
class PersonaChatInputBar extends StatelessWidget {
  const PersonaChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final String hintText;

  bool _canSend(String value) => value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 10, 14, bottomPadding + 12),
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          final focused = focusNode.hasFocus;
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: _personaPanel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: focused ? _personaAccent : _personaLine,
                width: focused ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    cursorColor: _personaAccent,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: _personaTextQuiet,
                        fontSize: 13,
                        height: 19 / 13,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 19 / 13,
                      color: _personaText,
                    ),
                    textInputAction: TextInputAction.send,
                    onEditingComplete: () {},
                    onSubmitted: (_) {
                      if (_canSend(controller.text)) onSend();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final canSend = _canSend(value.text);
                    return _SendButton(
                      enabled: canSend,
                      onTap: onSend,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: UserStorage.l10n.sendLabel,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: SizedBox.square(
          dimension: 44,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? _personaAccent : _personaPanelRaised,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: enabled ? _personaOnAccent : _personaTextQuiet,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated three-dot typing indicator.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _personaAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.2
            final delay = i * 0.2;
            final t = (_controller.value - delay) % 1.0;
            // Bounce: peak at 0.3, back to 0 at 0.6
            final offset = t < 0.3
                ? -4.0 * (t / 0.3)
                : t < 0.6
                    ? -4.0 * (1 - (t - 0.3) / 0.3)
                    : 0.0;
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _personaAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Bottom sheet for switching companion characters.
class _CharacterSwitcherSheet extends StatelessWidget {
  final List<CharacterModel> characters;
  final String? currentId;

  const _CharacterSwitcherSheet({
    required this.characters,
    this.currentId,
  });

  static Future<CharacterModel?> show(
    BuildContext context, {
    required List<CharacterModel> characters,
    String? currentId,
  }) {
    return showModalBottomSheet<CharacterModel>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CharacterSwitcherSheet(
        characters: characters,
        currentId: currentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: _personaPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: _personaLineStrong),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _personaTextQuiet,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.switchCompanion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _personaText,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  final char = characters[index];
                  final isCurrent = char.id == currentId;
                  return ListTile(
                    leading: CharacterAvatar(
                      avatar: char.avatar,
                      name: char.name,
                      size: 40,
                      backgroundColor: _personaPanelSoft,
                    ),
                    title: Text(
                      char.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                        color: _personaText,
                      ),
                    ),
                    subtitle: char.tags.isNotEmpty
                        ? Text(
                            char.tags.join(' · '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _personaTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle,
                            color: _personaAccent, size: 20)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: isCurrent
                        ? () => Navigator.pop(context)
                        : () => Navigator.pop(context, char),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
