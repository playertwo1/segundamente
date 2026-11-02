import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:memex/domain/models/session_report.dart';

enum ReportExportFormat { markdown, pdf, docx }

const reportExportDateLabel = 'Data';
const reportExportSourceLabel = 'Fonte';
const reportExportClockLabel = 'Relógio';

String reportExportFileName(ReportExportFormat format) {
  switch (format) {
    case ReportExportFormat.markdown:
      return 'relatorio.md';
    case ReportExportFormat.pdf:
      return 'relatorio.pdf';
    case ReportExportFormat.docx:
      return 'relatorio.docx';
  }
}

String reportExportMimeType(ReportExportFormat format) {
  switch (format) {
    case ReportExportFormat.markdown:
      return 'text/markdown';
    case ReportExportFormat.pdf:
      return 'application/pdf';
    case ReportExportFormat.docx:
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
}

String formatReportExportDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

/// [itemIds] null keeps every item that was not discarded.
/// A set keeps only those ids, including a discarded item the user checked.
String reportExportMarkdown({
  required SessionReport report,
  required DateTime exportedAt,
  Set<String>? itemIds,
}) {
  final chosen = _chosenItems(report, itemIds);
  final buffer = StringBuffer()
    ..writeln('# ${report.title}')
    ..writeln()
    ..writeln('$reportExportDateLabel: ${formatReportExportDate(exportedAt)}')
    ..writeln();
  for (final section in report.sections) {
    final items = chosen.where((item) => item.kind == section).toList();
    if (items.isEmpty) continue;
    buffer
      ..writeln('## ${_sectionTitle(section)}')
      ..writeln();
    for (final item in items) {
      buffer
        ..writeln('### ${item.text}')
        ..writeln()
        ..writeln('${item.assignee} · ${item.due}')
        ..writeln(_statusLabel(item.status))
        ..writeln('$reportExportSourceLabel: ${item.source.excerpt}');
      final clock = item.source.clock;
      if (clock != null && clock.isNotEmpty) {
        buffer.writeln('$reportExportClockLabel: $clock');
      }
      buffer.writeln();
    }
  }
  return buffer.toString();
}

List<int> exportSessionReportBytes({
  required SessionReport report,
  required DateTime exportedAt,
  required ReportExportFormat format,
  Set<String>? itemIds,
}) {
  final markdown = reportExportMarkdown(
    report: report,
    exportedAt: exportedAt,
    itemIds: itemIds,
  );
  switch (format) {
    case ReportExportFormat.markdown:
      return utf8.encode(markdown);
    case ReportExportFormat.pdf:
      return _pdf(markdown);
    case ReportExportFormat.docx:
      return _docx(markdown);
  }
}

List<ReportItem> _chosenItems(SessionReport report, Set<String>? itemIds) {
  if (itemIds == null) {
    return report.items
        .where((item) => item.status != ReportItemStatus.discarded)
        .toList(growable: false);
  }
  return report.items
      .where((item) => itemIds.contains(item.id))
      .toList(growable: false);
}

String _sectionTitle(ReportItemKind kind) {
  switch (kind) {
    case ReportItemKind.summary:
      return 'Resumo';
    case ReportItemKind.idea:
      return 'Ideias';
    case ReportItemKind.opportunity:
      return 'Oportunidades';
    case ReportItemKind.decision:
      return 'Decisões';
    case ReportItemKind.task:
      return 'Tarefas';
    case ReportItemKind.followUp:
      return 'Encaminhamentos';
    case ReportItemKind.question:
      return 'Dúvidas';
  }
}

String _statusLabel(ReportItemStatus status) {
  switch (status) {
    case ReportItemStatus.unconfirmed:
      return 'Não confirmado';
    case ReportItemStatus.approved:
      return 'Confirmado';
    case ReportItemStatus.discarded:
      return 'Descartado';
  }
}

/// shortcut: Helvetica WinAnsi covers pt-BR. A code point above 255 becomes
/// "?" in the PDF only. Upgrade when a Unicode font is bundled.
List<int> _pdf(String markdown) {
  final lines = <String>[];
  for (final line in const LineSplitter().convert(markdown)) {
    lines.addAll(_wrap(line, 90));
  }
  const perPage = 45;
  final pages = <List<String>>[];
  if (lines.isEmpty) {
    pages.add(const ['']);
  } else {
    for (var start = 0; start < lines.length; start += perPage) {
      final end = start + perPage;
      pages.add(lines.sublist(start, end > lines.length ? lines.length : end));
    }
  }
  final bodies = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>',
  ];
  final kids = <int>[];
  for (final page in pages) {
    final pageId = bodies.length + 1;
    final contentId = pageId + 1;
    kids.add(pageId);
    bodies.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
      '/Contents $contentId 0 R /Resources << /Font << /F1 3 0 R >> >> >>',
    );
    bodies.add(_content(page));
  }
  bodies[1] =
      '<< /Type /Pages /Kids [${kids.map((id) => '$id 0 R').join(' ')}] /Count ${kids.length} >>';
  return _pdfFile(bodies);
}

