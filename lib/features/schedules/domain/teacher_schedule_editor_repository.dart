import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_models.dart';

abstract interface class TeacherScheduleEditorRepository {
  Future<TeacherScheduleEditorData> getEditor(String teacherId);

  Future<({int version, List<TeacherScheduleBlock> blocks})> saveMatrix({
    required String teacherId,
    required String periodId,
    required int version,
    required List<TeacherScheduleBlock> blocks,
  });

  Future<void> saveGeneralConfig(GeneralScheduleDraft draft);
}
