import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sis_amerinst/core/config/app_brand.dart';
import 'package:sis_amerinst/core/storage/windows_session_migration.dart';

void main() {
  late Directory roaming;
  late File legacy;
  late File current;
  setUp(() async {
    roaming = await Directory.systemTemp.createTemp('amerinst-session-');
    legacy = File(
      p.join(
        roaming.path,
        'Unidad Educativa Baker',
        'AsisteQR Baker',
        WindowsSessionMigration.fileName,
      ),
    );
    current = File(
      p.join(
        roaming.path,
        AppBrand.institution,
        AppBrand.name,
        WindowsSessionMigration.fileName,
      ),
    );
  });
  tearDown(() async => roaming.delete(recursive: true));

  test(
    'moves encrypted bytes unchanged and preserves unrelated files',
    () async {
      await legacy.parent.create(recursive: true);
      await legacy.writeAsBytes([0, 255, 19, 82]);
      final unrelated = File(p.join(legacy.parent.path, 'other.secure'));
      await unrelated.writeAsBytes([44]);
      await WindowsSessionMigration(roaming.path).run();
      expect(await current.readAsBytes(), [0, 255, 19, 82]);
      expect(await legacy.exists(), isFalse);
      expect(await unrelated.readAsBytes(), [44]);
    },
  );

  test(
    'preserves current session and cannot resurrect legacy after logout',
    () async {
      await legacy.parent.create(recursive: true);
      await legacy.writeAsBytes([1]);
      await current.parent.create(recursive: true);
      await current.writeAsBytes([2]);
      await WindowsSessionMigration(roaming.path).run();
      expect(await current.readAsBytes(), [2]);
      await current.delete();
      await WindowsSessionMigration(roaming.path).run();
      expect(await current.exists(), isFalse);
    },
  );

  test('fresh installation creates no encrypted session', () async {
    await WindowsSessionMigration(roaming.path).run();
    expect(await current.exists(), isFalse);
  });
}
