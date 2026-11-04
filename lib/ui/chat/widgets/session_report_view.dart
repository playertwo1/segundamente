import 'package:flutter/material.dart';
import 'package:memex/domain/models/session_report.dart';
import 'package:memex/domain/models/session_report_export.dart';
import 'package:memex/utils/user_storage.dart';

class SessionReportView extends StatefulWidget {
  const SessionReportView({
    super.key,
    required this.report,
    required this.onDraft,
    required this.onEdit,
    required this.onSetStatus,
    this.onExport = _ignoreExport,
    this.errorMessage,
    this.onDraftWithModel,
    this.usedLocalFallback = false,
  });

  final SessionReport? report;
  final Future<void> Function(ReportKind kind, String? customTitle) onDraft;
  final Future<void> Function({
    required String itemId,
    required String text,
    required String assignee,
    required String due,
  }) onEdit;
  final Future<void> Function({
    required String itemId,
    required ReportItemStatus status,
  }) onSetStatus;
  final Future<void> Function(ReportExportFormat format, Set<String> itemIds)
      onExport;
  final String? errorMessage;
  final Future<void> Function(ReportKind kind, String? customTitle)?
      onDraftWithModel;
  final bool usedLocalFallback;

  static Future<void> _ignoreExport(
    ReportExportFormat format,
    Set<String> itemIds,
  ) async {}

  @override
  State<SessionReportView> createState() => _SessionReportViewState();
}

class _SessionReportViewState extends State<SessionReportView> {
  ReportKind _kind = ReportKind.livre;
  var _query = '';
  var _selectionToken = '';
  final _selected = <String>{};
  final _customTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    final kind = widget.report?.kind;
    if (kind != null) _kind = kind;
    _syncSelection(widget.report);
  }

  @override
  void didUpdateWidget(SessionReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.report;
    if (next != null && oldWidget.report?.kind != next.kind) {
      _kind = next.kind;
    }
    _syncSelection(next);
  }

  void _syncSelection(SessionReport? report) {
    final token = report?.items.map((item) => item.id).join('|') ?? '';
    if (token == _selectionToken) return;
    _selectionToken = token;
    _selected
      ..clear()
      ..addAll(
        report?.items
                .where((item) => item.status != ReportItemStatus.discarded)
                .map((item) => item.id) ??
            const Iterable<String>.empty(),
      );
  }

  @override
  void dispose() {
    _customTitle.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDraftWithModel() async {
    final l10n = UserStorage.l10n;
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sendLeavesDeviceTitle),
        content: Text(l10n.reportModelConfirmBody),
        actions: [
          TextButton(
            key: const ValueKey('report_model_cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.sendBack),
          ),
          TextButton(
            key: const ValueKey('report_model_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.sendNow),
          ),
        ],
      ),
    );
    if (send != true) return;
    await widget.onDraftWithModel!(_kind, _customTitle.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final report = widget.report;
    final visible = report == null
        ? const <ReportItem>[]
        : searchSessionReport(report, _query);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.sessionReportTitle, key: const ValueKey('report_title')),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: DropdownButton<ReportKind>(
            key: const ValueKey('report_kind'),
            isExpanded: true,
            menuMaxHeight: 320,
            value: _kind,
            items: [
              for (final kind in ReportKind.values)
                DropdownMenuItem(
                  value: kind,
                  child: Text(
                    _kindLabel(kind),
                    key: ValueKey('report_kind_${kind.name}'),
                  ),
                ),
            ],
            onChanged: (kind) {
              if (kind == null) return;
              setState(() => _kind = kind);
            },
          ),
        ),
        if (_kind == ReportKind.custom)
          TextField(
            key: const ValueKey('report_custom_name'),
            controller: _customTitle,
            decoration: InputDecoration(hintText: l10n.reportCustomName),
          ),
        TextField(
          key: const ValueKey('report_search'),
          decoration: InputDecoration(hintText: l10n.reportSearchHint),
          onChanged: (value) => setState(() => _query = value),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('report_generate'),
            onPressed: () => widget.onDraft(_kind, _customTitle.text),
            child: Text(l10n.reportGenerate),
          ),
        ),
        if (widget.onDraftWithModel != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('report_generate_model'),
              onPressed: _confirmAndDraftWithModel,
              child: Text(l10n.reportGenerateModel),
            ),
          ),
        if (widget.usedLocalFallback)
          Text(
            l10n.reportModelFallback,
            key: const ValueKey('report_model_fallback'),
          ),
        if (report != null)
          Wrap(
            children: [
              for (final format in ReportExportFormat.values)
                TextButton(
                  key: ValueKey('report_export_${format.name}'),
                  onPressed: () => widget.onExport(format, {..._selected}),
                  child: Text(_exportLabel(format)),
                ),
            ],
          ),
        if (widget.errorMessage != null)
          Text(
            widget.errorMessage!,
            key: const ValueKey('report_error'),
          ),
        if (report != null)
          Text(report.title, key: const ValueKey('report_stored_title')),
        if (report != null)
          for (final section in report.sections) ...[
            Text(
              _sectionLabel(section),
              key: ValueKey('report_section_${section.name}'),
            ),
            for (final item in visible.where((item) => item.kind == section))
              _ReportItemTile(
                item: item,
                selected: _selected.contains(item.id),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(item.id);
                    } else {
                      _selected.remove(item.id);
                    }
                  });
                },
                onEdit: widget.onEdit,
                onSetStatus: widget.onSetStatus,
              ),
          ],
      ],
    );
  }

  String _exportLabel(ReportExportFormat format) {
    final l10n = UserStorage.l10n;
    switch (format) {
      case ReportExportFormat.markdown:
        return l10n.reportExportMarkdown;
      case ReportExportFormat.pdf:
        return l10n.reportExportPdf;
      case ReportExportFormat.docx:
        return l10n.reportExportDocx;
    }
  }

  String _kindLabel(ReportKind kind) {
    final l10n = UserStorage.l10n;
    switch (kind) {
      case ReportKind.livre:
        return l10n.reportKindFree;
      case ReportKind.reuniao:
        return l10n.reportKindMeeting;
      case ReportKind.brainstorm:
        return l10n.reportKindBrainstorm;
      case ReportKind.diario:
        return l10n.reportKindJournal;
      case ReportKind.estudo:
        return l10n.reportKindStudy;
      case ReportKind.custom:
        return l10n.reportKindCustom;
    }
  }

  String _sectionLabel(ReportItemKind kind) {
    final l10n = UserStorage.l10n;
    switch (kind) {
      case ReportItemKind.summary:
        return l10n.reportSectionSummary;
      case ReportItemKind.idea:
        return l10n.reportSectionIdea;
      case ReportItemKind.opportunity:
        return l10n.reportSectionOpportunity;
      case ReportItemKind.decision:
        return l10n.reportSectionDecision;
      case ReportItemKind.task:
        return l10n.reportSectionTask;
      case ReportItemKind.followUp:
        return l10n.reportSectionFollowUp;
      case ReportItemKind.question:
        return l10n.reportSectionQuestion;
    }
  }
}

