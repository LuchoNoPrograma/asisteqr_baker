import 'dart:typed_data';

import 'package:sis_amerinst/features/credentials/domain/credential_models.dart';

abstract interface class CredentialDocumentGenerator {
  Future<Uint8List> build({
    required List<CredentialStudent> students,
    required CredentialPrintMode mode,
  });
}
