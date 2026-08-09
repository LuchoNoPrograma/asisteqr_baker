import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:flutter/foundation.dart';

enum SessionStatus { checking, signedOut, authenticating, signedIn }

class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._repository) {
    restore();
  }

  final AuthRepository _repository;
  SessionStatus status = SessionStatus.checking;
  SessionUser? user;
  String? errorMessage;

  Future<void> restore() async {
    try {
      user = await _repository.restoreSession().timeout(
        const Duration(seconds: 2),
      );
    } on Object {
      user = null;
      errorMessage =
          'La sesión anterior no pudo recuperarse. Ingresa nuevamente.';
    } finally {
      status = user == null ? SessionStatus.signedOut : SessionStatus.signedIn;
      notifyListeners();
    }
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
}