class _ReportItemTile extends StatelessWidget {
  const _ReportItemTile({
    required this.item,
    required this.selected,
    required this.onSelected,
    required this.onEdit,
    required this.onSetStatus,
  });

  final ReportItem item;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Future<void> Function({
    required String itemId,
    required String text,
    required String assignee,
    required String due,
  }) onEdit;
  final Future<void> Function({
    required String itemId,
    required ReportItemStatus status,
  }) onSetStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = UserStorage.l10n;
    final status = switch (item.status) {
      ReportItemStatus.unconfirmed => l10n.reportUnconfirmed,
      ReportItemStatus.approved => l10n.reportApproved,
      ReportItemStatus.discarded => l10n.reportDiscarded,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          key: ValueKey('report_item_${item.id}'),
          leading: Checkbox(
            key: ValueKey('report_export_item_${item.id}'),
            value: selected,
            onChanged: (value) => onSelected(value ?? false),
          ),
          title: Text(item.text),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.assignee),
              Text(item.due),
            ],
          ),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (dialogContext) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reportSourceTitle,
                        key: const ValueKey('report_source_title'),
                      ),
                      Text(
                        item.source.excerpt,
                        key: ValueKey('report_source_excerpt_${item.id}'),
                      ),
                      if (item.source.clock != null)
                        Text(
                          item.source.clock!,
                          key: ValueKey('report_source_clock_${item.id}'),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        Text(status, key: ValueKey('report_status_${item.id}')),
        if (isDefinitiveTask(item))
          Text(
            l10n.reportDefinitiveTask,
            key: ValueKey('report_definitive_${item.id}'),
          ),
        Wrap(
          children: [
            TextButton(
              key: ValueKey('report_approve_${item.id}'),
              onPressed: () => onSetStatus(
                itemId: item.id,
                status: ReportItemStatus.approved,
              ),
              child: Text(l10n.reportApprove),
            ),
            TextButton(
              key: ValueKey('report_discard_${item.id}'),
              onPressed: () => onSetStatus(
                itemId: item.id,
                status: ReportItemStatus.discarded,
              ),
              child: Text(l10n.reportDiscard),
            ),
            TextButton(
              key: ValueKey('report_edit_${item.id}'),
              onPressed: () => _edit(context),
              child: Text(l10n.reportEdit),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final saved =
        await showDialog<({String text, String assignee, String due})>(
      context: context,
      builder: (dialogContext) => _EditReportItemDialog(item: item),
    );
    if (saved == null) return;
    await onEdit(
      itemId: item.id,
      text: saved.text,
      assignee: saved.assignee,
      due: saved.due,
    );
  }
}

class _EditReportItemDialog extends StatefulWidget {
  const _EditReportItemDialog({required this.item});

  final ReportItem item;

  @override
  State<_EditReportItemDialog> createState() => _EditReportItemDialogState();
}

class _EditReportItemDialogState extends State<_EditReportItemDialog> {
  late final TextEditingController _text;
  late final TextEditingController _assignee;
  late final TextEditingController _due;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.item.text);
    _assignee = TextEditingController(text: widget.item.assignee);
    _due = TextEditingController(text: widget.item.due);
  }

  @override
  void dispose() {
    _text.dispose();
    _assignee.dispose();
    _due.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.item.id;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: ValueKey('report_edit_text_$id'),
            controller: _text,
            maxLines: 1,
          ),
          TextField(
            key: ValueKey('report_edit_assignee_$id'),
            controller: _assignee,
            maxLines: 1,
          ),
          TextField(
            key: ValueKey('report_edit_due_$id'),
            controller: _due,
            maxLines: 1,
          ),
          TextButton(
            key: ValueKey('report_edit_save_$id'),
            onPressed: () => Navigator.pop(context, (
              text: _text.text,
              assignee: _assignee.text,
              due: _due.text,
            )),
            child: Text(UserStorage.l10n.confirm),
          ),
        ],
      ),
    );
  }
}
