# Plan Frontend - AsisteQR Baker

Construir una aplicacion Flutter profesional para docentes y administradores, basada en los mockups del proyecto Stitch `10630876069436674383`. La implementacion usara MVVM por funcionalidad, estados explicitos y una interfaz responsive que conserve la rapidez del flujo movil y la densidad del escritorio.

## Scope

- In: acceso, panel principal, escaner QR, resultado y errores, asistencia diaria, CRUD de estudiantes y docentes, historial individual, cursos/horarios, reportes y control por rol.
- In: Android y escritorio Linux/Windows, con validaciones responsive en 320,
  390 y 1280 px.
- Out: Flutter Web, iOS y macOS.
- Out inicial: reconocimiento facial, modo estudiante y notificaciones push reales.

## Direccion visual

- Tesis visual: herramienta institucional sobria, precisa y rapida, con azul petroleo, superficies claras y color reservado para estados de asistencia.
- Contenido: primero estado y accion; despues contexto del periodo, registros recientes y detalle consultable.
- Interaccion: entrada escalonada discreta, marco de escaneo vivo sin distracciones y transiciones compartidas entre estudiante detectado y resultado.
- Referencia: Stitch `AsisteQR Baker Management System`, design system `assets/fd47a8d090404bef8347b02cd7a8b892`.
- Pantallas Stitch base: acceso, panel movil, escaner, resultado, panel administrativo, asistencia diaria, cursos/horarios y reportes.
- Pantallas Stitch agregadas: gestion de usuarios/permisos `7d646a7a8ee14dc6ba71d9b313f7714e`, QR no valido `b0a5bc7ebc13459f89953b92ffd8d8ff` y estudiantes/historial `c2aef270bdb8443cb982f645375f74a8`.
- CRUD Stitch: Gestion de Estudiantes `da8dfca891f84ba29fee17547f93db2c` y Gestion de Docentes `8138035d447a4059a229198a5055341c`.

## Arquitectura MVVM

- `app/`: arranque, rutas, inyeccion y tema.
- `core/`: red, almacenamiento seguro, errores, utilidades y componentes transversales.
- `features/<modulo>/domain/`: entidades y contratos sin dependencias de Flutter.
- `features/<modulo>/data/`: DTO, fuentes de datos y repositorios.
- `features/<modulo>/presentation/`: vistas, widgets y view models.
- Los widgets no llaman HTTP ni contienen reglas de puntualidad/duplicados.
- Los view models exponen estados inmutables y comandos de interfaz.
- El backend es la autoridad para fecha, hora, duplicados, permisos y clasificacion de asistencia.

## Flujo principal

1. El usuario inicia sesion y sus tokens se guardan en almacenamiento seguro.
2. El panel carga periodo, resumen y registros recientes segun el rol.
3. El escaner solicita permiso de camara y captura un QR una sola vez por ciclo.
4. El repositorio envia el token QR al backend; nunca confia en datos personales embebidos en el codigo.
5. La vista muestra fotografia, nombre, curso, codigo, hora y estado devueltos por el servidor.
6. Los errores invalido, ilegible, inactivo, duplicado, sin red y sin permiso tienen mensajes y acciones diferentes.
7. Reportes e historial se consultan con filtros por fecha, periodo, curso y estudiante.

## Trazabilidad funcional

| Casos | Cobertura de interfaz |
|---|---|
| CP-01, CP-02, CP-04, CP-17, CP-18, CP-20 | Escaner, validacion, resultado identificado y actualizacion del panel |
| CP-03, CP-14 | Estado QR invalido/ilegible con reintento sin registro |
| CP-05 | Aviso de asistencia ya registrada con fecha y hora original |
| CP-06, CP-07 | Resultado semantico `Atraso` o `Puntual` |
| CP-08, CP-09, CP-19 | Asistencia diaria filtrable por curso y estado |
| CP-10, CP-11 | Reportes semanal y mensual |
| CP-12, CP-13 | Busqueda, historial y verificacion visual del propietario real |
| CP-15, CP-16 | Guardas de ruta y estados de acceso denegado |

## Action items

- [x] Consolidar tokens de Stitch en `app/theme` y componentes de estado accesibles.
- [x] Implementar navegacion responsive y guardas segun sesion/rol.
- [x] Implementar acceso, panel principal y cierre de sesion; renovacion disponible en el contrato backend.
- [x] Implementar escaner QR, permisos, linterna, pausa y reintento.
- [x] Corregir el ciclo de vida de cámara en Android, agregar captura QR nativa en Linux/Windows, mostrar errores recuperables y adaptar el espacio de escaneo a escritorio y móvil.
- [x] Unificar éxitos, advertencias y errores con `quickalert` en alertas modales animadas de alto contraste, jerarquía visual y acción explícita.
- [x] Implementar resultado puntual/atraso/duplicado y errores invalido/ilegible.
- [x] Implementar asistencia diaria, filtros por curso y ausencia calculada.
- [x] Implementar historial individual, cursos/horarios y reportes por periodo.
- [x] Implementar CRUD responsive de estudiantes sin campo de codigo manual.
- [x] Implementar CRUD responsive de docentes con asignacion multiple de cursos.
- [x] Conectar repositorios HTTP al contrato NestJS manteniendo mocks intercambiables para pruebas.
- [x] Descargar reportes PDF reales desde el endpoint autenticado del backend.
- [x] Proteger secretos y tokens con `flutter_secure_storage`; bloquear HTTP claro en Android release.
- [ ] Cubrir view models, widgets clave y CP-01 a CP-20 con pruebas automatizadas; el componente de alertas ya cuenta con prueba de widget.
- [x] Verificar por análisis estático y pruebas responsive los anchos 320, 390 y 1280 px, incluyendo texto al 130%.
- [ ] Validar el escaneo con cámara real en un teléfono Android físico y en Windows; Android requiere aceptar la instalación de depuración en el dispositivo.
- [ ] Ampliar la auditoría de accesibilidad automatizada.

## Definition of done

- `flutter analyze` no presenta errores.
- `flutter test` valida estados felices, errores, duplicados, atraso y permisos.
- El flujo login -> escaneo -> resultado -> reporte funciona contra el backend local.
- En Android se validan permisos concedido y denegado sobre un dispositivo físico; Linux y Windows usan la cámara nativa mediante OpenCV.
- La UI no cambia de tamano al cargar datos y no presenta texto solapado.
- El APK release no contiene URL insegura, secretos ni tokens en logs.

## Decisiones abiertas

- La primera entrega usa fotografia por URL protegida; el almacenamiento definitivo puede migrar sin cambiar las vistas.
- El pinning TLS queda preparado para produccion cuando exista dominio y certificado definitivos.
- La exportacion PDF se solicita al backend; Flutter descarga el archivo autorizado. Excel queda fuera de esta entrega.
- `mobile_scanner` cubre Android. Linux y Windows usan `opencv_dart` con `VideoCapture` y `QRCodeDetector`; el ingreso manual se conserva como alternativa en todas las plataformas soportadas.
