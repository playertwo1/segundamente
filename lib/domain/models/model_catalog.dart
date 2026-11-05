import 'dart:convert';

/// Whether a model id is on the curated list, returned by the account, or only typed by hand.
enum ModelAvailability { supported, accessible, untested }

/// Adapter capabilities probed from the model settings screen.
enum ModelCapability { text, streaming, json, vision, audio }

/// Result of one capability probe. [unknown] means the probe did not run or did not prove a miss.
enum CapabilityVerdict { unknown, yes, no }

/// Cached model list for one provider and base URL.
///
/// Availability is derived from [fetchedIds] plus the provider's recommended
/// list, so a curated id does not stay "untested" after the recommended list changes.
class ModelCatalog {
  static const int schemaVersion = 1;
  static const int storeVersion = 1;

  final int version;
  final String providerType;
  final String baseUrl;
  final DateTime? fetchedAt;
  final List<String> fetchedIds;
  final List<String> manualIds;
  final Map<String, Map<ModelCapability, CapabilityVerdict>> capabilities;

  const ModelCatalog({
    required this.version,
    required this.providerType,
    required this.baseUrl,
    required this.fetchedAt,
    required this.fetchedIds,
    required this.manualIds,
    required this.capabilities,
  });

  factory ModelCatalog.empty({
    required String providerType,
    required String baseUrl,
  }) {
    return ModelCatalog(
      version: schemaVersion,
      providerType: providerType,
      baseUrl: normalizeBaseUrl(baseUrl),
      fetchedAt: null,
      fetchedIds: const [],
      manualIds: const [],
      capabilities: const {},
    );
  }

