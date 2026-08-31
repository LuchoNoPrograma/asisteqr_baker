import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';

class SchedulePlannerSaveException extends TeachingScheduleException {
  const SchedulePlannerSaveException(
    super.message, {
    this.code,
    this.currentVersion,
    this.weekday,
    this.startTime,
    this.endTime,
    this.teacher,
    this.course,
    this.classroom,
  });

  final String? code;
  final int? currentVersion;
  final int? weekday;
  final String? startTime;
  final String? endTime;
  final String? teacher;
  final String? course;
  final String? classroom;
}

abstract interface class SchedulePlannerRepository {
  Future<SchedulePlannerData> getPlanner();

  Future<int> savePlanner({
    required int periodId,
    required int version,
    required List<AcademicAssignment> assignments,
    required List<PlannerScheduleBlock> blocks,
    required Set<int> removedAssignmentIds,
    required Set<int> removedBlockIds,
  });

  Future<int> saveGeneralConfig(GeneralScheduleDraft draft);

  Future<ScheduleSubject> saveSubject(ScheduleSubjectDraft draft, {int? id});
  Future<void> deactivateSubject(int id);

  Future<ScheduleClassroom> saveClassroom(
    ScheduleClassroomDraft draft, {
    int? id,
  });
  Future<void> deactivateClassroom(int id);
}
