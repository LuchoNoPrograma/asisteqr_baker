import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_models.dart';

abstract interface class TeachingScheduleRepository {
  Future<List<TeachingSchedule>> getSchedules();
  Future<TeachingSchedule> createSchedule(TeachingScheduleDraft draft);
  Future<TeachingSchedule> updateSchedule(
    String id,
    TeachingScheduleDraft draft,
  );
  Future<void> deactivateSchedule(String id);
}
