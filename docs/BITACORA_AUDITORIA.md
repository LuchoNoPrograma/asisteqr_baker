# Bitácora de auditoría

Última actualización: 2026-08-22 (America/La_Paz).

Esta bitácora es el registro de seguimiento de la auditoría transversal de
Flutter, API NestJS, Prisma y PostgreSQL. Los hallazgos permanecen abiertos
hasta que exista evidencia de corrección y verificación; que una prueba actual
pase no cierra un caso que esa prueba no cubre.

La cola ejecutable, orden de dependencias y contexto de relevo para continuar
las correcciones están en
[`BITACORA_SOLUCION_ISSUES.md`](BITACORA_SOLUCION_ISSUES.md).

## Convenciones de seguimiento

| Campo | Valores |
|---|---|
| Severidad | `Crítica`: impide entrega; `Alta`: puede corromper el flujo o bloquear al usuario; `Media`: resultado incorrecto o fragilidad acotada |
| Estado | `Abierto`, `En corrección`, `Listo para verificar`, `Cerrado`, `Aceptado` |
| Propietario | Módulo que debe resolver la causa, no necesariamente donde se observa |

Al actualizar un hallazgo se debe añadir una entrada al historial, conservar la
evidencia original e indicar la prueba o comprobación que evita su regresión.
La próxima revisión sugerida es 2026-08-29 o inmediatamente después de integrar
la consolidación actual del planificador, lo que ocurra primero.

## Resumen vivo

| Severidad | Abiertos | En corrección | Cerrados |
|---|---:|---:|---:|
| Crítica | 0 | 0 | 1 |
| Alta | 0 | 0 | 7 |
| Media | 0 | 0 | 10 |
| **Total** | **0** | **0** | **18** |

## Hallazgos

### AUD-001 — Registros simulados visibles en el escáner

- Severidad: **Crítica**.
- Estado: **Cerrado**.
- Propietario: Flutter, `features/attendance`.
- Evidencia: `lib/features/attendance/presentation/scanner_page.dart:629`
  construye dos asistencias con nombres, códigos, curso y hora locales fijos.
- Impacto: la interfaz rotulada como últimos registros muestra datos inventados
  durante la ejecución normal y puede hacer creer que se registraron alumnos
  reales. Contradice la regla de que los datos visibles proceden de la API.
- Corrección esperada: alimentar la sección desde un estado del view model/API
  o mostrar un estado vacío; no dejar filas de demostración en el widget.
- Criterio de cierre: inspección de la ruta normal sin datos simulados y prueba
  de mapeo/estado del repositorio si se incorpora una nueva respuesta API.
- Solución aplicada: `_RecentScans` ya no construye `AttendanceRecord` locales;
  presenta un estado vacío honesto y conserva el ingreso manual. No se modificó
  el contrato porque la solución no incorpora una respuesta API nueva.
- Evidencia de cierre: búsqueda sin coincidencias para nombres, códigos e IDs
  ficticios en `lib/` y `test/`; `flutter analyze` finalizó sin issues el
  2026-08-22.

### AUD-002 — La semilla no satisface el esquema migrado

- Severidad: **Alta**.
- Estado: **Cerrado**.
- Propietario: backend/Prisma, horarios.
- Evidencia: `prisma/seed.ts:215` crea un `HorarioClase` activo sin
  `asignacionId`; la migración
  `20260813120000_link_class_blocks_to_assignments/migration.sql:14` exige que
  todo bloque activo tenga una asignación.
- Impacto: una base creada desde cero puede aplicar migraciones y fallar al
  ejecutar la semilla. La base local evolucionada oculta el problema porque ya
  contiene una fila enlazada por la migración de backfill.
- Corrección esperada: crear/upsert primero la `AsignacionAcademica` canónica y
  enlazarla en las ramas `create` y `update` del bloque.
- Criterio de cierre: migraciones y semilla completas en una base de desarrollo
  descartable, sin usar `migrate reset` sobre la base actual.
- Solución aplicada: `prisma/seed.ts` crea/upsert primero la asignación
  canónica de 90 minutos semanales y usa su ID al crear o actualizar el bloque.
