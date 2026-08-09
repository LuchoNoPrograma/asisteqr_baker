import 'package:asisteqr_baker/features/courses/domain/course_models.dart';
import 'package:asisteqr_baker/features/courses/domain/course_repository.dart';
import 'package:asisteqr_baker/features/people/domain/people_models.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_repository.dart';
import 'package:flutter/foundation.dart';

class TeachingSchedulesViewModel extends ChangeNotifier {
  TeachingSchedulesViewModel(
    this._repository,
    this._peopleRepository,
    this._courseRepository,
  );

  final TeachingScheduleRepository _repository;
  final PeopleRepository _peopleRepository;
  final CourseRepository _courseRepository;

  List<TeachingSchedule> schedules = const [];
  List<TeacherEntry> teachers = const [];
  List<CourseEntry> courses = const [];
  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getSchedules(),
        _peopleRepository.getTeachers(),
        _courseRepository.getCourses(),
      ]);
      schedules = results[0] as List<TeachingSchedule>;
      teachers = (results[1] as List<TeacherEntry>)
          .where((teacher) => teacher.status == 'ACTIVO')
          .toList();
      courses = results[2] as List<CourseEntry>;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
    } on PeopleException catch (exception) {
      error = exception.message;
    } on CourseException catch (exception) {
      error = exception.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> save(
    TeachingScheduleDraft draft, {
    TeachingSchedule? current,
  }) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      final saved = current == null
          ? await _repository.createSchedule(draft)
          : await _repository.updateSchedule(current.id, draft);
      final updated = [...schedules];
      final index = updated.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        updated.add(saved);
      } else {
        updated[index] = saved;
      }
      updated.sort(_compareSchedules);
      schedules = List.unmodifiable(updated);
      return true;
    } on TeachingScheduleException catch (exception) {
      error = exception.message;
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> deactivate(TeachingSchedule schedule) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.deactivateSchedule(schedule.id);
      schedules = List.unmodifiable(
        schedules.where((item) => item.id != schedule.id),
      );
      return true;
    } on TeachingScheduleException catch (exception) {
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

  static int _compareSchedules(
    TeachingSchedule first,
    TeachingSchedule second,
  ) {
    final day = first.weekday.compareTo(second.weekday);
    return day != 0 ? day : first.startTime.compareTo(second.startTime);
  }
}
