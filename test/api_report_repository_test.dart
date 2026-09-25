import 'dart:convert';

import 'package:sis_amerinst/core/network/api_client.dart';
import 'package:sis_amerinst/core/storage/secure_token_store.dart';
import 'package:sis_amerinst/features/reports/data/api_report_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapea la proyección histórica y los registros no computados', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = _ReportSummaryAdapter();
    final repository = ApiReportRepository(
      ApiClient(_TokenStore(), httpClient: dio),
    );

    final summary = await repository.getSummary(
      from: DateTime(2026, 8, 3),
      to: DateTime(2026, 8, 7),
      courseId: 1,
    );

    expect(summary.consideredPeriods, 1);
    expect(summary.enrolledStudents, 3);
    expect(summary.schoolDays, 4);
    expect(summary.nonInstructionalDays, 1);
    expect(summary.expectedAttendances, 8);
    expect(summary.ignoredRecords, 2);
    expect(summary.attendancePercentage, 25);
  });
}

class _ReportSummaryAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'desde': '2026-08-03',
      'hasta': '2026-08-07',
      'periodosConsiderados': 1,
      'estudiantesInscritos': 3,
      'asistenciasPuntuales': 1,
      'atrasos': 1,
      'totalRegistros': 2,
      'diasHabiles': 4,
      'diasNoLectivos': 1,
      'asistenciasEsperadas': 8,
      'inasistencias': 6,
      'registrosNoComputados': 2,
      'porcentajeAsistencia': 25,
      'porcentajePuntualidad': 50,
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _TokenStore extends SecureTokenStore {
  @override
  Future<String?> readToken() async => null;
}
