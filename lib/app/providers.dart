import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/attendance/data/api_attendance_repository.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_repository.dart';
import 'package:asisteqr_baker/features/auth/data/auth_repositories.dart';
import 'package:asisteqr_baker/features/auth/domain/auth_repository.dart';
import 'package:asisteqr_baker/features/auth/presentation/session_view_model.dart';
import 'package:asisteqr_baker/features/credentials/data/api_credential_repository.dart';
import 'package:asisteqr_baker/features/credentials/domain/credential_repository.dart';
import 'package:asisteqr_baker/features/courses/data/api_course_repository.dart';
import 'package:asisteqr_baker/features/courses/domain/course_repository.dart';
import 'package:asisteqr_baker/features/courses/presentation/courses_view_model.dart';
import 'package:asisteqr_baker/features/people/data/api_people_repository.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:asisteqr_baker/features/people/presentation/students_view_model.dart';
import 'package:asisteqr_baker/features/people/presentation/teachers_view_model.dart';
import 'package:asisteqr_baker/features/reports/data/api_report_repository.dart';
import 'package:asisteqr_baker/features/reports/domain/report_repository.dart';
import 'package:asisteqr_baker/features/reports/presentation/report_export_view_model.dart';
import 'package:asisteqr_baker/features/schedules/data/api_teaching_schedule_repository.dart';
import 'package:asisteqr_baker/features/schedules/data/api_teacher_schedule_editor_repository.dart';
import 'package:asisteqr_baker/features/schedules/data/api_schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/schedule_planner_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teacher_schedule_editor_repository.dart';
import 'package:asisteqr_baker/features/schedules/domain/teaching_schedule_repository.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teacher_schedule_editor_view_model.dart';
import 'package:asisteqr_baker/features/schedules/presentation/schedule_planner_view_model.dart';
import 'package:asisteqr_baker/features/schedules/presentation/teaching_schedules_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStoreProvider = Provider((ref) => SecureTokenStore());
final apiClientProvider = Provider(
  (ref) => ApiClient(ref.watch(tokenStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => ApiAttendanceRepository(ref.watch(apiClientProvider)),
);

final credentialRepositoryProvider = Provider<CredentialRepository>(
  (ref) => ApiCredentialRepository(ref.watch(apiClientProvider)),
);

final peopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => ApiPeopleRepository(ref.watch(apiClientProvider)),
);

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => ApiCourseRepository(ref.watch(apiClientProvider)),
);

final coursesViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => CoursesViewModel(ref.watch(courseRepositoryProvider))..load(),
);

final studentsViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => StudentsViewModel(ref.watch(peopleRepositoryProvider))..load(),
);

final teachersViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => TeachersViewModel(ref.watch(peopleRepositoryProvider))..load(),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ApiReportRepository(ref.watch(apiClientProvider)),
);

final reportExportViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => ReportExportViewModel(ref.watch(reportRepositoryProvider)),
);

final teachingScheduleRepositoryProvider = Provider<TeachingScheduleRepository>(
  (ref) => ApiTeachingScheduleRepository(ref.watch(apiClientProvider)),
);

final teachingSchedulesViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => TeachingSchedulesViewModel(
    ref.watch(teachingScheduleRepositoryProvider),
    ref.watch(peopleRepositoryProvider),
    ref.watch(courseRepositoryProvider),
  )..load(),
);

final teacherScheduleEditorRepositoryProvider =
    Provider<TeacherScheduleEditorRepository>(
      (ref) => ApiTeacherScheduleEditorRepository(ref.watch(apiClientProvider)),
    );

final schedulePlannerRepositoryProvider = Provider<SchedulePlannerRepository>(
  (ref) => ApiSchedulePlannerRepository(ref.watch(apiClientProvider)),
);

final schedulePlannerViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) =>
      SchedulePlannerViewModel(ref.watch(schedulePlannerRepositoryProvider))
        ..load(),
);

final teacherScheduleEditorViewModelProvider = ChangeNotifierProvider
    .autoDispose
    .family<TeacherScheduleEditorViewModel, String>(
      (ref, teacherId) => TeacherScheduleEditorViewModel(
        ref.watch(teacherScheduleEditorRepositoryProvider),
        teacherId,
      )..load(),
    );

final sessionViewModelProvider = ChangeNotifierProvider(
  (ref) => SessionViewModel(ref.watch(authRepositoryProvider)),
);