- Evidencia de cierre: schema válido, lint y build correctos; las 14 migraciones
  y la semilla completaron en un esquema temporal seleccionado mediante una URL
  Prisma separada, con cero bloques activos sin asignación. El esquema se
  eliminó al finalizar; no se modificó el esquema `public` actual.

### AUD-003 — Un 401 no cierra el estado de sesión de Flutter

- Severidad: **Alta**.
- Estado: **Cerrado**.
- Propietario: Flutter, autenticación/red/router.
- Evidencia: `lib/core/network/api_client.dart:15` borra el token ante `401`,
  pero no notifica a `SessionViewModel`; GoRouter sigue observando la sesión
  anterior.
- Impacto: una sesión expirada o revocada puede dejar al usuario dentro de la
  aplicación, recibiendo errores repetidos, sin redirección confiable a acceso.
- Corrección esperada: un único evento de sesión inválida que limpie el token,
  actualice el view model y refresque el router sin bucles.
- Criterio de cierre: prueba de integración del estado de sesión al recibir un
  `401` desde un endpoint protegido.
- Solución aplicada: un `SessionInvalidationNotifier` inyectado conecta el
  interceptor con `SessionViewModel`; el `401` protegido elimina el token de la
  solicitud, pasa la sesión a `signedOut` y refresca el router. La generación de
  invalidación protege restauraciones obsoletas y tokens nuevos.
- Evidencia de cierre: las pruebas focalizadas verifican token vacío, usuario y
  estado cerrados, y que un `401` tardío no borra otra sesión; `flutter analyze`
  finalizó sin issues.

### AUD-004 — Rol principal no determinista para usuarios multirrol

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: backend/autenticación y contrato Flutter.
- Evidencia: `src/modulos/autenticacion/infraestructura/auth.service.ts:132`
  devuelve `roles[0]` sin orden o prioridad contractual.
- Impacto: un administrador que también sea docente puede aparecer como
  `DOCENTE` en Flutter y perder comandos administrativos, aunque el backend
  conozca ambos roles.
- Corrección esperada: definir prioridad estable o devolver la colección de
  roles y hacer que el cliente evalúe capacidades.
- Criterio de cierre: caso automatizado de un usuario con ambos roles.
- Solución aplicada: `AuthService` centraliza una prioridad determinista
  `ADMINISTRADOR > DOCENTE` para login y restauración, conservando el contrato
  `rol` existente.
- Evidencia de cierre: spec con roles recibidos en orden
  `DOCENTE, ADMINISTRADOR` devuelve administrador en ambas respuestas; lint y
  build backend correctos.

### AUD-005 — Los errores 400 de asistencia se presentan como credencial inactiva

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: Flutter, repositorio de asistencia.
- Evidencia: `lib/features/attendance/data/api_attendance_repository.dart:203`
  traduce cualquier `400` a `inactiveStudent`; la vista lo rotula como
  `Credencial inactiva`.
- Impacto: faltas de inscripción, curso, horario o configuración se diagnostican
  de forma incorrecta y dificultan la operación.
- Corrección esperada: contrato de códigos de error estable y mapeo específico,
  conservando el mensaje seguro del backend.
- Criterio de cierre: pruebas de mapeo para cada causa funcional de `400`.
- Solución aplicada: el backend devuelve códigos estables para QR inválido,
  estudiante inexistente/inactivo, inscripción, horario o configuración
  ausentes. Flutter mapea primero el código y muestra una causa específica; un
  `400` desconocido queda como error desconocido, no como estudiante inactivo.
- Evidencia de cierre: 8 pruebas de `AttendanceService` y 9 pruebas enfocadas
  Flutter correctas; lint/build backend y `flutter analyze` sin issues.

### AUD-006 — Asistencia ambigua con varias jornadas activas

- Severidad: **Alta**.
- Estado: **Cerrado**.
- Propietario: negocio/API de asistencia y horarios de ingreso.
- Evidencia: `attendance.service.ts:19` ordena horarios por jornada y usa
  `take: 1`; escaneo/manual no reciben jornada. `attendance.service.ts:277`
  reduce los registros diarios a uno por estudiante.
