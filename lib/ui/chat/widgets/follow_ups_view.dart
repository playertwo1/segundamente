import 'package:flutter/material.dart';
import 'package:memex/domain/models/report_memory.dart';
import 'package:memex/utils/user_storage.dart';

class FollowUpsView extends StatelessWidget {
  const FollowUpsView({
    super.key,
    required this.hits,
    required this.textChanges,
    required this.onSearch,
  });

  final List<ReportHit> hits;
  final Map<String, ReportRevision> textChanges;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: const ValueKey('follow_up_search'),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.followUpsSearchHint,
            ),
            onSubmitted: onSearch,
          ),
        ),
        Expanded(
          child: hits.isEmpty
              ? Center(
                  child: Text(
                    l10n.followUpsEmpty,
                    key: const ValueKey('follow_ups_empty'),
                  ),
                )
              : ListView(
                  children: [
                    for (final hit in hits)
                      ListTile(
                        key: ValueKey(
                          'follow_up_${hit.sessionId}_${hit.item.id}',
                        ),
                        title: Text(hit.item.text),
                        subtitle: _change(hit),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget? _change(ReportHit hit) {
    final change = textChanges[reportHitKey(hit.sessionId, hit.item.id)];
    if (change == null) return null;
    return Text(
      '${change.before} → ${change.after}',
      key: ValueKey('follow_up_change_${hit.sessionId}_${hit.item.id}'),
    );
  }
}
