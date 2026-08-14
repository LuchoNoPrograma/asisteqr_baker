import 'dart:async';

import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:flutter/foundation.dart';

class TeachersViewModel extends ChangeNotifier {
  TeachersViewModel(this._repository);
  final PeopleRepository _repository;

  List<TeacherEntry> teachers = const [];
  bool loading = false;
  bool saving = false;
  String? error;
  Timer? _debounce;

  Future<void> load({String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      teachers = await _repository.getTeachers(search: search);
    } on PeopleException catch (exception) {
      error = exception.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void search(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 320),
      () => load(search: value),
    );
  }

  Future<bool> save(TeacherDraft draft, {TeacherEntry? current}) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      late final TeacherEntry saved;
      if (current == null) {
        saved = await _repository.createTeacher(draft);
      } else {
        saved = await _repository.updateTeacher(current.id, draft);
      }
      _upsert(saved);
      return true;
    } on PeopleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> deactivate(TeacherEntry teacher) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.deactivateTeacher(teacher.id);
      final index = teachers.indexWhere((item) => item.id == teacher.id);
      if (index >= 0) {
        final updated = [...teachers];
        updated[index] = updated[index].copyWith(status: 'INACTIVO');
        teachers = List.unmodifiable(updated);
      }
      return true;
    } on PeopleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  String? takeError() {
    final message = error;
    error = null;
    notifyListeners();
    return message;
  }

  void _upsert(TeacherEntry teacher) {
    final updated = [...teachers];
    final index = updated.indexWhere((item) => item.id == teacher.id);
    if (index < 0) {
      updated.add(teacher);
    } else {
      updated[index] = teacher;
    }
    updated.sort((first, second) => first.fullName.compareTo(second.fullName));
    teachers = List.unmodifiable(updated);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
