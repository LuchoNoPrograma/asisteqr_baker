# AsisteQR Baker

Aplicación Flutter responsive para registrar asistencia mediante QR, verificar la identidad del estudiante y consultar reportes protegidos por rol.

Incluye CRUD responsive de estudiantes, docentes, cursos, horarios de ingreso y planillas semanales. El formulario de estudiantes no solicita código: la API devuelve el consecutivo asignado por PostgreSQL. Las fotografías visibles y las credenciales PDF usan la fuente entregada por la API; las imágenes de demostración quedan limitadas a los repositorios mock.

El escáner mantiene el ciclo de vida de la cámara al cambiar de aplicación, diferencia errores de permiso y compatibilidad, y conserva el ingreso manual como alternativa. Usa `mobile_scanner` en Android y `opencv_dart` para captura y lectura QR nativa en Linux y Windows. Las confirmaciones, advertencias y errores importantes se presentan con `quickalert` como alertas modales animadas de alto contraste.

## Desarrollo local

Para Linux Desktop:

```bash
flutter run -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
```

## Cámara y plataformas

- Android solicita el permiso de cámara al entrar a `Escanear`. El manifiesto declara la cámara como opcional para que el ingreso manual siga disponible en equipos sin cámara.
- Los ejecutables nativos de Linux y Windows usan `opencv_dart` para abrir la cámara y decodificar QR. Si no existe una cámara disponible, la interfaz muestra el error y permite reintentar o usar el ingreso manual.

Para Android Emulator:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

Para un teléfono Android físico, define una URL HTTPS o una IP local alcanzable para la API; `10.0.2.2` solo corresponde al emulador.

- APK: `build/app/outputs/flutter-apk/app-debug.apk`

La vista de reportes descarga un PDF real desde la API autenticada. Las credenciales se introducen en la pantalla de acceso y nunca se versionan en este repositorio. No uses `.env` ni `--dart-define` para secretos de usuario: Flutter los incorpora al artefacto compilado.

## Verificación

```bash
flutter analyze
flutter test
```
