import 'package:flutter/material.dart';
import 'package:memex/domain/models/llm_config.dart';
import 'package:memex/data/repositories/memex_router.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:memex/ui/core/widgets/agent_logo_loading.dart';
import 'package:memex/ui/settings/widgets/agent_config_list_page.dart';
import 'package:memex/ui/settings/widgets/bottom_primary_action_bar.dart';
import 'model_config_edit_page.dart';
import 'package:memex/ui/core/themes/app_colors.dart';

import 'package:memex/domain/models/agent_definitions.dart';

class ModelConfigListPage extends StatefulWidget {
  const ModelConfigListPage({
    super.key,
    this.popOnConfigSaved = false,
    this.autoOpenFirstConfig = false,
    this.simpleSetupMode = false,
  });

  final bool popOnConfigSaved;
  final bool autoOpenFirstConfig;
  final bool simpleSetupMode;

  @override
  State<ModelConfigListPage> createState() => _ModelConfigListPageState();
}

class _ModelConfigListPageState extends State<ModelConfigListPage> {
  List<LLMConfig> _configs = [];
  String _defaultConfigKey = LLMConfig.defaultClientKey;
  bool _isLoading = true;
  bool _didAutoOpenFirstConfig = false;
  bool _isFallbackEnabled = true;
  List<String> _fallbackOrder = [];

  String _providerDisplayName(String type) {
    final l10n = UserStorage.l10n;
    switch (type) {
      case LLMConfig.typeChatCompletion:
        return l10n.providerOpenAiApiKey;
      case LLMConfig.typeResponses:
        return l10n.providerOpenAiResponses;
      case LLMConfig.typeOpenAiOauth:
        return l10n.providerChatGptOauth;
      case LLMConfig.typeClaude:
        return l10n.providerClaudeApiKey;
      case LLMConfig.typeClaudeOauth:
        return 'Anthropic Claude (OAuth)';
      case LLMConfig.typeBedrockClaude:
        return l10n.providerBedrockSecret;
      case LLMConfig.typeGemini:
        return l10n.providerGemini;
      case LLMConfig.typeGeminiOauth:
        return l10n.providerGeminiOauth;
      case LLMConfig.typeKimi:
        return l10n.providerKimi;
      case LLMConfig.typeQwen:
        return l10n.providerQwen;
      case LLMConfig.typeSeed:
        return l10n.providerSeed;
      case LLMConfig.typeZhipu:
        return l10n.providerZhipu;
      case LLMConfig.typeDeepSeek:
        return l10n.providerDeepSeek;
      case LLMConfig.typeMinimax:
        return l10n.providerMinimax;
      case LLMConfig.typeOpenRouter:
        return l10n.providerOpenRouter;
      case LLMConfig.typeOllama:
        return l10n.providerOllama;
      case LLMConfig.typeMemex:
        return l10n.providerMemex;
      default:
        return type;
    }
  }

  String get _visionBadgeText => UserStorage.l10n.visionBadge;