- Impacto: un curso admite mañana, tarde y noche, pero el registro puede usar el
  límite equivocado y la vista diaria puede descartar registros válidos.
- Corrección esperada: declarar la regla de selección por franja/hora o exigir
  jornada/punto de control, y modelar la identidad diaria con el horario.
- Criterio de cierre: casos de puntualidad, atraso y duplicado con dos jornadas
  activas para el mismo curso.
- Corrección aplicada: QR/manual exigen la jornada y resuelven el horario activo
  correspondiente; la unicidad sigue siendo estudiante+horario+fecha. La
  proyección diaria genera una fila por horario y admite filtro de jornada.
  `REGENTE` opera escaneo/manual y `DOCENTE` queda en consulta.
- Evidencia de cierre: casos de puntual, atraso, duplicado, jornada inexistente
  y dos horarios activos entre 16 pruebas backend; payload, filtro, selección y
  proyección cubiertos entre 12 pruebas Flutter. Lint, build, Prisma y analyze
  correctos.

### AUD-007 — Los ausentes reciben una hora ficticia en Flutter

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: contrato y presentación de asistencia.
- Evidencia: la API devuelve `fechaHora: null` para ausentes en
  `attendance.service.ts:290`; Flutter lo reemplaza por `DateTime.now()` en
  `api_attendance_repository.dart:154`.
- Impacto: tablas y tarjetas pueden mostrar una hora real para una asistencia
  que nunca ocurrió.
- Corrección esperada: timestamp nullable o una representación de fila diaria
  distinta del registro de asistencia; la UI debe mostrar `—` para ausentes.
- Criterio de cierre: prueba de mapeo de ausencia sin timestamp.
- Corrección aplicada: `AttendanceRecord.timestamp` es nullable; repositorio y
  UI conservan la ausencia sin fabricar una hora.
- Evidencia de cierre: prueba de mapeo por jornada y `flutter analyze`
  correctos.

### AUD-008 — “Actividad reciente” no está ordenada por hora

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: Flutter/dashboard o endpoint dedicado.
- Evidencia: `api_attendance_repository.dart:46` toma los primeros cinco
  presentes; la API diaria llega ordenada por curso y apellido en
  `attendance.service.ts:269`.
- Impacto: el panel etiqueta como recientes registros que no necesariamente son
  los últimos cinco.
- Corrección esperada: ordenar descendentemente por `fechaHora` o crear una
  proyección backend explícita.
- Criterio de cierre: prueba con horas desordenadas respecto al apellido.
- Corrección aplicada: el dashboard ordena los presentes por timestamp
  descendente antes de tomar cinco.
- Evidencia de cierre: caso de orden temporal contrario al orden de respuesta y
  `flutter analyze` correctos.

### AUD-009 — PATCH de estado evita las reglas de baja

- Severidad: **Alta**.
- Estado: **Cerrado**.
- Propietario: backend, estudiantes/docentes.
- Evidencia: los DTO de actualización exponen `estado`; en estudiantes,
  `students.service.ts:125` lo aplica directamente, mientras el retiro de
  `students.service.ts:208` también retira inscripciones y revoca credenciales.
  Docentes presenta el mismo bypass en `teachers.service.ts:99`.
- Impacto: un cliente de API puede producir un estudiante retirado con
  inscripción/QR activos o cambiar el estado de un docente sin una política de
  planificación consistente.
- Corrección esperada: quitar estado del PATCH general o encaminar toda
  transición por comandos transaccionales con sus invariantes.
- Criterio de cierre: pruebas que demuestren los efectos laterales de cada
  transición permitida.
- Corrección aplicada: los PATCH generales ya no admiten `estado`/`activo` y
  esos campos se rechazan con `400`. El comando DELETE de estudiante retira en
  una transacción serializable estudiante, matrículas y QR activos, y audita.
- Evidencia de cierre: tres casos del borde de validación y caso transaccional
  de estudiante dentro de 29 pruebas backend; lint y build correctos.

### AUD-010 — Bajas de docente/curso dejan planificación activa inconsistente

