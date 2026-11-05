import 'package:flutter_test/flutter_test.dart';
import 'package:memex/domain/models/explicit_due.dart';

void main() {
  test('reads Brazilian and ISO dates, with or without a time', () {
    final br = parseExplicitDue('20/11/2026')!;
    expect(br.date, DateTime(2026, 11, 20));
    expect(br.hasTime, isFalse);

    final iso = parseExplicitDue('2026-11-20')!;
    expect(iso.date, DateTime(2026, 11, 20));
    expect(iso.hasTime, isFalse);

    for (final raw in [
      '20/11/2026 14:30',
      '2026-11-20T14:30',
      '2026-11-20 14:30',
      '20/11/2026 às 14:30',
      '  20/11/2026   14:30  ',
    ]) {
      final due = parseExplicitDue(raw);
      expect(due, isNotNull, reason: raw);
      expect(due!.date, DateTime(2026, 11, 20, 14, 30), reason: raw);
      expect(due.hasTime, isTrue, reason: raw);
    }
    expect(parseExplicitDue('5/1/2027')!.date, DateTime(2027, 1, 5));
  });

  test('relative words, the unknown marker and free text give null', () {
    for (final raw in [
      '',
      'não informado',
      'amanhã',
      'sexta-feira',
      'semana que vem',
      'até dia 20',
      '20/11',
      '20/11/26',
      'entregar 20/11/2026',
    ]) {
      expect(parseExplicitDue(raw), isNull, reason: raw);
    }
  });

  test('impossible dates and times give null instead of rolling over', () {
    for (final raw in [
      '31/02/2026',
      '2026-13-01',
      '2026-00-10',
      '32/01/2026',
      '20/11/2026 25:00',
      '20/11/2026 14:75',
      '20/11/2026 14:3',
    ]) {
      expect(parseExplicitDue(raw), isNull, reason: raw);
    }
  });
}
