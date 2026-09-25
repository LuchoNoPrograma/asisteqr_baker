import 'dart:async';

import 'package:sis_amerinst/core/network/session_invalidation_notifier.dart';
import 'package:sis_amerinst/features/auth/domain/auth_repository.dart';
import 'package:sis_amerinst/features/auth/presentation/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sale de checking cuando el almacenamiento de sesión no responde',
    () async {
      final model = SessionViewModel(
        _HangingAuthRepository(),
        SessionInvalidationNotifier(),
      );

      expect(model.status, SessionStatus.checking);
      await Future<void>.delayed(const Duration(milliseconds: 2100));

      expect(model.status, SessionStatus.signedOut);
      expect(model.errorMessage, isNotNull);
    },
  );
}

class _HangingAuthRepository implements AuthRepository {
  @override
  Future<SessionUser?> restoreSession() => Completer<SessionUser?>().future;

  @override
  Future<SessionUser> signIn({
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
