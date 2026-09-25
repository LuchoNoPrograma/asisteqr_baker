import 'package:sis_amerinst/core/network/api_client.dart';
import 'package:sis_amerinst/core/network/session_invalidation_notifier.dart';
import 'package:sis_amerinst/core/storage/secure_token_store.dart';
import 'package:sis_amerinst/features/attendance/data/api_attendance_repository.dart';
import 'package:sis_amerinst/features/attendance/domain/attendance_repository.dart';
import 'package:sis_amerinst/features/attendance/presentation/attendance_view_model.dart';
import 'package:sis_amerinst/features/auth/data/auth_repositories.dart';
import 'package:sis_amerinst/features/auth/domain/auth_repository.dart';
import 'package:sis_amerinst/features/auth/presentation/session_view_model.dart';
import 'package:sis_amerinst/features/credentials/data/api_credential_repository.dart';
import 'package:sis_amerinst/features/credentials/data/credential_pdf_service.dart';
import 'package:sis_amerinst/features/credentials/domain/credential_document_generator.dart';
import 'package:sis_amerinst/features/credentials/domain/credential_repository.dart';
import 'package:sis_amerinst/features/credentials/presentation/credentials_view_model.dart';
import 'package:sis_amerinst/features/courses/data/api_course_repository.dart';
import 'package:sis_amerinst/features/courses/domain/course_repository.dart';
import 'package:sis_amerinst/features/courses/presentation/courses_view_model.dart';
import 'package:sis_amerinst/features/people/data/api_people_repository.dart';
import 'package:sis_amerinst/features/people/domain/people_repository.dart';
import 'package:sis_amerinst/features/people/presentation/students_view_model.dart';
import 'package:sis_amerinst/features/people/presentation/teachers_view_model.dart';
import 'package:sis_amerinst/features/reports/data/api_report_repository.dart';
import 'package:sis_amerinst/features/reports/domain/report_repository.dart';
import 'package:sis_amerinst/features/reports/presentation/report_export_view_model.dart';
import 'package:sis_amerinst/features/schedules/data/api_schedule_planner_repository.dart';
import 'package:sis_amerinst/features/schedules/domain/schedule_planner_repository.dart';
import 'package:sis_amerinst/features/schedules/presentation/schedule_planner_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStoreProvider = Provider((ref) => SecureTokenStore());
final sessionInvalidationProvider = Provider(
  (ref) => SessionInvalidationNotifier(),
);
final apiClientProvider = Provider(
  (ref) => ApiClient(
    ref.watch(tokenStoreProvider),
    sessionInvalidation: ref.watch(sessionInvalidationProvider),
  ),
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

final attendanceViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => AttendanceViewModel(ref.watch(attendanceRepositoryProvider))..load(),
);

final credentialRepositoryProvider = Provider<CredentialRepository>(
  (ref) => ApiCredentialRepository(ref.watch(apiClientProvider)),
);

final credentialDocumentGeneratorProvider =
    Provider<CredentialDocumentGenerator>((ref) => CredentialPdfService());

final credentialsViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) => CredentialsViewModel(
    ref.watch(credentialRepositoryProvider),
    ref.watch(credentialDocumentGeneratorProvider),
  )..load(),
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

final schedulePlannerRepositoryProvider = Provider<SchedulePlannerRepository>(
  (ref) => ApiSchedulePlannerRepository(ref.watch(apiClientProvider)),
);

final schedulePlannerViewModelProvider = ChangeNotifierProvider.autoDispose(
  (ref) =>
      SchedulePlannerViewModel(ref.watch(schedulePlannerRepositoryProvider))
        ..load(),
);

final sessionViewModelProvider = ChangeNotifierProvider(
  (ref) => SessionViewModel(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionInvalidationProvider),
  ),
);
