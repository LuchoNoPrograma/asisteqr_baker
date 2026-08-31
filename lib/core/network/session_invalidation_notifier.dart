import 'package:flutter/foundation.dart';

class SessionInvalidationNotifier extends ChangeNotifier {
  bool _invalidated = false;
  int _generation = 0;

  bool get invalidated => _invalidated;
  int get generation => _generation;

  void invalidate() {
    if (_invalidated) return;
    _invalidated = true;
    _generation += 1;
    notifyListeners();
  }

  void reset() {
    _invalidated = false;
  }
}
