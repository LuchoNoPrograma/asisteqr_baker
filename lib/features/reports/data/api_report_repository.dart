import 'dart:typed_data';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/features/reports/domain/report_repository.dart';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._client);

  final ApiClient _client;

  @override
  Future<ReportSummary> getSummary({
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async {
    final format = DateFormat('yyyy-MM-dd');
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/reportes/resumen',
        queryParameters: {
          'desde': format.format(from),
          'hasta': format.format(to),
          'cursoId': ?courseId,
        },
      );
      final json = response.data!;
      return ReportSummary(
        from: DateTime.parse(json['desde'].toString()),
        to: DateTime.parse(json['hasta'].toString()),
        enrolledStudents: (json['estudiantesInscritos'] as num).toInt(),
        punctualAttendances: (json['asistenciasPuntuales'] as num).toInt(),
        lateAttendances: (json['atrasos'] as num).toInt(),
        totalRecords: (json['totalRegistros'] as num).toInt(),
        schoolDays: (json['diasHabiles'] as num).toInt(),
        expectedAttendances: (json['asistenciasEsperadas'] as num).toInt(),
        absences: (json['inasistencias'] as num).toInt(),
        attendancePercentage: (json['porcentajeAsistencia'] as num).toDouble(),
        punctualityPercentage: (json['porcentajePuntualidad'] as num)
            .toDouble(),
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw ReportExportException(
        message ?? 'No fue posible cargar el resumen del reporte.',
      );
    }
  }

  @override
  Future<String> exportPdf({
    required DateTime from,
    required DateTime to,
    String? courseId,
  }) async {
    final format = DateFormat('yyyy-MM-dd');
    try {
      final response = await _client.dio.get<List<int>>(
        '/reportes/exportar/pdf',
        queryParameters: {
          'desde': format.format(from),
          'hasta': format.format(to),
          'cursoId': ?courseId,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ReportExportException('El reporte llegó vacío.');
      }
      return FileSaver.instance.saveFile(
        name: 'asisteqr_${format.format(from)}_${format.format(to)}',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    } on ReportExportException {
      rethrow;
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      throw ReportExportException(
        message ?? 'No fue posible generar el reporte PDF.',
      );
    } on Object {
      throw const ReportExportException(
        'No fue posible guardar el reporte PDF.',
      );
    }
  }
}
