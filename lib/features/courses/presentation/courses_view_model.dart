import 'dart:async';

import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:asisteqr_baker/features/courses/domain/course_repository.dart';
import 'package:flutter/foundation.dart';

class CoursesViewModel extends ChangeNotifier {
  CoursesViewModel(this._repository);
  final CourseRepository _repository;

  List<CourseEntry> courses = const [];
  bool loading = false;
  bool saving = false;
  String? error;
  Timer? _debounce;

  Future<void> load({String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      courses = await _repository.getCourses(search: search);
    } on CourseException catch (exception) {
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

  Future<bool> saveCourse(CourseDraft draft, {CourseEntry? current}) =>
      _run(() async {
        late final CourseEntry saved;
        if (current == null) {
          saved = await _repository.createCourse(draft);
        } else {
          saved = await _repository.updateCourse(current.id, draft);
        }
        _upsertCourse(saved);
      });

  Future<bool> deactivateCourse(CourseEntry course) => _run(() async {
    await _repository.deactivateCourse(course.id);
    courses = List.unmodifiable(courses.where((item) => item.id != course.id));
  });

  Future<bool> saveSchedule(
    CourseEntry course,
    ScheduleDraft draft, {
    CourseSchedule? current,
  }) => _run(() async {
    late final CourseSchedule saved;
    if (current == null) {
      saved = await _repository.createSchedule(course.id, draft);
    } else {
      saved = await _repository.updateSchedule(course.id, current.id, draft);
    }
    final schedules = [..._currentCourse(course).schedules];
    final index = schedules.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      schedules.add(saved);
    } else {
      schedules[index] = saved;
    }
    _replaceCourse(
      course.id,
      _currentCourse(course).copyWith(schedules: schedules),
    );
  });

  Future<bool> deactivateSchedule(
    CourseEntry course,
    CourseSchedule schedule,
  ) => _run(() async {
    await _repository.deactivateSchedule(course.id, schedule.id);
    final currentCourse = _currentCourse(course);
    _replaceCourse(
      course.id,
      currentCourse.copyWith(
        schedules: currentCourse.schedules
            .where((item) => item.id != schedule.id)
            .toList(),
      ),
    );
  });

  String? takeError() {
    final message = error;
    error = null;
    notifyListeners();
    return message;
  }

  Future<bool> _run(Future<void> Function() action) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on CourseException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  CourseEntry _currentCourse(CourseEntry fallback) => courses.firstWhere(
    (course) => course.id == fallback.id,
    orElse: () => fallback,
  );

  void _upsertCourse(CourseEntry course) {
    final index = courses.indexWhere((item) => item.id == course.id);
    if (index < 0) {
      courses = List.unmodifiable([...courses, course]);
      return;
    }
    _replaceCourse(course.id, course);
  }

  void _replaceCourse(String id, CourseEntry replacement) {
    courses = List.unmodifiable([
      for (final course in courses) course.id == id ? replacement : course,
    ]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
