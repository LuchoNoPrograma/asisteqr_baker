import 'package:sis_amerinst/core/network/session_invalidation_notifier.dart';
import 'package:sis_amerinst/features/auth/domain/auth_repository.dart';
import 'package:flutter/foundation.dart';

enum SessionStatus { checking, signedOut, authenticating, signedIn }

class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._repository, this._sessionInvalidation) {
    _sessionInvalidation.addListener(_handleSessionInvalidation);
    restore();
  }

  final AuthRepository _repository;
  final SessionInvalidationNotifier _sessionInvalidation;
  SessionStatus status = SessionStatus.checking;
  SessionUser? user;
  String? errorMessage;

  Future<void> restore() async {
    final invalidationGeneration = _sessionInvalidation.generation;
    SessionUser? restoredUser;
    String? restoreError;
    try {
      restoredUser = await _repository.restoreSession().timeout(
        const Duration(seconds: 2),
      );
    } on Object {
      restoreError =
          'La sesión anterior no pudo recuperarse. Ingresa nuevamente.';
    }
    if (_sessionInvalidation.generation != invalidationGeneration) return;
    user = restoredUser;
    errorMessage = restoreError;
    status = user == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    if (status == SessionStatus.signedIn) _sessionInvalidation.reset();
    notifyListeners();
  }

  Future<bool> signIn(String username, String password) async {
    status = SessionStatus.authenticating;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _repository.signIn(
        username: username.trim(),
        password: password,
      );
      status = SessionStatus.signedIn;
      _sessionInvalidation.reset();
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      status = SessionStatus.signedOut;
      errorMessage = error.message;
      notifyListeners();
      return false;
    } on Object {
      status = SessionStatus.signedOut;
      errorMessage = 'No fue posible iniciar sesión.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    user = null;
    status = SessionStatus.signedOut;
    notifyListeners();
  }

  void _handleSessionInvalidation() {
    if (!_sessionInvalidation.invalidated) return;
    user = null;
    status = SessionStatus.signedOut;
    errorMessage = 'Tu sesión expiró. Ingresa nuevamente.';
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionInvalidation.removeListener(_handleSessionInvalidation);
    super.dispose();
  }
}
