import 'package:asisteqr_baker/features/attendance/data/mock_attendance_repository.dart';
import 'package:asisteqr_baker/features/attendance/domain/attendance_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAttendanceRepository repository;

  setUp(() => repository = MockAttendanceRepository());

  test(
    'CP-01 registra un QR valido con identidad, curso, fecha y estado',
    () async {
      final result = await repository.registerQr(
        'AQB1.test_attendance_fixture',
      );

      expect(result.duplicate, isFalse);
      expect(result.record.student.fullName, 'Valeria Mendoza Rojas');
      expect(result.record.student.course, '4.º Secundaria B');
      expect(result.record.student.code, 'EST-2026-0148');
      expect(result.record.timestamp, isNotNull);
      expect(
        result.record.status,
        anyOf(AttendanceStatus.punctual, AttendanceStatus.late),
      );
    },
  );

  test('CP-03 rechaza un QR no registrado sin devolver asistencia', () async {
    expect(
      () => repository.registerQr('QR-INVALIDO'),
      throwsA(
        isA<AttendanceException>().having(
          (error) => error.kind,
          'kind',
          AttendanceFailureKind.invalidQr,
        ),
      ),
    );
  });

  test('CP-05 identifica el duplicado y conserva la hora original', () async {
    final result = await repository.registerQr('QR-DUPLICADO');

    expect(result.duplicate, isTrue);
    expect(result.originalTimestamp, isNotNull);
  });

  test('CP-14 solicita reintento cuando el QR esta danado', () async {
    expect(
      () => repository.registerQr('QR-DAÑADO'),
      throwsA(
        isA<AttendanceException>().having(
          (error) => error.kind,
          'kind',
          AttendanceFailureKind.unreadableQr,
        ),
      ),
    );
  });

  test('CP-19 filtra registros por curso', () async {
    final records = await repository.getDaily(course: '4.º Secundaria A');

    expect(records, isNotEmpty);
    expect(
      records.every((record) => record.student.course == '4.º Secundaria A'),
      isTrue,
    );
  });
}