- Severidad: **Alta**.
- Estado: **Cerrado**.
- Propietario: backend, docentes/cursos/horarios.
- Evidencia: `teachers.service.ts:146` solo inactiva al docente;
  `courses.service.ts:162` solo inactiva curso y horarios de ingreso. El
  planificador filtra catálogos activos pero conserva asignaciones y bloques
  activos que los referencian.
- Impacto: la proyección puede contener IDs sin su catálogo, fallar en
  `firstWhere`, o quedar imposible de volver a guardar.
- Corrección esperada: impedir la baja mientras existan referencias activas o
  realizar una baja lógica transaccional coherente de toda la planificación.
- Criterio de cierre: pruebas de baja con y sin referencias activas y carga
  posterior del planificador.
- Corrección aplicada: docente responde
  `409 DOCENTE_CON_PLANIFICACION_ACTIVA` ante asignaciones/bloques; curso responde
  `409 CURSO_CON_DEPENDENCIAS_ACTIVAS` ante matrículas, asignaciones o bloques.
  Ambos incluyen conteos y no mutan ni auditan el rechazo.
- Evidencia de cierre: casos con/sin dependencias y suite del planificador entre
  29 pruebas backend; 14 pruebas Flutter confirman mensaje y estado local;
  lint/build/Prisma/analyze correctos.

### AUD-011 — Guardado confirmado puede informarse como fallido al recargar

- Severidad: **Alta**.
- Estado: **Cerrado**.
- Propietario: Flutter, view model del planificador.
- Evidencia: `schedule_planner_view_model.dart:308` ejecuta PUT y luego GET en
  el mismo `try`; `saveGeneralConfig` repite el patrón en la línea 382.
- Impacto: si el PUT confirma pero la recarga falla, el método devuelve fallo,
  conserva el borrador/version anterior y un reintento obtiene conflicto aunque
  el servidor sí guardó.
- Corrección esperada: distinguir `commit` de `refresh`, aplicar la versión
  devuelta y ofrecer una recarga recuperable sin reintentar el comando.
- Criterio de cierre: prueba donde PUT responde éxito y el GET posterior falla.
- Solución aplicada: matriz y configuración aplican la versión confirmada antes
  del GET. Si la recarga falla, el borrador pasa a confirmado, se bloquea la
  edición pendiente de IDs y la UI permite reintentar solo el GET.
- Evidencia de cierre: pruebas focalizadas de PUT exitoso + GET fallido
  comprueban versión nueva, `dirty` limpio, una sola llamada de guardado y
  recarga posterior correcta; `flutter analyze` no presenta issues.

### AUD-012 — Turnos fijos pueden dejar la matriz sin rango válido

- Severidad: **Alta**.
- Estado: **Cerrado**.
- Propietario: Flutter, planificador responsive.
- Evidencia: `teaching_schedules_page.dart:40` fija 07:30–13:30 y 14:00–20:00,
  aunque el backend admite otra jornada. En la línea 1675, `slots` puede ser
  cero o negativo; el alta móvil de la línea 674 usa el inicio fijo sin
  ajustarlo a la configuración.
- Impacto: una configuración válida como 06:00–07:00 o 20:00–21:00 puede causar
  dimensiones/índices inválidos o un valor de formulario fuera de sus opciones.
- Corrección esperada: derivar segmentos de la configuración y representar de
  forma segura un turno sin intersección.
- Criterio de cierre: comprobación a 320/390/1280 px con jornadas antes, entre y
  después de los turnos actuales; por regla del proyecto, sin añadir tests UI.
- Solución aplicada: los tramos visibles se derivan de la jornada API y se
  dividen en un corte alineado cercano a las 14:00. Selectores, matriz, agenda y
  altas usan únicamente intersecciones válidas y omiten tramos vacíos.
- Evidencia de cierre: inspección de jornadas 06:00–07:00, 07:30–20:00 y
  20:00–21:00 sin slots nulos/negativos; `flutter analyze` finalizó sin issues.
  La validación física de viewports continúa registrada en OPS-004.

### AUD-013 — Cambio de jornada no valida alineación de bloques existentes

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: backend/horarios.
- Evidencia: `teaching-schedules.service.ts:547` comprueba rango y recreos, pero
  no que inicio/fin de cada bloque sean múltiplos del intervalo respecto al
  nuevo inicio.