  bool _isKnownMultimodalConfig(LLMConfig config) =>
      LLMConfig.isKnownMultimodal(config.type, config.modelId);

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    final router = MemexRouter();
    final configs = await router.getLLMConfigs();
    final defaultConfigKey = await router.getDefaultLLMConfigKey();
    final isFallbackEnabled = await router.isFallbackEnabled();
    final fallbackOrder = await router.getFallbackOrder();
    if (!mounted) return;
    setState(() {
      _configs = configs;
      _defaultConfigKey = defaultConfigKey;
      _isFallbackEnabled = isFallbackEnabled;
      _fallbackOrder = fallbackOrder;
      _isLoading = false;
    });
    _maybeAutoOpenFirstConfig();
  }

  bool get _shouldAutoOpenFirstConfig {
    if (!widget.autoOpenFirstConfig || _didAutoOpenFirstConfig) return false;
    return _autoOpenConfig != null ||
        !_configs.any((config) => config.type != LLMConfig.typeMemex);
  }

  LLMConfig? get _autoOpenConfig {
    final manualConfigs =
        _configs.where((c) => c.type != LLMConfig.typeMemex).toList();
    final validManualConfigs =
        manualConfigs.where((config) => config.isValid).toList();
    if (validManualConfigs.length == 1) {
      return validManualConfigs.single;
    }
    if (validManualConfigs.isEmpty && manualConfigs.length == 1) {
      return manualConfigs.first;
    }
    return null;
  }

  void _maybeAutoOpenFirstConfig() {
    if (!_shouldAutoOpenFirstConfig) return;
    _didAutoOpenFirstConfig = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editConfig(_autoOpenConfig);
    });
  }

  Future<List<String>> _getAgentsUsingConfig(String configKey) async {
    final usedByagents = <String>[];
    for (var agentId in AgentDefinitions.configurableAgentIds) {
      final config = await MemexRouter().getAgentConfig(agentId);
      if (config.llmConfigKey == configKey) {
        usedByagents.add(AgentDefinitions.displayNames[agentId] ?? agentId);
      }
    }
    return usedByagents;
  }

  bool _isDefaultConfig(LLMConfig config) => config.key == _defaultConfigKey;

  Future<bool> _confirmDeleteConfig(LLMConfig config) async {
    final l10n = UserStorage.l10n;
    if (_isDefaultConfig(config) || config.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotDeleteDefaultConfiguration)),
      );
      return false;
    }

    final usingAgents = await _getAgentsUsingConfig(config.key);
    if (usingAgents.isNotEmpty) {
      if (!mounted) return false;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(l10n.cannotDeleteConfigurationTitle),
          content: Text(l10n.configUsedByAgentsMessage(usingAgents.join('\n'))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return false;
    }

    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(l10n.deleteConfigurationTitle),
            content: Text(l10n.confirmDeleteConfigMessage(config.key)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteConfig(LLMConfig config) async {
    if (await _confirmDeleteConfig(config)) {
      setState(() {
        _configs.removeWhere((item) => item.key == config.key);
      });
      await MemexRouter().saveLLMConfigs(_configs);
    }
  }

  Future<void> _setDefaultConfig(LLMConfig config) async {
    final l10n = UserStorage.l10n;
    try {
      await MemexRouter().setDefaultLLMConfigKey(config.key);
      await _loadConfigs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.modelSetAsDefault(config.modelId))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveConfigFailed(e.toString()))),
      );
    }
  }

  void _editConfig(LLMConfig? config, {LLMConfig? duplicateSource}) async {
    final savedConfigKey = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ModelConfigEditPage(
          config: config,
          duplicateSource: duplicateSource,
          isDefaultConfig: config != null && _isDefaultConfig(config),
          simpleSetupMode: widget.simpleSetupMode,
        ),
      ),
    );

    if (savedConfigKey != null) {
      if (widget.popOnConfigSaved) {
        if (mounted) {
          Navigator.pop(context, savedConfigKey);
        }
        return;
      }
      _loadConfigs();
    }
  }

  void _duplicateConfig(LLMConfig config) {
    final duplicated = config.duplicate(
      existingKeys: _configs.map((c) => c.key).toList(),
    );
    _editConfig(null, duplicateSource: duplicated);
  }

  String _buildFallbackChainSubtitle() {
    final validConfigs = _configs.where((c) => c.isValid).toList();
    if (validConfigs.isEmpty) return 'Nenhum provedor configurado';
    if (_fallbackOrder.isNotEmpty) {
      validConfigs.sort((a, b) {
        final iA = _fallbackOrder.indexOf(a.key);
        final iB = _fallbackOrder.indexOf(b.key);
        if (iA != -1 && iB != -1) return iA.compareTo(iB);
        if (iA != -1) return -1;
        if (iB != -1) return 1;
        return 0;
      });
    }
    return validConfigs
        .map((c) => LLMConfig.displayName(c.type))
        .take(4)
        .join(' ➔ ');
  }

  void _openFallbackOrderSheet() {
    final validConfigs = _configs.where((c) => c.isValid).toList();
    if (_fallbackOrder.isNotEmpty) {
      validConfigs.sort((a, b) {
        final iA = _fallbackOrder.indexOf(a.key);
        final iB = _fallbackOrder.indexOf(b.key);
        if (iA != -1 && iB != -1) return iA.compareTo(iB);
        if (iA != -1) return -1;
        if (iB != -1) return 1;
        return 0;
      });
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prioridade de Fallback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Arraste para definir a ordem em que os modelos serão tentados em caso de falha.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      onReorder: (oldIndex, newIndex) async {
                        setSheetState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = validConfigs.removeAt(oldIndex);
                          validConfigs.insert(newIndex, item);
                        });
                        final newOrder =
                            validConfigs.map((c) => c.key).toList();
                        await MemexRouter().setFallbackOrder(newOrder);
                        setState(() => _fallbackOrder = newOrder);
                      },
                      children: [
                        for (int i = 0; i < validConfigs.length; i++)
                          ListTile(
                            key: ValueKey(validConfigs[i].key),
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              LLMConfig.displayName(validConfigs[i].type),
                            ),
                            subtitle: Text(validConfigs[i].modelId),
                            trailing: const Icon(Icons.drag_handle),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAdvancedAgentConfig() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const AgentConfigListPage()),
    );
  }

  Widget _buildAdvancedAgentSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      child: Card(
        elevation: 0,
        color: AppColors.background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: Theme(
          key: const ValueKey('advanced-agent-model-settings-theme'),
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('advanced-agent-model-settings'),
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(
              side: BorderSide.none,
            ),
            leading: const Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
            ),
            title: Text(
              UserStorage.l10n.advancedSettings,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(
                  UserStorage.l10n.aiSetupAdvancedCustomizationDescription,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                key: const ValueKey('agent-model-assignments-action'),
                leading: const Icon(Icons.people_outline),
                title: Text(UserStorage.l10n.advancedAgentModelAssignments),
                subtitle: Text(
                  UserStorage.l10n.openAdvancedAgentModelAssignments,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _openAdvancedAgentConfig,
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const ValueKey('model-fallback-toggle'),
                secondary: const Icon(Icons.alt_route_rounded),
                title: const Text('Fallback automático'),
                subtitle: const Text(
                  'Se o provedor atual falhar (rate limit, offline, erro), tenta os outros automaticamente.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _isFallbackEnabled,
                onChanged: (val) async {
                  await MemexRouter().setFallbackEnabled(val);
                  setState(() => _isFallbackEnabled = val);
                },
              ),
              if (_isFallbackEnabled && _configs.length > 1) ...[
                ListTile(
                  key: const ValueKey('model-fallback-order-action'),
                  leading: const Icon(Icons.low_priority_rounded),
                  title: const Text('Ordem de prioridade do fallback'),
                  subtitle: Text(
                    _buildFallbackChainSubtitle(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _openFallbackOrderSheet,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(UserStorage.l10n.modelConfiguration),
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_page),
            tooltip: UserStorage.l10n.resetToDefaults,
            onPressed: () async {
              final l10n = UserStorage.l10n;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.cardBackground,
                  title: Text(l10n.resetAllConfigurationsTitle),
                  content: Text(l10n.resetAllModelConfigurationsMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        l10n.resetButton,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                setState(() => _isLoading = true);
                try {
                  await MemexRouter().resetLLMConfigs();
                  await _loadConfigs();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          UserStorage.l10n.modelConfigurationsReset,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          UserStorage.l10n.resetFailed(e.toString()),
                        ),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AgentLogoLoading())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _configs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _configs.length) {
                        return _buildAdvancedAgentSettings();
                      }
                      final config = _configs[index];
                      final isDefaultConfig = _isDefaultConfig(config);
                      final canDelete = !isDefaultConfig && !config.isDefault;

                      return Dismissible(
                        key: Key(config.key),
                        direction: canDelete
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return _confirmDeleteConfig(config);
                        },
                        onDismissed: (direction) async {
                          setState(() {
                            _configs.removeWhere(
                              (item) => item.key == config.key,
                            );
                          });
                          await MemexRouter().saveLLMConfigs(_configs);
                        },
                        child: ListTile(
                          title: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Text(
                                  config.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (isDefaultConfig)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    UserStorage.l10n.defaultLabel,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              if (_isKnownMultimodalConfig(config))
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _visionBadgeText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  '${_providerDisplayName(config.type)} / ${config.modelId}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    config.isValid
                                        ? Icons.check_circle_outline
                                        : Icons.warning_amber_rounded,
                                    size: 14,
                                    color: config.isValid
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      config.isValid
                                          ? UserStorage.l10n.configured
                                          : UserStorage.l10n.apiKeyNotSet,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: config.isValid
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).moreButtonTooltip,
                            onSelected: (value) {
                              if (value == 'duplicate') {
                                _duplicateConfig(config);
                              } else if (value == 'set_default') {
                                _setDefaultConfig(config);
                              } else if (value == 'delete') {
                                _deleteConfig(config);
                              }
                            },
                            itemBuilder: (context) {
                              final l10n = UserStorage.l10n;
                              return [
                                PopupMenuItem<String>(
                                  value: 'duplicate',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.copy_outlined, size: 20),
                                      const SizedBox(width: 8),
                                      Text(l10n.duplicate),
                                    ],
                                  ),
                                ),
                                if (!isDefaultConfig)
                                  PopupMenuItem<String>(
                                    value: 'set_default',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star_outline,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(l10n.setAsDefault),
                                      ],
                                    ),
                                  ),
                                if (canDelete)
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.delete,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ];
                            },
                          ),
                          onTap: () => _editConfig(config),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomPrimaryActionBar(
        buttonKey: const ValueKey('add-model-config-button'),
        label: UserStorage.l10n.addConfiguration,
        icon: Icons.add_rounded,
        onPressed: () => _editConfig(null),
      ),
    );
  }
}
