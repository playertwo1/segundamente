import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memex/ui/chat/view_models/voice_dictation_viewmodel.dart';

void main() {
  late StreamController<Uint8List> audio;
  late int stops;

  VoiceDictationViewModel build({
    bool permission = true,
    Future<String?> Function(Float32List)? transcribe,
    Object? startError,
  }) {
    audio = StreamController<Uint8List>();
    stops = 0;
    return VoiceDictationViewModel(
      requestPermission: () async => permission,
      startStream: () async {
        if (startError != null) throw startError;
        return audio.stream;
      },
      stopStream: () async => stops++,
      transcribe: transcribe ?? (_) async => 'olá mundo',
    );
  }

  // Not awaited: close() on a never-listened controller never completes.
  tearDown(() {
    audio.close();
  });

  test('toca para gravar e toca de novo devolve a transcrição', () async {
    final vm = build();
    addTearDown(vm.dispose);

    expect(await vm.toggle(), isNull);
    expect(vm.state, VoiceDictationState.recording);

    audio.add(Uint8List.fromList([1, 0, 2, 0]));
    await Future<void>.delayed(Duration.zero);

    expect(await vm.toggle(), 'olá mundo');
    expect(vm.state, VoiceDictationState.idle);
    expect(vm.error, isNull);
    expect(stops, 1);
  });

  test('sem permissão do microfone não grava', () async {
    final vm = build(permission: false);
    addTearDown(vm.dispose);

    expect(await vm.toggle(), isNull);
    expect(vm.permissionDenied, isTrue);
    expect(vm.state, VoiceDictationState.idle);
  });

  test('falha ao transcrever devolve o erro e não texto', () async {
    final vm = build(transcribe: (_) async => throw StateError('rede'));
    addTearDown(vm.dispose);

    await vm.toggle();
    audio.add(Uint8List.fromList([1, 0, 2, 0]));
    await Future<void>.delayed(Duration.zero);

    expect(await vm.toggle(), isNull);
    expect(vm.error, isA<StateError>());
    expect(vm.state, VoiceDictationState.idle);
  });

  test('gravação sem áudio devolve texto vazio sem chamar o transcritor',
      () async {
    var calls = 0;
    final vm = build(transcribe: (_) async {
      calls++;
      return 'x';
    });
    addTearDown(vm.dispose);

    await vm.toggle();
    expect(await vm.toggle(), '');
    expect(calls, 0);
  });

  test('erro ao iniciar volta para parado com o erro registrado', () async {
    final vm = build(startError: StateError('sem microfone'));
    addTearDown(vm.dispose);

    expect(await vm.toggle(), isNull);
    expect(vm.error, isA<StateError>());
    expect(vm.state, VoiceDictationState.idle);
  });

  test('cancel descarta a gravação sem transcrever', () async {
    var calls = 0;
    final vm = build(transcribe: (_) async {
      calls++;
      return 'x';
    });
    addTearDown(vm.dispose);

    await vm.toggle();
    await vm.cancel();

    expect(vm.state, VoiceDictationState.idle);
    expect(calls, 0);
    expect(stops, 1);
  });
}