- Impacto: una jornada desplazada puede aceptar bloques fuera de grilla y el
  siguiente guardado del planificador rechazarlos.
- Corrección esperada: reutilizar la misma validación de alineación del batch
  antes de guardar la configuración.
- Criterio de cierre: prueba de cambio de 07:30 a 07:45 con bloques a media hora.
- Solución aplicada: configuración y batch comparten la regla de alineación
  respecto del inicio/intervalo. Una jornada nueva que desalinee una clase
  responde `CONFIGURACION_AFECTA_CLASES` antes de persistir.
- Evidencia de cierre: el caso `07:45–13:45` con bloque `08:00–09:00` se
  rechaza, `07:30–13:30` se acepta; suite enfocada de 20 pruebas, lint y build
  backend correctos.

### AUD-014 — Payload batch admite instrucciones contradictorias

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: backend/horarios.
- Evidencia: `save-schedule-planner.dto.ts:55` permite días 1–7 aunque la base
  restringe 1–5; `teaching-schedules.service.ts:360` actualiza/reactiva y da de
  baja listas en el mismo `Promise.all` sin rechazar IDs repetidos o presentes
  a la vez en estado y eliminados.
- Impacto: resultado dependiente del orden/concurrencia o error de base
  presentado como `500`, en vez de un `400` determinista.
- Corrección esperada: validar lunes-viernes, unicidad y disjunción de IDs antes
  de abrir el diff transaccional.
- Criterio de cierre: pruebas negativas de fin de semana, duplicados y cruce
  activo/eliminado.
- Solución aplicada: el DTO acepta solo días `1..5`; antes de `$transaction`, el
  servicio exige IDs únicos y disjuntos en asignaciones/bloques activos y
  eliminados, con código `PAYLOAD_PLANIFICADOR_CONTRADICTORIO`.
- Evidencia de cierre: pruebas para días `0`, `6`, `7`, duplicados en las cuatro
  listas y ambos cruces activo/eliminado. Los seis payloads contradictorios no
  invocan la transacción; suite de 20 pruebas, lint y build correctos.

### AUD-015 — IDs y fechas de URL no se validan completamente

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: backend transversal.
- Evidencia: los controllers reciben UUID con `@Param`/`@Query` como strings sin
  `ParseUUIDPipe` o DTO. Asistencia usa regex más `new Date` en
  `attendance.service.ts:256`; JavaScript normaliza `2026-02-31` a marzo.
- Impacto: entradas inválidas pueden llegar a Prisma/PostgreSQL o consultar una
  fecha distinta de la escrita, produciendo errores internos o resultados
  sorprendentes.
- Corrección esperada: pipes/DTO para UUID y parseo de calendario estricto con
  Luxon antes del repositorio.
- Criterio de cierre: matriz de 400 para UUID inválido y fechas 29/30/31 no
  existentes en asistencia, reportes e historial.
- Solución aplicada: pipes compartidos UUID v4 obligatorios/opcionales protegen
  todos los params y filtros de IDs inventariados. `parseCalendarDate` usa
  Luxon con formato exacto y comprobación canónica; asistencia, resumen, PDF e
  historial validan antes de Prisma, incluido el rango invertido del historial.
- Evidencia de cierre: 24 pruebas enfocadas cubren UUID inválidos, filtros
  opcionales, días inexistentes `29/30/31`, formato no canónico, año bisiesto,
  rango invertido y ausencia de consultas ante error. El inventario final de
  controllers no dejó IDs conocidos sin pipe; lint, build y `git diff --check`
  finalizaron correctamente.

### AUD-016 — Limpiar filtros puede desincronizar estado y selector

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: Flutter, `AppDataTable`.
- Evidencia: `app_data_table.dart:229` usa una key estable e `initialValue` para
  el dropdown. Al limpiar se cambia `_selectedFilters`, pero el estado interno
  del campo puede conservar visualmente la opción anterior.
- Impacto: la tabla queda sin filtro mientras el control aún aparenta filtrar.
- Corrección esperada: selector controlado o key que cambie con el valor.
- Criterio de cierre: comprobación manual de limpiar búsqueda/filtros en las
  cuatro tablas compartidas; no añadir pruebas de widget por regla del repo.
