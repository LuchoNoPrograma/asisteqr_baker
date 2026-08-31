---
name: asisteqr-baker-qr-multiplataforma
description: Mantener el escaneo QR y registro de asistencia multiplataforma de AsisteQR Baker en Android, Linux y Windows. Usar para camara, ciclo de vida, mobile_scanner, FFmpeg/V4L2, OpenCV, ingreso manual, validacion de credenciales o respuesta de asistencia; no usar para CRUD escolar o UI sin escaneo.
---

# AsisteQR Baker QR Multiplataforma

## Proposito

Conservar un recorrido de escaneo robusto con recursos bien liberados, fallback manual y registro autoritativo e idempotente por unicidad en el backend.

## Alcance del proyecto

- Frontend en `lib/features/attendance/` y dependencias de plataforma declaradas en `pubspec.yaml` y Android cuando corresponda.
- Android mediante `mobile_scanner`, Linux mediante proceso FFmpeg/V4L2 y decodificacion OpenCV, y Windows mediante captura OpenCV.
- Backend en `src/modulos/asistencias/`, credenciales QR persistentes y unicidad diaria de asistencia en PostgreSQL.

## Fuentes

- Leer `README.md`, `AGENTS.md`, `scanner_page.dart`, `desktop_camera_scanner_native.dart`, `scanner_view_model.dart` y `api_attendance_repository.dart`.
- Leer `AttendanceController`, `AttendanceService`, los DTO y la spec del backend antes de cambiar tokens, errores o registro.
- Leer manifiesto y configuracion de la plataforma afectada; no asumir que una estrategia de camara funciona igual en Android, Linux y Windows.

## Patrones del proyecto

- `lib/features/attendance/presentation/scanner_page.dart` - `_ScannerPageState`: coordina `WidgetsBindingObserver`, una sola validacion con `_handling`, pausa/reinicio de camara y fallback manual.
- `lib/features/attendance/presentation/desktop_camera_scanner_native.dart` - `_DesktopCameraScannerState`: separa FFmpeg/V4L2 en Linux de `VideoCapture` en Windows y libera procesos, streams, timers y objetos OpenCV.
- `/home/nini/IdeaProjects/asisteqr_baker_backend/src/modulos/asistencias/infraestructura/attendance.service.ts` - `AttendanceService.scan` y `registerAttendance`: valida credencial, usa transaccion y devuelve el registro existente ante duplicado diario.

## Flujo

1. Identificar plataforma, disponibilidad y permiso de camara, ciclo de vida, fuente de frames, decodificacion, control de duplicados y fallback manual.
2. Mantener deteccion y recursos de camara en presentation, validacion asincrona en `ScannerViewModel` y transporte/mapeo en `ApiAttendanceRepository`.
3. Tratar el QR como credencial opaca y enviar el token solo al endpoint autenticado; el backend decide vigencia, estudiante, curso, horario, puntualidad y duplicado.
4. Pausar captura durante una validacion, impedir solicitudes simultaneas y reanudar solo si widget, sesion y pantalla siguen vigentes.
5. Liberar camara, detector, frames, subscripciones, timers y procesos en pausa, error, reintento y dispose.
6. Mantener ingreso manual por codigo disponible cuando no haya camara, permiso, FFmpeg o compatibilidad.

## Reglas

- No habilitar Flutter Web ni usarlo como fallback del escaner.
- No registrar, persistir ni mostrar el token QR completo en logs, auditoria o mensajes de error.
- No crear un registro por frame ni reintentar en paralelo; una deteccion mantiene una sola operacion en vuelo.
- No reemplazar el fallback manual por una dependencia obligatoria de camara.
- No generar un QR nuevo al reimprimir; la credencial persistente cambia solo por revocacion explicita.
- No confiar en deduplicacion del cliente; PostgreSQL conserva la unicidad diaria y el backend informa `duplicado`.

## Validacion

- Ejecutar `dart format` sobre los Dart tocados y `flutter analyze`.
- Ejecutar `flutter test test/api_attendance_repository_test.dart test/attendance_repository_test.dart` cuando cambien contrato, mapeo o control de duplicados; no agregar pruebas de widget del escaner.
- Ejecutar la spec focalizada `src/modulos/asistencias/infraestructura/attendance.service.spec.ts` en el backend cuando cambie validacion o persistencia.
- Cuando cambie captura nativa, verificar manualmente solo en la plataforma afectada que pausa, reanuda, reintenta, libera recursos y conserva el ingreso manual.

## Autoevaluacion

- Existe como maximo una validacion en vuelo por lectura?
- Cada recurso nativo se libera en pausa, error y dispose?
- El backend sigue siendo la autoridad de credencial, horario, estado y duplicado?
