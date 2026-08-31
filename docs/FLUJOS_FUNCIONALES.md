# Flujos funcionales de AsisteQR Baker

Última revisión: 2026-08-22 (America/La_Paz).

Este documento describe el comportamiento que existe en el código actual. No
es una lista de deseos ni sustituye las reglas de `AGENTS.md`. El recorrido de
ejecución normal es siempre:

```text
Vista Flutter -> ViewModel -> contrato de dominio -> repositorio API
-> controller NestJS -> service propietario -> Prisma -> PostgreSQL
```

Los mocks existen solo como dobles de prueba o demostración y no están
inyectados por `lib/app/providers.dart` durante la ejecución normal.

## Actores y acceso

| Capacidad | Administrador | Docente | Regente | Autoridad final |
|---|---:|---:|---:|---|
| Iniciar/restaurar/cerrar sesión | Sí | Sí | Sí | Autenticación y sesión opaca en PostgreSQL |
| Panel y asistencia diaria | Sí | Sí | Sí | API |
| Historial y reportes | Sí | Sí | No | API |
| Escaneo QR e ingreso manual | Sí | No | Sí | API + unicidad de PostgreSQL |
| Consultar estudiantes, docentes y horarios académicos | Sí | Sí | No | API |
| Consultar cursos para filtrar asistencia | Sí | Sí | Sí | API |
| Crear, editar o desactivar datos académicos | Sí | No | No | Guards y services NestJS |
| Editar planificación y configuración general | Sí | No | No | Transacción de horarios |
| Preparar e imprimir credenciales | Sí | No | No | API para QR; Flutter para generar el PDF |
| Consultar salud de la API | Público | Público | Público | HealthService + PostgreSQL |

Flutter oculta los comandos fuera de cada rol, pero la seguridad real permanece
en `SessionAuthGuard` y `RolesGuard`. GoRouter limita al regente a inicio,
escáner, resultado y asistencia; el backend vuelve a validar cada lectura y
escritura protegida.

## Flujos de usuario

### F-01. Arranque y restauración de sesión

- Entrada: apertura de la aplicación en `/inicio`.
- Recorrido: `SessionViewModel.restore` lee el token de almacenamiento seguro y
  consulta `GET /autenticacion/sesion`.
- Resultado: sesión válida redirige a `/inicio`; token ausente, inválido o
  recuperación fallida redirige a `/acceso`.
- Estado visible: `/cargando` mientras se resuelve la sesión.
- Propietario: `autenticacion`; consumidor Flutter `features/auth` y router.

### F-02. Inicio de sesión

- Entrada: usuario y contraseña en `/acceso`.
- Recorrido: `POST /autenticacion/iniciar-sesion`; Argon2 valida la contraseña,
  se crea una sesión opaca, solo su hash queda en PostgreSQL y el token se
  guarda con `flutter_secure_storage`.
- Resultado: usuario, rol principal y expiración de la sesión.
- Errores previstos: credenciales incorrectas, throttle, validación de campos,
  API no disponible.
- Auditoría: `LOGIN_EXITOSO` o `LOGIN_FALLIDO` sin registrar contraseña ni
  token.

### F-03. Cierre y vencimiento de sesión

- Cierre explícito: `POST /autenticacion/cerrar-sesion` revoca la sesión y
  Flutter elimina el token local.
- Vencimiento/revocación: cualquier endpoint protegido devuelve `401` cuando
  el hash no existe, la sesión venció, fue revocada o el usuario está inactivo.
- Propietario: `autenticacion` y `comun/seguridad`.
- Riesgo conocido: ver `AUD-003` en `BITACORA_AUDITORIA.md`; un `401` limpia el
  token, pero no cambia por sí mismo el estado observable del router.

### F-04. Panel principal

- Entrada: `/inicio`.
- Recorrido: `DashboardViewModel` usa `AttendanceRepository.getDashboard`, que
  deriva el resumen desde `GET /asistencias/diaria`.
- Salida: esperados, presentes, puntuales, atrasos, ausentes, matriz por curso y
  actividad reciente.