List<String> _wrap(String line, int width) {
  if (line.length <= width) return [line];
  final parts = <String>[];
  for (var start = 0; start < line.length; start += width) {
    final end = start + width;
    parts.add(line.substring(start, end > line.length ? line.length : end));
  }
  return parts;
}

String _content(List<String> lines) {
  final commands = StringBuffer('BT\n/F1 11 Tf\n50 800 Td\n14 TL\n');
  for (final line in lines) {
    commands.write('${_pdfLiteral(line)} Tj\nT*\n');
  }
  commands.write('ET');
  final stream = commands.toString();
  return '<< /Length ${latin1.encode(stream).length} >>\nstream\n$stream\nendstream';
}

String _pdfLiteral(String value) {
  final buffer = StringBuffer('(');
  for (final unit in value.runes) {
    final byte = unit > 255 ? 0x3f : unit;
    if (byte == 0x28 || byte == 0x29 || byte == 0x5c) buffer.write('\\');
    buffer.writeCharCode(byte);
  }
  buffer.write(')');
  return buffer.toString();
}

List<int> _pdfFile(List<String> bodies) {
  final out = BytesBuilder(copy: false);
  void add(String text) => out.add(latin1.encode(text));
  add('%PDF-1.4\n');
  final offsets = <int>[0];
  for (var i = 0; i < bodies.length; i++) {
    offsets.add(out.length);
    add('${i + 1} 0 obj\n${bodies[i]}\nendobj\n');
  }
  final xrefAt = out.length;
  final size = bodies.length + 1;
  add('xref\n0 $size\n');
  add('0000000000 65535 f \n');
  for (var i = 1; i < offsets.length; i++) {
    add('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
  }
  add('trailer\n<< /Size $size /Root 1 0 R >>\n');
  add('startxref\n$xrefAt\n%%EOF\n');
  return out.takeBytes();
}

List<int> _docx(String markdown) {
  final document = utf8.encode(_documentXml(markdown));
  final types = utf8.encode(_contentTypes);
  final rels = utf8.encode(_rels);
  final archive = Archive()
    ..addFile(ArchiveFile('[Content_Types].xml', types.length, types))
    ..addFile(ArchiveFile('_rels/.rels', rels.length, rels))
    ..addFile(ArchiveFile('word/document.xml', document.length, document));
  final encoded = ZipEncoder().encode(archive);
  if (encoded == null) throw StateError('docx empty');
  return encoded;
}

const _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>
''';

const _rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
''';

String _documentXml(String markdown) {
  final paragraphs = const LineSplitter()
      .convert(markdown)
      .map(
        (line) =>
            '<w:p><w:r><w:t xml:space="preserve">${_xml(line)}</w:t></w:r></w:p>',
      )
      .join();
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$paragraphs<w:sectPr/></w:body></w:document>';
}

String _xml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
