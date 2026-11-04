import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memex/data/services/location_context_service.dart';
import 'package:memex/domain/models/location_context_config.dart';
import 'package:memex/ui/core/themes/app_colors.dart';
import 'package:memex/ui/core/widgets/editorial_scaffold.dart';
import 'package:memex/utils/toast_helper.dart';
import 'package:memex/utils/user_storage.dart';

typedef CurrentLocationContextLoader = Future<CurrentLocationContext> Function(
    {bool forceRefresh});
typedef LocationPermissionRequester = Future<void> Function();
typedef LocationSettingsOpener = Future<bool> Function();

class LocationContextSettingsPage extends StatefulWidget {
  const LocationContextSettingsPage({
    super.key,
    this.loadCurrentContext,
    this.requestLocationPermission,
    this.openAppSettings,
    this.openLocationSettings,
  });

  final CurrentLocationContextLoader? loadCurrentContext;
  final LocationPermissionRequester? requestLocationPermission;
  final LocationSettingsOpener? openAppSettings;
  final LocationSettingsOpener? openLocationSettings;

  @override
  State<LocationContextSettingsPage> createState() =>
      _LocationContextSettingsPageState();
}

class _LocationContextSettingsPageState
    extends State<LocationContextSettingsPage> {
  LocationContextConfig _config = const LocationContextConfig();
  LocationContextConfig _savedConfig = const LocationContextConfig();
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _runningLocationAction = false;
  int _testToken = 0;
  String? _testResult;
  CurrentLocationContext? _testContext;

  bool get _hasChanges => !_isSameConfig(_config, _savedConfig);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await UserStorage.getLocationContextConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _savedConfig = config;
      _loading = false;
    });
  }

  void _updateDraft(LocationContextConfig config) {
    setState(() => _config = config);
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _saving) return;
    setState(() => _saving = true);

    final config = _config;
    try {
      await UserStorage.saveLocationContextConfig(config);
      if (!mounted) return;
      setState(() {
        _config = config;
        _savedConfig = config;
        _saving = false;
        });
      ToastHelper.showSuccess(context, UserStorage.l10n.saveSuccess);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ToastHelper.showError(context, UserStorage.l10n.saveFailed(e));
    }
  }

  void _cancelTest() {
    // The platform call cannot be aborted; its late answer is ignored.
    _testToken++;
    setState(() => _testing = false);
  }

  Future<void> _testLocation() async {
    final token = ++_testToken;
    setState(() {
      _testing = true;
      _testResult = null;
      _testContext = null;
    });
    try {
      final loader = widget.loadCurrentContext ??
          LocationContextService.instance.getCurrentContext;
      final context = await loader(forceRefresh: true);
      if (!mounted || token != _testToken) return;
      setState(() {
        _testResult = _formatLocationDebugResult(context);
        _testContext = context;
      });
    } catch (e) {
      if (!mounted || token != _testToken) return;
      setState(
        () => _testResult = UserStorage.l10n.locationTestFailed(e.toString()),
      );
    } finally {
      if (mounted && token == _testToken) {
        setState(() => _testing = false);
      }
    }
  }

  Future<void> _handleGuidanceAction(_LocationGuidanceAction action) async {
    if (_runningLocationAction) return;
    setState(() => _runningLocationAction = true);

    try {
      switch (action) {
        case _LocationGuidanceAction.requestPermission:
          final requester = widget.requestLocationPermission ??
              () async => Geolocator.requestPermission();
          await requester();
          if (mounted) {
            await _testLocation();
          }
        case _LocationGuidanceAction.openAppSettings:
          final opener = widget.openAppSettings ?? Geolocator.openAppSettings;
          final opened = await opener();
          if (mounted && !opened) {
            ToastHelper.showError(
              context,
              UserStorage.l10n.locationSettingsOpenFailed,
            );
          }
        case _LocationGuidanceAction.openLocationSettings:
          final opener =
              widget.openLocationSettings ?? Geolocator.openLocationSettings;
          final opened = await opener();
          if (mounted && !opened) {
            ToastHelper.showError(
              context,
              UserStorage.l10n.locationSettingsOpenFailed,
            );
          }
      }
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showError(
        context,
        UserStorage.l10n.locationActionFailed(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _runningLocationAction = false);
      }
    }
  }

  String _formatLocationDebugResult(CurrentLocationContext context) {
    final l10n = UserStorage.l10n;
    final address = context.address;
    final summary = address?.summary(context.granularity);
    final lines = <String>[
      '${l10n.locationDebugGps}: ${context.status}',
      '${l10n.locationDebugProvider}: ${_providerLabel(_savedConfig.provider)}',
      '${l10n.locationDebugReverseGeocode}: '
          '${address == null ? l10n.locationDebugUnavailable : l10n.locationDebugOk}',
      '${l10n.locationDebugAgentContext}: '
          '${context.toAgentSystemReminderContent() == null ? l10n.locationDebugNotInjected : l10n.locationDebugInjected}',
    ];

    if (context.source.trim().isNotEmpty) {
      lines.add('${l10n.locationDebugSource}: ${context.source}');
    }
    if (summary != null && summary.isNotEmpty) {
      lines.add('${l10n.locationDebugAddressSummary}: $summary');
    }
    if (address?.fullAddress != null) {
      lines.add('${l10n.locationDebugFullAddress}: ${address!.fullAddress!}');
    }
    if (context.latitude != null && context.longitude != null) {
      lines.add(
        '${l10n.locationDebugCoordinates}: '
        '${context.latitude!.toStringAsFixed(6)}, '
        '${context.longitude!.toStringAsFixed(6)}',
      );
    }
    if (context.accuracyMeters != null) {
      lines.add(
        '${l10n.locationDebugAccuracy}: '
        '${context.accuracyMeters!.toStringAsFixed(1)}m',
      );
    }
    if (context.reason != null && context.reason!.trim().isNotEmpty) {
      lines.add('${l10n.locationDebugReason}: ${context.reason}');
    }

    return lines.join('\n');
  }

  String _providerLabel(GeocodingProvider provider) {
    switch (provider) {
      case GeocodingProvider.openStreetMap:
        return 'OpenStreetMap / Nominatim';
    }
  }

  bool _isSameConfig(LocationContextConfig a, LocationContextConfig b) {
    return a.enabled == b.enabled &&
        a.provider == b.provider &&
        a.granularity == b.granularity &&
        a.ttlMinutes == b.ttlMinutes;
  }

  Future<bool> _showDiscardDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(UserStorage.l10n.discardChangesTitle),
        content: Text(UserStorage.l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(UserStorage.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              UserStorage.l10n.discardButton,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  static const _granularities = [
    LocationContextGranularity.city,
    LocationContextGranularity.district,
    LocationContextGranularity.neighborhood,
    LocationContextGranularity.street,
    LocationContextGranularity.full,
  ];

  String _granularityLabel(LocationContextGranularity g) {
    final l10n = UserStorage.l10n;
    switch (g) {
      case LocationContextGranularity.city:
        return l10n.granularityCity;
      case LocationContextGranularity.district:
        return l10n.granularityDistrict;
      case LocationContextGranularity.neighborhood:
        return l10n.granularityNeighborhood;
      case LocationContextGranularity.street:
        return l10n.granularityStreet;
      case LocationContextGranularity.full:
        return l10n.granularityFullAddress;
    }
  }

  String _ttlLabel(int minutes) {
    final l10n = UserStorage.l10n;
    return minutes == 60 ? l10n.oneHour : l10n.minutesShort(minutes);
  }

  Future<void> _pickTtl() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in const [5, 15, 30, 60])
              EditorialRow(
                title: _ttlLabel(m),
                selected: m == _config.ttlMinutes,
                onTap: () => Navigator.pop(ctx, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _updateDraft(_config.copyWith(ttlMinutes: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: EditorialScaffold(
        title: l10n.locationContextTitle,
        subtitle: l10n.locationContextSubtitle,
        bottom: _loading ? null : _saveBar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const Divider(height: 1, color: AppColors.divider),
                  EditorialRow(
                    leading: const Icon(Icons.my_location_outlined),
                    title: l10n.locationContextAttachTitle,
                    subtitle: l10n.locationContextAttachDesc,
                    trailing: Switch(
                      value: _config.enabled,
                      onChanged: (value) =>
                          _updateDraft(_config.copyWith(enabled: value)),
                    ),
                  ),
                  EditorialSectionLabel(l10n.contextGranularity),
                  const Divider(height: 1, color: AppColors.divider),
                  for (final g in _granularities)
                    EditorialRow(
                      title: _granularityLabel(g),
                      selected: _config.granularity == g,
                      onTap: () =>
                          _updateDraft(_config.copyWith(granularity: g)),
                    ),
                  EditorialSectionLabel(l10n.locationFreshness),
                  const Divider(height: 1, color: AppColors.divider),
                  EditorialRow(
                    leading: const Icon(Icons.schedule_outlined),
                    title: _ttlLabel(_config.ttlMinutes),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: _pickTtl,
                  ),
                  EditorialSectionLabel(l10n.reverseGeocodingProvider),
                  const Divider(height: 1, color: AppColors.divider),
                  EditorialRow(
                    leading: const Icon(Icons.place_outlined),
                    title: _providerLabel(_config.provider),
                    subtitle: l10n.locationOsmLine,
                  ),
                  const SizedBox(height: 8),
                  _testArea(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  Widget _testArea() {
    final l10n = UserStorage.l10n;
    if (_testing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.locationTestingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.locationTestingHint,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: _cancelTest,
              style: TextButton.styleFrom(minimumSize: const Size(160, 48)),
              child: Text(
                l10n.locationCancelTest,
                style: const TextStyle(color: AppColors.primary, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
    final tested = _testContext != null || _testResult != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_testContext != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              l10n.locationTestResultTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _locationStatusFeedback(_testContext!),
          ),
        ],
        if (_testResult != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SelectableText(
              _testResult!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.divider),
        EditorialRow(
          leading: const Icon(Icons.location_searching),
          title: tested ? l10n.locationTestAgain : l10n.testCurrentLocation,
          titleColor: AppColors.primary,
          onTap: _testLocation,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            l10n.locationApproxNote,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationStatusFeedback(CurrentLocationContext context) {
    final feedback = _feedbackFor(context);
    final details = _feedbackDetails(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(feedback.icon, color: feedback.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feedback.message,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                detail,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
        if (feedback.action != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _runningLocationAction
                ? null
                : () => _handleGuidanceAction(feedback.action!),
            icon: _runningLocationAction
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(feedback.actionIcon),
            label: Text(feedback.actionLabel!),
          ),
        ],
      ],
    );
  }

  _LocationStatusFeedback _feedbackFor(CurrentLocationContext context) {
    final l10n = UserStorage.l10n;
    final reason = (context.reason ?? '').toLowerCase();

    if (context.status == 'disabled') {
      return _LocationStatusFeedback(
        icon: Icons.location_disabled_outlined,
        color: AppColors.textSecondary,
        title: l10n.locationStatusDisabledTitle,
        message: l10n.locationStatusDisabledBody,
      );
    }
    if (reason.contains('service is disabled')) {
      return _LocationStatusFeedback(
        icon: Icons.location_off_outlined,
        color: AppColors.warning,
        title: l10n.locationStatusServiceDisabledTitle,
        message: l10n.locationStatusServiceDisabledBody,
        action: _LocationGuidanceAction.openLocationSettings,
        actionIcon: Icons.settings_outlined,
        actionLabel: l10n.openLocationSettingsButton,
      );
    }
    if (reason.contains('permanently denied')) {
      return _LocationStatusFeedback(
        icon: Icons.app_settings_alt_outlined,
        color: AppColors.warning,
        title: l10n.locationStatusPermissionForeverTitle,
        message: l10n.locationStatusPermissionForeverBody,
        action: _LocationGuidanceAction.openAppSettings,
        actionIcon: Icons.app_settings_alt_outlined,
        actionLabel: l10n.openAppSettingsButton,
      );
    }
    if (reason.contains('permission denied')) {
      return _LocationStatusFeedback(
        icon: Icons.location_on_outlined,
        color: AppColors.primary,
        title: l10n.locationStatusPermissionDeniedTitle,
        message: l10n.locationStatusPermissionDeniedBody,
        action: _LocationGuidanceAction.requestPermission,
        actionIcon: Icons.location_on_outlined,
        actionLabel: l10n.allowLocationPermissionButton,
      );
    }
    if (context.isFresh && _looksApproximate(context)) {
      return _LocationStatusFeedback(
        icon: Icons.adjust_outlined,
        color: AppColors.warning,
        title: l10n.locationStatusApproximateTitle,
        message: l10n.locationStatusApproximateBody,
        action: _LocationGuidanceAction.openAppSettings,
        actionIcon: Icons.app_settings_alt_outlined,
        actionLabel: l10n.openAppSettingsButton,
      );
    }
    if (context.isFresh && context.address == null) {
      return _LocationStatusFeedback(
        icon: Icons.gps_fixed_outlined,
        color: AppColors.warning,
        title: l10n.locationStatusGeocodeUnavailableTitle,
        message: l10n.locationStatusGeocodeUnavailableBody,
      );
    }
    if (context.isFresh) {
      return _LocationStatusFeedback(
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        title: l10n.locationStatusSuccessTitle,
        message: l10n.locationStatusSuccessBody,
      );
    }

    return _LocationStatusFeedback(
      icon: Icons.info_outline,
      color: AppColors.warning,
      title: l10n.locationStatusUnavailableTitle,
      message: l10n.locationStatusUnavailableBody,
    );
  }

  List<String> _feedbackDetails(CurrentLocationContext context) {
    final l10n = UserStorage.l10n;
    final summary = context.address?.summary(context.granularity);
    return [
      '${l10n.locationStatusUpdatedAt}: ${_formatTimestamp(context.updatedAt)}',
      if (summary != null && summary.isNotEmpty)
        '${l10n.locationDebugAddressSummary}: $summary',
      if (context.accuracyMeters != null)
        '${l10n.locationDebugAccuracy}: '
            '${context.accuracyMeters!.toStringAsFixed(1)}m',
    ];
  }

  bool _looksApproximate(CurrentLocationContext context) {
    final accuracy = context.accuracyMeters;
    return accuracy != null && accuracy >= 500;
  }

  String _formatTimestamp(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  Widget _saveBar() {
    final l10n = UserStorage.l10n;
    final hasChanges = _hasChanges;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: hasChanges && !_saving ? _saveChanges : null,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(hasChanges ? l10n.save : l10n.saved),
      ),
    );
  }
}

enum _LocationGuidanceAction {
  requestPermission,
  openAppSettings,
  openLocationSettings,
}

class _LocationStatusFeedback {
  const _LocationStatusFeedback({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
    this.actionIcon,
    this.actionLabel,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final _LocationGuidanceAction? action;
  final IconData? actionIcon;
  final String? actionLabel;
}