- Autoridad: el backend produce la jornada diaria; Flutter agrega los totales
  para presentarlos.
- La actividad reciente filtra registros presentes y los ordena por hora
  descendente antes de tomar cinco.

### F-05. Escaneo QR en Android

- Actor: regente; el administrador conserva capacidad operativa de respaldo.
- Entrada: `/escaner`; se selecciona jornada y luego se solicita permiso e
  inicia `mobile_scanner`.
- Ciclo: una detección pausa la cámara, bloquea lecturas simultáneas y envía el
  token opaco a `POST /asistencias/escanear`.
- Resultado: navegación a `/resultado`; al regresar se limpia el estado y se
  reinicia la cámara.
- Alternativas: reintento e ingreso manual si no hay permiso o cámara.
- Autoridad: el backend resuelve credencial, estudiante, curso, horario de la
  jornada elegida, hora, estado y duplicado.
- Validación manual pendiente: teléfono Android físico.

### F-06. Escaneo QR en Linux y Windows

- Linux: FFmpeg captura `/dev/video0` por V4L2; OpenCV decodifica frames JPEG.
- Windows: `VideoCapture` y `QRCodeDetector` de OpenCV.
- Pausa/dispose: se cancelan timers, streams, proceso FFmpeg y objetos OpenCV.
- Alternativa: ingreso manual disponible en ambas plataformas.
- Validación manual pendiente: cámara real en Windows; Linux depende de que
  `ffmpeg` esté disponible en `PATH`.

### F-07. Registro manual de asistencia

- Entrada: código numérico del estudiante desde el diálogo del escáner.
- Recorrido: `POST /asistencias/manual` recibe código y jornada, busca
  `codigoEstudiante` y ejecuta la misma transacción de registro que el QR.
- Resultado: puntual, atraso o duplicado con la hora autoritativa.
- Errores: estudiante inexistente/inactivo, sin inscripción, sin horario de
  ingreso o sin configuración general.
- Una jornada no activa para el curso se comunica mediante el código estable
  `HORARIO_JORNADA_AUSENTE`.

### F-08. Registro autoritativo y duplicados

- La API toma la inscripción del periodo activo y el horario activo de la
  jornada seleccionada por el regente.
- La hora local se calcula con la zona de la configuración general y se compara
  con hora límite más tolerancia.
- PostgreSQL aplica unicidad por estudiante, horario y fecha local.
- Una carrera no crea dos filas: `ON CONFLICT DO NOTHING` devuelve el registro
  original y `duplicado: true`.
- Auditoría: una entrada `ASISTENCIA_REGISTRADA` o
  `ASISTENCIA_DUPLICADA` por operación.
- Dos jornadas del mismo día producen registros independientes; repetir dentro
  de la misma jornada devuelve el registro original.

### F-09. Asistencia diaria

- Entrada: `/asistencia`, fecha, curso, jornada y estado.
- API: `GET /asistencias/diaria?fecha=YYYY-MM-DD&cursoId=...&jornada=...`.
- El backend combina inscripciones activas del periodo activo con asistencias
  de la fecha y proyecta una fila por estudiante y horario. Cuando no existe
  registro devuelve `AUSENTE` con `fechaHora: null`.
- Desktop usa `AppDataTable`; móvil usa tarjetas. La búsqueda, orden, filtros y
  paginación son locales sobre la respuesta cargada.
- La UI muestra `—` o “Sin registro de ingreso” para ausencias, sin inventar
  una hora.

### F-10. Historial de un estudiante

- Entrada: selección del estudiante y navegación a `/historial` con su ID.
- API: `GET /estudiantes/:id/historial`; aunque la ruta empieza por
  `estudiantes`, el propietario es `reportes`.
- Salida: identidad, fotografía y asistencias ordenadas de más reciente a más
  antigua.
- Estados: carga, lista vacía, error con reintento.

### F-11. Gestión de estudiantes

- Entrada: `/estudiantes`.
- Lectura: `GET /estudiantes` y `GET /cursos`.
- Escritura admin: `POST /estudiantes`, `PATCH /estudiantes/:id` y
  `DELETE /estudiantes/:id`.