- Solución aplicada: la key interna del `DropdownButtonFormField` incorpora el
  índice seleccionado o `all`, por lo que seleccionar/limpiar recrea el campo
  con el mismo valor que `_selectedFilters`. El wrapper conserva la key pública
  usada por el componente compartido.
- Evidencia de cierre: inspección del ciclo de identidad en el único
  `AppDataTable` consumido por las cuatro tablas y `flutter analyze` sin issues.
  No se crearon ni ejecutaron pruebas widget por regla del repositorio; la
  validación física general permanece en OPS-004.

### AUD-017 — Resumen histórico usa la matrícula activa actual

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: negocio/reportes y modelo de matrícula.
- Evidencia: `reports.service.ts:30` cuenta inscripciones activas del periodo
  activo actual y multiplica por lunes-viernes del rango solicitado.
- Impacto: periodos históricos, altas/retiros dentro del rango, feriados o
  cambios de curso producen esperados, ausencias y porcentajes inexactos.
- Corrección esperada: acordar la regla de negocio histórica y contar la cohorte
  vigente por fecha, junto con un calendario académico si los feriados cuentan.
- Criterio de cierre: ejemplos de aceptación con ingreso/retiro a mitad de rango
  y consulta de un periodo no activo.
- Solución aplicada: matrícula y horarios de ingreso conservan vigencia
  `[desde, hasta)` y los días no lectivos se almacenan por periodo. Reportes
  proyecta cada unidad estudiante-fecha-jornada sobre periodos activos o
  cerrados, excluye fines de semana/excepciones y publica los registros fuera
  de esa proyección como `registrosNoComputados`. El PDF y la planilla diaria
  usan la misma semántica.
- Evidencia de cierre: el fixture del 3 al 7 de agosto, con miércoles no
  lectivo, produce 4 esperadas para un estudiante vigente toda la semana, 2
  para un alta del miércoles y 2 para un retiro efectivo el jueves: 8 en total.
  También se cubren periodo `CERRADO`, traslado de curso y segunda jornada. Las
  78 pruebas backend, 3 pruebas Flutter, lint, build, Prisma, migración local y
  `flutter analyze` finalizaron correctamente.
- Riesgo residual: el backfill no puede reconstruir fechas históricas que el
  esquema anterior nunca almacenó. En la base local no existían matrículas
  retiradas; todas las transiciones posteriores quedan fechadas.

### AUD-018 — Respuestas antiguas pueden sobrescribir filtros recientes

- Severidad: **Media**.
- Estado: **Cerrado**.
- Propietario: Flutter, view models de reportes y gestión.
- Evidencia: las cargas asíncronas de reportes, estudiantes, docentes y cursos
  no usan cancelación ni número de generación antes de asignar el resultado.
- Impacto: al cambiar rápidamente curso/fecha/búsqueda, una respuesta lenta de
  la selección anterior puede reemplazar el estado correcto.
- Corrección esperada: cancelar solicitudes o descartar resultados cuyo token
  de carga ya no sea el vigente.
- Criterio de cierre: prueba de unidad con dos futures resueltos en orden inverso
  para cada view model que acepte filtros mutables.
- Solución aplicada: los view models de reportes, estudiantes, docentes y cursos
  asignan una generación a cada carga y solo la vigente puede publicar datos,
  errores o finalizar `loading`. Las búsquedas con debounce y `dispose`
  invalidan inmediatamente las cargas reemplazadas.
- Evidencia de cierre: cuatro casos nuevos resuelven dos `Future` en orden
  inverso y comprueban que el resultado o error obsoleto no sustituye al
  vigente. Las 12 pruebas de las tres suites focalizadas y `flutter analyze`
  finalizaron correctamente.

## Brechas operativas bajo seguimiento

Estas brechas no son fallos de lógica del runtime y no forman parte del conteo
de 18 hallazgos, pero impiden declarar una entrega terminada:

