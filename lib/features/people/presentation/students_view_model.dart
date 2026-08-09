import 'dart:async';

import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:flutter/foundation.dart';

class StudentsViewModel extends ChangeNotifier {
  StudentsViewModel(this._repository);
  final PeopleRepository _repository;

  List<StudentEntry> students = const [];
  List<CourseOption> courses = const [];
  bool loading = false;
  bool saving = false;
  String? error;
  Timer? _debounce;

  Future<void> load({String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getStudents(search: search),
        _repository.getCourses(),
      ]);
      students = results[0] as List<StudentEntry>;
      courses = results[1] as List<CourseOption>;
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

  Future<bool> save(StudentDraft draft, {StudentEntry? current}) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      late final StudentEntry saved;
      if (current == null) {
        saved = await _repository.createStudent(draft);
      } else {
        saved = await _repository.updateStudent(current.id, draft);
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

  Future<bool> retire(StudentEntry student) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.retireStudent(student.id);
      final index = students.indexWhere((item) => item.id == student.id);
      if (index >= 0) {
        final updated = [...students];
        updated[index] = updated[index].copyWith(status: 'INACTIVO');
        students = List.unmodifiable(updated);
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

  void _upsert(StudentEntry student) {
    final updated = [...students];
    final index = updated.indexWhere((item) => item.id == student.id);
    if (index < 0) {
      updated.add(student);
    } else {
      updated[index] = student;
    }
    updated.sort((first, second) => first.fullName.compareTo(second.fullName));
    students = List.unmodifiable(updated);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