- Crear asigna el consecutivo en PostgreSQL e inscribe al estudiante en el
  periodo activo; Flutter nunca envía el código.
- Retirar usa una transacción: marca al estudiante `RETIRADO`, retira
  inscripciones activas y revoca credenciales activas.
- Fotografía: Flutter recorta a 640 px, codifica JPEG y la API valida la fuente.
- El PATCH general no acepta `estado`; toda transición pasa por el DELETE
  explícito y conserva los efectos laterales y la auditoría.

### F-12. Gestión de docentes y horario contextual

- Entrada: `/docentes`.
- Lectura: `GET /docentes`; escritura admin con `POST`, `PATCH` y `DELETE`.
- `Configurar horario` navega a `/docentes/:docenteId/horario` y proyecta la
  misma fuente del planificador general, no otro repositorio.
- Desactivar responde `409 DOCENTE_CON_PLANIFICACION_ACTIVA` si existen
  asignaciones o bloques activos, con conteos para resolverlos en el
  planificador. Sin dependencias marca al docente `INACTIVO` y audita.
- El PATCH general no acepta `estado`.

### F-13. Gestión de cursos

- Entrada: `/cursos`.
- Lectura: `GET /cursos`; escritura admin con `POST`, `PATCH` y `DELETE`.
- El nombre institucional se deriva de nivel y paralelo; la base impide repetir
  nivel, paralelo y gestión.
- La respuesta agrega cantidad de estudiantes y docentes y horarios de ingreso.
- Desactivar responde `409 CURSO_CON_DEPENDENCIAS_ACTIVAS` si existen
  matrículas, asignaciones o bloques activos. Sin dependencias marca el curso y
  sus horarios de ingreso como inactivos y audita.
- El PATCH general no acepta `activo`.

### F-14. Horarios de ingreso por curso

- Entrada: diálogo desde un curso.
- API admin: `POST`, `PATCH` y `DELETE /cursos/:id/horarios/...`.
- Cada curso admite como máximo un horario por jornada
  `MANANA | TARDE | NOCHE`.
- La hora límite participa en la clasificación de asistencia; la tolerancia se
  toma actualmente de la configuración general.
- El registro exige la jornada y resuelve exactamente el horario activo
  correspondiente.

### F-15. Catálogo de materias

- Entrada: `/materias`.
- Lectura para ambos roles: `GET /materias`.
- Escritura admin: `POST`, `PATCH` y `DELETE /materias/:id`.
- El nombre se normaliza a mayúsculas y debe ser único.
- La API impide desactivar una materia con asignaciones o bloques activos.

### F-16. Catálogo de aulas

- Entrada: `/aulas`.
- Lectura para ambos roles: `GET /aulas`.
- Escritura admin: `POST`, `PATCH` y `DELETE /aulas/:id`.
- Datos: nombre único, capacidad opcional y ubicación opcional.
- La API impide desactivar un aula con bloques activos.

### F-17. Carga del planificador

- Entradas: `/horarios` o `/docentes/:docenteId/horario`.
- API: `GET /horarios-clase/planificador`.
- Proyección única: periodo, configuración, recreos, cursos, materias, aulas,
  docentes, asignaciones, carga programada, versión y bloques.
- Perspectivas Flutter: curso, docente y aula sobre las mismas listas.
- Sin configuración: la API devuelve catálogos y `configuracion: null`; el
  administrador debe crear la jornada con versión `0`.
- Riesgos conocidos: recurso contextual inválido se reemplaza silenciosamente
  y turnos fijos pueden no cruzarse con la jornada (`AUD-012`).

### F-18. Edición local de carga y bloques

- `SchedulePlannerViewModel` conserva original, borrador, altas/cambios, bajas
  lógicas, undo y redo con máximo 50 instantáneas.
- Crear, mover, redimensionar, duplicar o retirar no llama a la API.
- Desktop muestra matriz lunes-viernes de 30 minutos con arrastre y teclado.
- Android muestra agenda por día y diálogos táctiles.
- Validación local: rango de jornada, recreos y superposición de docente, curso
  o aula. El backend vuelve a validar todo de manera autoritativa.

