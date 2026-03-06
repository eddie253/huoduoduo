import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_flutter/features/signature/application/signature_view_model.dart';

void main() {
  group('SignatureViewModel.save', () {
    test('isSaving starts false', () {
      final vm = SignatureViewModel();
      expect(vm.isSaving, isFalse);
      vm.dispose();
    });

    test('returns result record on success', () async {
      final vm = SignatureViewModel();
      final writes = <String>[];

      final result = await vm.save(
        exportBytes: () async => Uint8List.fromList(<int>[1, 2, 3, 4]),
        now: () => DateTime.fromMillisecondsSinceEpoch(1773000000000),
        writeBytes: (File file, List<int> bytes) async {
          writes.add(file.path);
        },
      );

      expect(result, isNotNull);
      expect(result!.mimeType, 'image/png');
      expect(result.fileName, 'signature_1773000000000.png');
      expect(result.filePath, endsWith('signature_1773000000000.png'));
      expect(writes.single, endsWith('signature_1773000000000.png'));
      vm.dispose();
    });

    test('isSaving is false after successful save', () async {
      final vm = SignatureViewModel();
      await vm.save(
        exportBytes: () async => Uint8List.fromList(<int>[1, 2, 3]),
        writeBytes: (File file, List<int> bytes) async {},
      );
      expect(vm.isSaving, isFalse);
      vm.dispose();
    });

    test('notifies isSaving=true during save and false after', () async {
      final vm = SignatureViewModel();
      final states = <bool>[];
      vm.addListener(() => states.add(vm.isSaving));

      await vm.save(
        exportBytes: () async => Uint8List.fromList(<int>[1, 2, 3]),
        writeBytes: (File file, List<int> bytes) async {},
      );

      expect(states, <bool>[true, false]);
      vm.dispose();
    });

    test('throws and resets isSaving when writeBytes fails', () async {
      final vm = SignatureViewModel();

      await expectLater(
        vm.save(
          exportBytes: () async => Uint8List.fromList(<int>[1, 2, 3]),
          writeBytes: (File file, List<int> bytes) {
            throw const FileSystemException('disk full');
          },
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(vm.isSaving, isFalse);
      vm.dispose();
    });

    test('throws FormatException when exportBytes returns null', () async {
      final vm = SignatureViewModel();

      await expectLater(
        vm.save(
          exportBytes: () async => null,
        ),
        throwsA(isA<FormatException>()),
      );

      expect(vm.isSaving, isFalse);
      vm.dispose();
    });

    test('throws FormatException when exportBytes returns empty bytes',
        () async {
      final vm = SignatureViewModel();

      await expectLater(
        vm.save(
          exportBytes: () async => Uint8List(0),
        ),
        throwsA(isA<FormatException>()),
      );

      vm.dispose();
    });
  });
}
