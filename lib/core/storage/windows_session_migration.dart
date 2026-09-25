import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sis_amerinst/core/config/app_brand.dart';

/// Moves the encrypted file used by flutter_secure_storage_windows 4.2.2.
/// The CMake STORAGE_PREFIX must remain stable to retain its encryption key.
class WindowsSessionMigration {
  WindowsSessionMigration(this.roamingDirectory);

  final String roamingDirectory;
  static const fileName =
      'asisteqr_baker_VGhpcyBpcyB0aGUgcHJlZml4IGZv_asisteqr_session_token.secure';
  static const markerName = '.amerinst-session-migrated';

  Future<void> run() async {
    final destination = Directory(
      p.join(roamingDirectory, AppBrand.institution, AppBrand.name),
    );
    final marker = File(p.join(destination.path, markerName));
    if (await marker.exists()) return;

    final legacy = File(
      p.join(
        roamingDirectory,
        'Unidad Educativa Baker',
        'AsisteQR Baker',
        fileName,
      ),
    );
    final current = File(p.join(destination.path, fileName));
    await destination.create(recursive: true);
    if (!await current.exists() && await legacy.exists()) {
      // Both directories are in the same roaming volume. Never decrypt or log.
      await legacy.rename(current.path);
    }
    // Survives deleteAll (*.secure), preventing an old session from returning
    // after logout when a newer session already existed at the destination.
    await marker.writeAsString('1', flush: true);
  }
}