### F-19. Guardado batch del planificador

- API admin: una sola llamada `PUT /horarios-clase/planificador` con versión,
  estado completo y bajas explícitas.
- Transacción: bloqueo asesor por periodo, versión optimista, validación de
  catálogos/asignaciones/conflictos, diff lógico, incremento de versión y una
  auditoría resumida.
- `409 VERSION_OBSOLETA` conserva el borrador y ofrece recarga explícita.
- Riesgos conocidos: confirmación del guardado seguida de fallo al recargar
  (`AUD-011`) y payloads contradictorios no rechazados de forma explícita
  (`AUD-014`).

### F-20. Configuración general y recreos

- API admin: `PUT /horarios-clase/configuracion/general`.
- Datos: inicio, fin, intervalo fijo de 30 minutos, tolerancia, zona IANA,
  versión y hasta ocho recreos.
- La API rechaza recreos solapados y configuraciones que dejan clases fuera de
  rango o encima de un recreo.
- La API comprueba que las clases existentes sigan alineadas con la nueva
  grilla y la UI deriva sus segmentos de la jornada recibida.
- Calendario académico: `GET/POST /periodos/:id/dias-no-lectivos` y
  `DELETE /periodos/:id/dias-no-lectivos/:dayId`; solo el administrador
  modifica y cada cambio queda auditado.

### F-21. Credenciales e impresión

- Entrada admin: `/credenciales`.
- API: `POST /credenciales/imprimibles` devuelve estudiantes activos del
  periodo, curso y token QR persistente.
- Si falta credencial principal, el backend la crea. La migración aplicada
  garantiza una sola principal activa por estudiante aun con concurrencia.
- Flutter filtra/selecciona estudiantes y genera localmente el PDF de anverso o
  anverso/reverso; reimprimir no cambia el QR.

### F-22. Resumen de reportes

- Entrada: `/reportes`, periodo diario/semanal/mensual, fecha y curso.
- API: `GET /reportes/resumen`.
- Salida: periodos considerados, cohorte histórica, puntuales, atrasos, total,
  días lectivos/no lectivos, asistencias esperadas, ausencias, registros no
  computados y porcentajes.
- Cada esperada corresponde a estudiante + fecha + jornada vigentes. Se
  consultan periodos activos o cerrados, se excluyen fines de semana y días no
  lectivos, y los traslados/retiros respetan su fecha efectiva.

### F-23. Exportación PDF de reportes

- API: `GET /reportes/exportar/pdf` con el mismo rango y curso.
- NestJS genera un PDF autenticado en memoria; Flutter lo descarga como bytes y
  lo guarda mediante `file_saver`.
- El PDF comparte la proyección histórica del resumen, lista solo registros
  computables y advierte si hubo marcas fuera de matrícula, jornada o día
  lectivo vigente.

### F-24. Salud y persistencia

- API pública: `GET /health`.
- Ejecuta `SELECT 1`; devuelve `200` con base disponible o `503` con base caída.
- PostgreSQL local usa 16 migraciones aplicadas. Las invariantes críticas de
  asistencia, credencial principal, rangos y versión están confirmadas en la
  base local.
- La semilla satisface el esquema completo en una base limpia (`AUD-002`
  cerrado).

## Inventario HTTP completo

Todas las rutas usan el prefijo `/api/v1`.