  static String normalizeBaseUrl(String baseUrl) {
    var value = baseUrl.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static String cacheKey(String providerType, String baseUrl) =>
      '$providerType|${normalizeBaseUrl(baseUrl)}';

  String get cacheKeyValue => cacheKey(providerType, baseUrl);

  static ModelAvailability? availabilityOf({
    required String modelId,
    required List<String> recommended,
    required List<String> fetchedIds,
  }) {
    final id = modelId.trim();
    if (id.isEmpty) return null;
    if (fetchedIds.contains(id)) return ModelAvailability.accessible;
    if (recommended.contains(id)) return ModelAvailability.supported;
    return ModelAvailability.untested;
  }

  ModelAvailability? statusOf(String modelId, List<String> recommended) {
    return availabilityOf(
      modelId: modelId,
      recommended: recommended,
      fetchedIds: fetchedIds,
    );
  }

  ModelCapabilityMatrix matrixFor(String modelId) {
    final stored = capabilities[modelId.trim()] ?? const {};
    return ModelCapabilityMatrix({
      for (final capability in ModelCapability.values)
        capability: stored[capability] ?? CapabilityVerdict.unknown,
    });
  }

  /// Ids to show besides the recommended and fetched lists.
  List<String> manualIdsOutside(Iterable<String> alreadyListed) {
    final listed = alreadyListed.toSet();
    return manualIds.where((id) => !listed.contains(id)).toList();
  }

  ModelCatalog rememberManual(String modelId) {
    final id = modelId.trim();
    if (id.isEmpty || manualIds.contains(id)) return this;
    return copyWith(manualIds: [...manualIds, id]);
  }

  /// Keeps [fetchedAt] when the account returned the same ids.
  ModelCatalog rememberFetch(List<String> ids, DateTime fetchedAt) {
    if (ids.isEmpty) return this;
    if (_sameIds(fetchedIds, ids)) return this;
    return copyWith(fetchedIds: List<String>.from(ids), fetchedAt: fetchedAt);
  }

  /// Ignores [CapabilityVerdict.unknown] so a later network failure cannot erase a real probe.
  ModelCatalog rememberVerdict(
    String modelId,
    ModelCapability capability,
    CapabilityVerdict verdict,
  ) {
    final id = modelId.trim();
    if (id.isEmpty || verdict == CapabilityVerdict.unknown) return this;
    final next = <String, Map<ModelCapability, CapabilityVerdict>>{
      for (final entry in capabilities.entries)
        entry.key: Map<ModelCapability, CapabilityVerdict>.from(entry.value),
    };
    final row = next.putIfAbsent(id, () => {});
    row[capability] = verdict;
    final withId = manualIds.contains(id) ? manualIds : [...manualIds, id];
    return copyWith(capabilities: next, manualIds: withId);
  }

  ModelCatalog copyWith({
    List<String>? fetchedIds,
    DateTime? fetchedAt,
    List<String>? manualIds,
    Map<String, Map<ModelCapability, CapabilityVerdict>>? capabilities,
  }) {
    return ModelCatalog(
      version: version,
      providerType: providerType,
      baseUrl: baseUrl,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      fetchedIds: fetchedIds ?? this.fetchedIds,
      manualIds: manualIds ?? this.manualIds,
      capabilities: capabilities ?? this.capabilities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'providerType': providerType,
      'baseUrl': baseUrl,
      'fetchedAt': fetchedAt?.toUtc().toIso8601String(),
      'fetchedIds': fetchedIds,
      'manualIds': manualIds,
      'capabilities': {
        for (final entry in capabilities.entries)
          entry.key: {
            for (final verdict in entry.value.entries)
              verdict.key.name: verdict.value.name,
          },
      },
    };
  }

  static ModelCatalog? fromJson(Map<String, dynamic> json) {
    if (json['version'] != schemaVersion) return null;
    final providerType = json['providerType'];
    final baseUrl = json['baseUrl'];
    if (providerType is! String || baseUrl is! String) return null;

    DateTime? fetchedAt;
    final rawFetchedAt = json['fetchedAt'];
    if (rawFetchedAt is String && rawFetchedAt.isNotEmpty) {
      fetchedAt = DateTime.tryParse(rawFetchedAt);
    }

    return ModelCatalog(
      version: schemaVersion,
      providerType: providerType,
      baseUrl: normalizeBaseUrl(baseUrl),
      fetchedAt: fetchedAt,
      fetchedIds: _stringList(json['fetchedIds']),
      manualIds: _stringList(json['manualIds']),
      capabilities: _capabilities(json['capabilities']),
    );
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().where((id) => id.trim().isNotEmpty).toList();
  }

  static Map<String, Map<ModelCapability, CapabilityVerdict>> _capabilities(
    Object? raw,
  ) {
    if (raw is! Map) return const {};
    final parsed = <String, Map<ModelCapability, CapabilityVerdict>>{};
    raw.forEach((modelId, verdicts) {
      if (modelId is! String || verdicts is! Map) return;
      final row = <ModelCapability, CapabilityVerdict>{};
      verdicts.forEach((capabilityName, verdictName) {
        final capability = _enumByName(ModelCapability.values, capabilityName);
        final verdict = _enumByName(CapabilityVerdict.values, verdictName);
        if (capability == null || verdict == null) return;
        row[capability] = verdict;
      });
      parsed[modelId] = row;
    });
    return parsed;
  }

  static bool _sameIds(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

class ModelCapabilityMatrix {
  final Map<ModelCapability, CapabilityVerdict> verdicts;

  const ModelCapabilityMatrix(this.verdicts);

  factory ModelCapabilityMatrix.unknown() {
    return ModelCapabilityMatrix({
      for (final capability in ModelCapability.values)
        capability: CapabilityVerdict.unknown,
    });
  }

  List<ModelCapability> get missing => ModelCapability.values
      .where((capability) => verdicts[capability] == CapabilityVerdict.no)
      .toList();

  bool get hasMissing => missing.isNotEmpty;
}

/// Turns a probe into a verdict without calling a provider.
class ModelCapabilityJudge {
  static CapabilityVerdict judge({
    required ModelCapability capability,
    required bool transportOk,
    required String text,
    int textChunks = 0,
    String? error,
  }) {
    if (!transportOk) return fromError(capability, error ?? '');
    switch (capability) {
      case ModelCapability.json:
        return looksLikeJsonObject(text)
            ? CapabilityVerdict.yes
            : CapabilityVerdict.no;
      case ModelCapability.streaming:
        return textChunks > 0 && text.trim().isNotEmpty
            ? CapabilityVerdict.yes
            : CapabilityVerdict.no;
      case ModelCapability.text:
      case ModelCapability.vision:
      case ModelCapability.audio:
        return text.trim().isNotEmpty
            ? CapabilityVerdict.yes
            : CapabilityVerdict.no;
    }
  }

  /// A transport failure is [CapabilityVerdict.no] only when the error names that capability.
  static CapabilityVerdict fromError(ModelCapability capability, String error) {
    final normalized = error.toLowerCase();
    const transport = [
      'timed out',
      'timeout',
      'api key',
      'unauthorized',
      'not authorized',
      '401',
      '403',
      'socket',
      'connection',
    ];
    if (transport.any(normalized.contains)) return CapabilityVerdict.unknown;
    final namesCapability = switch (capability) {
      ModelCapability.vision => normalized.contains('image') ||
          normalized.contains('vision') ||
          normalized.contains('multimodal'),
      ModelCapability.audio => normalized.contains('audio'),
      ModelCapability.json => normalized.contains('json'),
      ModelCapability.streaming => normalized.contains('stream'),
      ModelCapability.text => false,
    };
    return namesCapability ? CapabilityVerdict.no : CapabilityVerdict.unknown;
  }

  static bool looksLikeJsonObject(String text) {
    var value = text.trim();
    if (value.startsWith('```')) {
      value = value
          .replaceFirst(RegExp(r'^```(?:json)?'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }
    try {
      return jsonDecode(value) is Map;
    } catch (_) {
      return false;
    }
  }
}
