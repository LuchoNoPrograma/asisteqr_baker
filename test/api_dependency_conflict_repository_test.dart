import 'dart:convert';

import 'package:asisteqr_baker/core/network/api_client.dart';
import 'package:asisteqr_baker/core/storage/secure_token_store.dart';
import 'package:asisteqr_baker/features/courses/data/api_course_repository.dart';
import 'package:asisteqr_baker/features/courses/domain/course_repository.dart';
import 'package:asisteqr_baker/features/people/data/api_people_repository.dart';
import 'package:asisteqr_baker/features/people/domain/people_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presenta el 409 de planificación al desactivar un docente', () async {
    final repositories = _repositories();

    await expectLater(
      repositories.people.deactivateTeacher(1),
      throwsA(
        isA<PeopleException>().having(
          (error) => error.message,
          'message',
          contains('planificación activa'),
        ),
      ),
    );
  });

  test('presenta el 409 de dependencias al desactivar un curso', () async {
    final repositories = _repositories();

    await expectLater(
      repositories.courses.deactivateCourse(1),
      throwsA(
        isA<CourseException>().having(
          (error) => error.message,
          'message',
          contains('dependencias activas'),
        ),
      ),
    );
  });
}

({ApiPeopleRepository people, ApiCourseRepository courses}) _repositories() {
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = _DependencyConflictAdapter();
  final client = ApiClient(_TokenStore(), httpClient: dio);
  return (
    people: ApiPeopleRepository(client),
    courses: ApiCourseRepository(client),
  );
}

class _DependencyConflictAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (code, message) = switch (options.path) {
      '/docentes/1' => (
        'DOCENTE_CON_PLANIFICACION_ACTIVA',
        'No se puede desactivar al docente mientras tenga planificación activa.',
      ),
      _ => (
        'CURSO_CON_DEPENDENCIAS_ACTIVAS',
        'No se puede desactivar el curso mientras tenga dependencias activas.',
      ),
    };
    return ResponseBody.fromString(
      jsonEncode({'code': code, 'message': message}),
      409,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TokenStore extends SecureTokenStore {
  @override
  Future<String?> readToken() async => null;
}