| Método y ruta | Roles | Propietario | Consumidor actual |
|---|---|---|---|
| `POST /autenticacion/iniciar-sesion` | Público | autenticacion | Login |
| `GET /autenticacion/sesion` | Sesión | autenticacion | Restauración |
| `POST /autenticacion/cerrar-sesion` | Sesión | autenticacion | Cierre |
| `POST /asistencias/escanear` | Admin/Regente | asistencias | Escáner |
| `POST /asistencias/manual` | Admin/Regente | asistencias | Ingreso manual |
| `GET /asistencias/jornadas` | Admin/Regente | asistencias | Selector operativo |
| `GET /asistencias/diaria` | Admin/Docente/Regente | asistencias | Panel y asistencia |
| `GET /estudiantes` | Admin/Docente | estudiantes | Gestión/credenciales indirectas |
| `GET /estudiantes/:id` | Admin/Docente | estudiantes | Sin llamada Flutter directa confirmada |
| `POST /estudiantes` | Admin | estudiantes | Gestión |
| `PATCH /estudiantes/:id` | Admin | estudiantes | Gestión |
| `DELETE /estudiantes/:id` | Admin | estudiantes | Gestión |
| `GET /estudiantes/:id/historial` | Admin/Docente | reportes | Historial |
| `GET /docentes` | Admin/Docente | docentes | Gestión |
| `GET /docentes/:id` | Admin/Docente | docentes | Sin llamada Flutter directa confirmada |
| `POST /docentes` | Admin | docentes | Gestión |
| `PATCH /docentes/:id` | Admin | docentes | Gestión |
| `DELETE /docentes/:id` | Admin | docentes | Gestión |
| `GET /cursos` | Admin/Docente/Regente | cursos | Cursos, filtros y estudiantes |
| `GET /cursos/:id` | Admin/Docente/Regente | cursos | Sin llamada Flutter directa confirmada |
| `GET /cursos/:id/horarios` | Admin/Docente/Regente | cursos | La lista principal ya incluye horarios |
| `POST /cursos` | Admin | cursos | Gestión |
| `PATCH /cursos/:id` | Admin | cursos | Gestión |
| `DELETE /cursos/:id` | Admin | cursos | Gestión |
| `POST /cursos/:id/horarios` | Admin | cursos | Horarios de ingreso |
| `PATCH /cursos/:id/horarios/:scheduleId` | Admin | cursos | Horarios de ingreso |
| `DELETE /cursos/:id/horarios/:scheduleId` | Admin | cursos | Horarios de ingreso |
| `GET /periodos/activo` | Admin/Docente | periodos | Sin consumidor Flutter directo confirmado |
| `GET /periodos/:id/dias-no-lectivos` | Admin/Docente | periodos | Resumen histórico indirecto |
| `POST /periodos/:id/dias-no-lectivos` | Admin | periodos | Administración API |
| `DELETE /periodos/:id/dias-no-lectivos/:dayId` | Admin | periodos | Administración API |
| `GET /horarios-clase` | Admin/Docente | horarios | API heredada, sin consumidor runtime actual |
| `GET /horarios-clase/planificador` | Admin/Docente | horarios | Planificador único |
| `PUT /horarios-clase/planificador` | Admin | horarios | Guardado batch |
| `PUT /horarios-clase/configuracion/general` | Admin | horarios | Jornada y recreos |
| `GET /materias` | Admin/Docente | horarios | Catálogo/planificador |
| `POST /materias` | Admin | horarios | Catálogo |
| `PATCH /materias/:id` | Admin | horarios | Catálogo |
| `DELETE /materias/:id` | Admin | horarios | Catálogo |
| `GET /aulas` | Admin/Docente | horarios | Catálogo/planificador |
| `POST /aulas` | Admin | horarios | Catálogo |
| `PATCH /aulas/:id` | Admin | horarios | Catálogo |
| `DELETE /aulas/:id` | Admin | horarios | Catálogo |
| `POST /credenciales/imprimibles` | Admin | credenciales | Impresión |
| `GET /reportes/resumen` | Admin/Docente | reportes | Reportes |
| `GET /reportes/exportar/pdf` | Admin/Docente | reportes | Exportación |
| `GET /health` | Público | salud | Operación/verificación |

## Flujos de entrega

- Android release: no está listo para distribución. Falta configurar firma de
  release; `pubspec.yaml` sigue en `1.0.0+1`.
- Windows: el EXE debe compilarse en Windows con la URL productiva y distribuir
  la carpeta Release completa.
- MSI: no está preparado; faltan `installer/` y
  `scripts/build_windows_msi.ps1`.
- Cámara real: queda pendiente validar Android físico y Windows.
- Flutter Web no forma parte del producto y no debe usarse para validar estos
  flujos.