| ID | Estado | Evidencia / siguiente paso |
|---|---|---|
| OPS-001 | Abierto | Android no tiene `signingConfigs.release`; configurar firma local antes de distribuir APK. |
| OPS-002 | Abierto | No existen `installer/` ni `scripts/build_windows_msi.ps1`; preparar y validar MSI exclusivamente en Windows. |
| OPS-003 | Abierto | `pubspec.yaml` está en `1.0.0+1`; incrementar antes de cualquier entrega. |
| OPS-004 | Abierto | Falta validar cámaras en Android físico y Windows, y responsive 320/390 px con texto al 130 %. |
| OPS-005 | Abierto | `FRONTEND_PLAN.md` local quedó desfasado respecto a la consolidación del planificador; actualizarlo después de integrar el trabajo actual. |
| OPS-006 | Abierto | El script `test:e2e` del backend referencia una configuración ausente; restaurar cobertura E2E reproducible. |

## Historial

| Fecha | Cambio | Evidencia |
|---|---|---|
| 2026-08-22 | Se cierra AUD-017 con vigencia de matrícula/horario, calendario académico y cálculo por estudiante-fecha-jornada. Quedan cerrados los 18 hallazgos. | 78 pruebas backend, 3 Flutter, lint/build/Prisma/migración/analyze y consulta local correctos. |
| 2026-08-22 | Se cierran AUD-009 y AUD-010 con transiciones explícitas y rechazo `409` de bajas académicas inconsistentes. | 29 pruebas backend, 14 Flutter y lint/build/Prisma/analyze correctos. |
| 2026-08-22 | Se cierran AUD-006, AUD-007 y AUD-008 con asistencia por jornada operada por regente y proyecciones temporales honestas. | 16 pruebas backend, 12 Flutter, lint/build/Prisma/analyze correctos. |
| 2026-08-22 | Se cierra AUD-018 descartando generaciones de carga reemplazadas en los cuatro view models afectados. | 12 pruebas enfocadas con resolución inversa y `flutter analyze` correctos. |
| 2026-08-22 | Se cierra AUD-015 validando UUID v4 y fechas calendario exactas en el borde. | 24 pruebas enfocadas, inventario de controllers, lint, build y diff-check correctos. |
| 2026-08-22 | Se cierra AUD-016 sincronizando la identidad visual del filtro compartido. | Cambio único en `AppDataTable` y `flutter analyze` correcto; sin tests UI por regla del repo. |
| 2026-08-22 | Se cierran AUD-013 y AUD-014 endureciendo configuración y diff del planificador. | 20 pruebas enfocadas; jornada desalineada, días no hábiles y payloads contradictorios cubiertos; lint/build correctos. |
| 2026-08-22 | Se cierra AUD-005 con códigos funcionales estables de asistencia. | 8 pruebas backend y 9 Flutter correctas; lint, build y analyze correctos. |
| 2026-08-22 | Se cierra AUD-004 con prioridad multirrol determinista. | 2 pruebas de AuthService correctas; lint y build backend correctos. |
| 2026-08-22 | Se cierra AUD-012 derivando los tramos visibles de la jornada API. | Casos de borde inspeccionados y `flutter analyze` sin issues; validación física pendiente en OPS-004. |
| 2026-08-22 | Se cierra AUD-011 separando commit confirmado y recarga recuperable. | 15 pruebas focalizadas correctas y `flutter analyze` sin issues. |
| 2026-08-22 | Se cierra AUD-003 propagando `401` desde red hasta sesión/GoRouter. | 3 pruebas focalizadas correctas y `flutter analyze` sin issues. |
| 2026-08-22 | Se cierra AUD-002 enlazando la semilla con su asignación académica canónica. | Prisma válido, lint/build correctos, migraciones+semilla en esquema temporal y cero bloques activos sin asignación. |
| 2026-08-22 | Se cierra AUD-001 retirando los registros simulados del escáner. | Estado vacío explícito en `scanner_page.dart`, búsqueda de datos ficticios sin coincidencias y `flutter analyze` correcto. |
| 2026-08-22 | Se crea la línea base con 18 hallazgos y 6 brechas operativas. | Auditoría estática, pruebas enfocadas, Prisma y base local; ver `ESTADO_AUDITORIA_2026-08-22.md`. |
