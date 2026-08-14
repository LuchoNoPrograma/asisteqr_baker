import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_models.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';

abstract interface class SchedulePlannerRepository {
  Future<SchedulePlannerData> getPlanner();

  Future<int> savePlanner({
    required String periodId,
    required int version,
    required List<AcademicAssignment> assignments,
    required List<PlannerScheduleBlock> blocks,
    required Set<String> removedAssignmentIds,
    required Set<String> removedBlockIds,
  });

  Future<void> saveGeneralConfig(GeneralScheduleDraft draft);

  Future<ScheduleSubject> saveSubject(ScheduleSubjectDraft draft, {String? id});
  Future<void> deactivateSubject(String id);

  Future<ScheduleClassroom> saveClassroom(
    ScheduleClassroomDraft draft, {
    String? id,
  });
  Future<void> deactivateClassroom(String id);
}
