# Bitácora de solución de issues

Última actualización: 2026-08-22 (America/La_Paz).

## Propósito

Este documento es el punto de entrada para el agente o LLM que continúe la
corrección de la auditoría. Resume el contexto que no conviene redescubrir,
convierte cada hallazgo en una tarea verificable y conserva el orden de
dependencias. Los 18 hallazgos de auditoría están cerrados; permanecen aparte
las brechas operativas de entrega `OPS-001` a `OPS-006`.

La evidencia extensa está en [`BITACORA_AUDITORIA.md`](BITACORA_AUDITORIA.md),
el dictamen y las validaciones de línea base en
[`ESTADO_AUDITORIA_2026-08-22.md`](ESTADO_AUDITORIA_2026-08-22.md), y los
recorridos funcionales en [`FLUJOS_FUNCIONALES.md`](FLUJOS_FUNCIONALES.md).

## Lectura obligatoria para retomar el trabajo

1. Leer `AGENTS.md` completo.
2. Leer `README.md` y el `FRONTEND_PLAN.md` local si continúa disponible.
3. Leer esta bitácora y luego el detalle del issue en
   `docs/BITACORA_AUDITORIA.md`.
4. Revisar `git status` y `git diff` en Flutter y backend antes de editar.
5. Si el cambio puede tocar API, autenticación, roles, Prisma o PostgreSQL,
   ejecutar primero `asisteqr-baker-backend-router` y después la skill que este
   indique. Para una corrección transversal usar
   `asisteqr-baker-feature-integral`; para Flutter puro,
   `asisteqr-baker-flutter-mvvm`; para QR/cámara/asistencia,
   `asisteqr-baker-qr-multiplataforma`.
6. Usar primero el grafo MCP de codebase-memory si está disponible. No lo estaba
   durante la auditoría y el directorio local no contenía un índice utilizable.

## Estado del árbol recibido

- Flutter: rama `master`, base observada `a37a913`.
- Backend: rama `master`, base observada `4ae0130` en
  `/home/nini/IdeaProjects/asisteqr_baker_backend`.
- Antes de crear la documentación de auditoría ya existían 23 entradas locales
  en Flutter y 5 en backend. Son trabajo del usuario y no deben revertirse.
- El cambio local principal consolida el planificador general y el horario
  contextual de docente. Incluye archivos modificados/eliminados y pruebas
  ajustadas en ambos repositorios.
- Los únicos cambios introducidos por la auditoría están en `README.md`,
  `docs/DIAGRAMA_CASOS_DE_USO.md` y los documentos `docs/*AUDITORIA*`,
  `docs/FLUJOS_FUNCIONALES.md` y esta bitácora.

No asumir que el último commit representa el código auditado: la línea base es
el árbol de trabajo sucio descrito arriba. Si el usuario integra o cambia ese
trabajo, volver a contrastar líneas y actualizar la evidencia.

## Reglas que no se deben romper

- No ejecutar, servir, compilar ni validar Flutter Web.
- No compilar Flutter solo para comprobar correcciones. Para cambios de UI usar
  `flutter analyze`; compilar únicamente por pedido o para un artefacto.
- No crear ni ejecutar pruebas de UI, widgets, responsive, navegación o textos.
- Crear y ejecutar pruebas enfocadas cuando se cambie repositorio, mapeo,
  transacción, migración o guardado.
- No ejecutar `prisma migrate reset` sin solicitud o aprobación explícita.
- No iniciar PostgreSQL en Docker ni copiar credenciales del `.env`.
- La interfaz normal siempre consume repositorios API; no introducir un selector
  de mocks ni datos simulados dentro de widgets.
- Las bajas son lógicas y el planificador se guarda con un único batch y una
  única transacción. No convertirlo en peticiones por celda.
- Usar `apply_patch` para ediciones manuales y preservar cambios ajenos.

## Definición de terminado para cada issue

Un issue solo pasa a `Cerrado` cuando se cumplen todos estos puntos:

- la causa, no solo el síntoma visual, fue corregida;
- existen pruebas de lógica/persistencia cuando las reglas del repositorio las
  permiten y exigen;
- se ejecutaron las validaciones específicas indicadas en esta bitácora;
- `flutter analyze` y/o lint/build backend pasan según las capas tocadas;
- se comprobó que el diff no mezcla ni revierte cambios ajenos;
- se actualizan el estado, fecha, solución aplicada y evidencia en esta
  bitácora y en `BITACORA_AUDITORIA.md`.

Estados permitidos: `Pendiente`, `En curso`, `Bloqueado por decisión`,
`Listo para verificar`, `Cerrado` y `Aceptado por negocio`.

## Orden recomendado

| Fase | Objetivo | Issues | Motivo |
|---|---|---|---|
| 0 | Quitar bloqueo visible | AUD-001 | Hay datos simulados presentados como reales. |
| 1 | Recuperar invariantes críticas | AUD-002, AUD-003, AUD-009, AUD-010, AUD-011, AUD-012 | Pueden bloquear usuario, bootstrap o planificador. |
| 2 | Resolver decisión de jornada | AUD-006 | Cambia contrato, unicidad y significado de asistencia diaria. |
| 3 | Corregir exactitud de datos | AUD-004, AUD-005, AUD-007, AUD-008, AUD-013, AUD-014, AUD-015 | Evita resultados engañosos y errores no controlados. |
| 4 | Robustecer interacción y reportes | AUD-016, AUD-017, AUD-018 | Requiere validación funcional y, en reportes, decisión de negocio. |
| 5 | Preparar entrega | OPS-001 a OPS-006 | Solo después de estabilizar runtime y contrato. |

AUD-001, AUD-002 y AUD-003 pueden trabajarse de forma independiente. AUD-009 y
AUD-010 deben diseñarse juntos. AUD-006 debe resolverse antes de cerrar AUD-007
y antes de afirmar que el dashboard representa correctamente el día.

### Vista rápida de soluciones

| Trabajo | Auditoría | Estado | Próxima acción |
|---|---|---|---|
| SOL-001 | AUD-001 | Cerrado | Estado vacío honesto; sin filas simuladas. |
| SOL-002 | AUD-002 | Cerrado | Semilla enlaza asignación antes del bloque. |
| SOL-003 | AUD-003 | Cerrado | `401` invalida token, sesión y router. |
| SOL-004 | AUD-009, AUD-010 | Cerrado | Transiciones explícitas y `409` ante dependencias externas activas. |
| SOL-005 | AUD-011 | Cerrado | Commit confirmado y recarga recuperable. |
| SOL-006 | AUD-012 | Cerrado | Segmentos derivados de la jornada API. |
| SOL-007 | AUD-006 | Cerrado | Una marca por estudiante, fecha y jornada; opera el regente. |
| SOL-008 | AUD-004 | Cerrado | Prioridad estable ADMINISTRADOR > DOCENTE. |
| SOL-009 | AUD-005 | Cerrado | Códigos estables mapeados de backend a UI. |
| SOL-010 | AUD-007 | Cerrado | Ausencia con timestamp nullable y presentación sin hora. |
| SOL-011 | AUD-008 | Cerrado | Presentes recientes ordenados por hora descendente. |
| SOL-012 | AUD-013 | Cerrado | Configuración valida rango y alineación existente. |
| SOL-013 | AUD-014 | Cerrado | DTO hábil y diff único/disjunto antes de transacción. |
| SOL-014 | AUD-015 | Cerrado | UUID v4 en el borde y fechas sin rollover. |
| SOL-015 | AUD-016 | Cerrado | Selector se recrea al cambiar su valor real. |
| SOL-016 | AUD-017 | Cerrado | Cohorte, jornadas y calendario proyectados por fecha efectiva. |
| SOL-017 | AUD-018 | Cerrado | Solo la generación de carga vigente publica estado. |

### Punto de relevo actual

- Último cierre completado: SOL-016/AUD-017. El resumen y el PDF proyectan por
  fecha la matrícula, el curso, la jornada y el calendario académico, incluso
  para periodos cerrados.
- Los 18 hallazgos de auditoría están cerrados y no queda relevo funcional en
  esta cola.
- La siguiente etapa es operativa: firma APK, infraestructura MSI, versión,
  validación física/responsive y restauración E2E (`OPS-001` a `OPS-006`).

## Cola de solución

### SOL-001 / AUD-001 — Eliminar asistencias simuladas del escáner

- Prioridad: **P0**.
- Estado: **Cerrado**.
- Skill sugerida: `asisteqr-baker-qr-multiplataforma`.
- Bug breve: `_RecentScans` crea localmente a “García, Carlos” y “Martínez,
  Ana” con `DateTime.now()`; no vienen del repositorio.
- Archivos iniciales: `lib/features/attendance/presentation/scanner_page.dart`
  y, solo si se decide cargar recientes reales, view model/repositorio de
  asistencia y contrato backend.
- Solución mínima segura: quitar las filas y mostrar un estado vacío honesto.
- Solución funcional completa: exponer registros recientes reales en el estado
  del escáner mediante repositorio API. No reutilizar datos mock.
- Validación: buscar que no queden los nombres/códigos simulados y ejecutar
  `flutter analyze`. Si cambia repositorio/mapeo, añadir y ejecutar prueba de
  unidad enfocada.
- Dependencia/decisión: ninguna para la solución mínima.

Solución aplicada:

- Se eliminaron los dos `AttendanceRecord` construidos dentro de
  `_RecentScans` y sus datos ficticios.
- La sección conserva el acceso al ingreso manual y ahora muestra un estado
  vacío que remite a la vista de Asistencia para consultar registros reales.

Decisiones tomadas:

- Se aplicó la solución mínima segura; no se amplió el contrato HTTP ni se
  duplicó en el escáner la carga disponible en la vista de Asistencia.

Archivos modificados:

- `lib/features/attendance/presentation/scanner_page.dart`.

Pruebas/comprobaciones:

- Búsqueda sin coincidencias para los nombres, códigos e IDs simulados en
  `lib/` y `test/`.
- `dart format lib/features/attendance/presentation/scanner_page.dart`.
- `flutter analyze`: sin issues.

Riesgo residual:

- La sección no presenta actividad reciente en vivo; es deliberado hasta que
  exista un contrato API específico y no afecta el registro QR/manual.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-002 / AUD-002 — Hacer reproducible la semilla con el esquema actual

- Prioridad: **P1**.
- Estado: **Cerrado**.
- Skills: primero `asisteqr-baker-backend-router`, después
  `asisteqr-baker-backend-prisma`.
- Bug breve: `prisma/seed.ts` crea un bloque activo sin `asignacionId`, pero el
  CHECK aplicado exige una asignación para todo bloque activo.
- Archivos iniciales: backend `prisma/seed.ts`, `prisma/schema.prisma` y
  migración `20260813120000_link_class_blocks_to_assignments`.
- Solución propuesta: upsert de la `AsignacionAcademica` canónica antes del
  `HorarioClase` y uso de su ID en `create` y `update`. Mantener minutos
  semanales divisibles por 30.
- Validación: `prisma validate`, lint, build y ejecución de migraciones+semilla
  en una base local descartable con URL separada. No tocar ni resetear la base
  `sistema-educativo-baker` actual sin aprobación.

Solución aplicada:

- La semilla hace `upsert` de la `AsignacionAcademica` canónica de Matemática
  antes de crear o actualizar el bloque.
- El bloque enlaza `asignacionId` tanto en `create` como en `update`; la carga
  semanal queda en 90 minutos, alineada a intervalos de 30 minutos.

Decisiones tomadas:

- No se cambió schema, migraciones ni contrato HTTP porque la invariante ya
  estaba modelada y aplicada; el defecto estaba únicamente en la semilla.
- Como el rol PostgreSQL no permite `CREATE DATABASE`, la prueba reproducible
  usó una URL Prisma separada hacia un esquema temporal aislado. El esquema fue
  eliminado al finalizar sin tocar tablas ni datos de `public`.

Archivos modificados:

- Backend: `prisma/seed.ts`.

Pruebas/comprobaciones:

- `npx --no-install prisma validate`: schema válido.
- `npm run lint -- --no-fix`: correcto.
- `npx --no-install nest build`: correcto.
- Las 14 migraciones y `prisma/seed.ts` completaron en un esquema temporal.
- Consulta de integridad temporal: cero bloques activos sin `asignacion_id`.
- El esquema temporal se eliminó con `DROP SCHEMA ... CASCADE` al terminar.

Riesgo residual:

- No se probó `CREATE DATABASE` porque el rol local carece de ese privilegio;
  el aislamiento por esquema ejercitó las mismas migraciones, semilla y CHECK.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-003 / AUD-003 — Propagar sesión inválida desde red hasta GoRouter

- Prioridad: **P1**.
- Estado: **Cerrado**.
- Skill: `asisteqr-baker-flutter-mvvm`.
- Bug breve: `ApiClient` borra el token al recibir `401`, pero
  `SessionViewModel` y el router siguen en `signedIn`.
- Archivos iniciales: `lib/core/network/api_client.dart`, providers, auth view
  model y router.
- Solución propuesta: un coordinador/listenable de invalidación de sesión
  inyectado por providers. El interceptor emite una única invalidación y el view
  model transiciona a sesión cerrada; evitar dependencias circulares y múltiples
  redirecciones concurrentes.
- Validación: prueba no visual donde un endpoint protegido responde `401`, el
  token queda vacío y el estado observable pasa a cerrado. Ejecutar
  `flutter analyze`.

Solución aplicada:

- Se agregó `SessionInvalidationNotifier` como dependencia compartida entre
  `ApiClient` y `SessionViewModel` mediante Riverpod.
- Ante `401` de una ruta protegida, el interceptor borra únicamente el token que
  acompañó esa solicitud y emite una sola invalidación; el view model pasa a
  `signedOut`, limpia el usuario y notifica al `GoRouter` ya conectado mediante
  `refreshListenable`.
- La restauración de sesión descarta resultados obsoletos por generación y un
  `401` tardío de una sesión anterior no puede borrar un token nuevo.

Decisiones tomadas:

- Se mantuvo `ApiClient` desacoplado del view model mediante un coordinador
  observable inyectado; no se introdujeron dependencias circulares ni lógica de
  red en el router.
- Los `401` de `/autenticacion/*` conservan su manejo local para no convertir
  credenciales incorrectas o restauración fallida en invalidaciones globales.

Archivos modificados:

- `lib/core/network/session_invalidation_notifier.dart`.
- `lib/core/network/api_client.dart`.
- `lib/app/providers.dart`.
- `lib/features/auth/presentation/session_view_model.dart`.
- `test/api_client_session_test.dart`.
- `test/session_view_model_test.dart`.

Pruebas/comprobaciones:

- `flutter test test/api_client_session_test.dart test/session_view_model_test.dart`:
  3 pruebas correctas.
- `flutter analyze`: sin issues.

Riesgo residual:

- La redirección visual no tiene prueba de widget por regla del repositorio; el
  contrato observable está cubierto y GoRouter ya escucha el mismo view model.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-004 / AUD-009 + AUD-010 — Unificar transiciones y bajas académicas

- Prioridad: **P1**.
- Estado: **Cerrado**.
- Skills: `asisteqr-baker-backend-router` y
  `asisteqr-baker-feature-integral`/`asisteqr-baker-backend-prisma`.
- Bug breve: el PATCH general permite modificar `estado` sin efectos laterales;
  las bajas de docente/curso no resuelven asignaciones y bloques activos.

Solución aplicada:

- `UpdateStudentDto` y `UpdateTeacherDto` ya no aceptan `estado`;
  `UpdateCourseDto` ya no acepta `activo`. El `ValidationPipe` global rechaza
  esos intentos con `400`, por lo que ninguna transición evita el comando
  explícito de baja.
- `DELETE /estudiantes/:id` ejecuta en una transacción serializable el retiro
  del estudiante, sus matrículas activas y credenciales QR activas, y registra
  una sola auditoría.
- `DELETE /docentes/:id` cuenta asignaciones y bloques activos dentro de la
  transacción. Si existe alguno responde
  `409 DOCENTE_CON_PLANIFICACION_ACTIVA`, incluye los conteos y no modifica ni
  audita la entidad.
- `DELETE /cursos/:id` aplica el mismo patrón sobre matrículas, asignaciones y
  bloques mediante `409 CURSO_CON_DEPENDENCIAS_ACTIVAS`. Sin dependencias,
  inactiva curso y horarios de ingreso y audita la operación.
- Flutter conserva las filas cuando el servidor rechaza la baja, presenta el
  mensaje autoritativo y anticipa las condiciones en los diálogos.

Decisiones tomadas:

- Se aprobó rechazo `409` antes que cascada silenciosa para dependencias
  académicas externas.
- La matrícula y el QR del estudiante son dependencias propias de su ciclo de
  vida: el comando de retiro debe cerrarlas atómicamente. Bloquear por matrícula
  haría imposible retirar cualquier estudiante porque toda alta crea una.
- No se desactivan asignaciones ni bloques desde los módulos de docentes o
  cursos; deben retirarse explícitamente en el planificador.

Archivos modificados:

- Backend: DTO y services de estudiantes, docentes y cursos; specs nuevas de
  estudiantes/docentes, ampliación de cursos y spec transversal de validación.
- Flutter: mensajes de confirmación en estudiantes, docentes y cursos, más
  pruebas de repositorio y view models para conflictos `409`.

Pruebas/comprobaciones:

- 29 pruebas backend enfocadas correctas: transiciones DTO, bajas con/sin
  dependencias y carga/guardado del planificador.
- 14 pruebas Flutter enfocadas correctas: mensajes `409`, conservación del
  estado local y regresiones de los view models.
- `npm run lint -- --no-fix`, `nest build`, `prisma validate` y
  `flutter analyze`: correctos.
- Inspección de solo lectura de PostgreSQL local: 2 estudiantes con matrícula
  activa, 2 docentes con planificación y 3 cursos con dependencias activas; no
  se modificaron datos ni se requirió migración.

Riesgo residual:

- La reasignación de estudiantes se realiza individualmente antes de retirar un
  curso; no existe todavía una operación masiva.
- No se agregó reactivación de entidades, fuera del alcance de esta corrección.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-005 / AUD-011 — Separar commit de recarga en el planificador

- Prioridad: **P1**.
- Estado: **Cerrado**.
- Skill: `asisteqr-baker-flutter-mvvm`.
- Bug breve: el PUT puede confirmar y el GET siguiente fallar; el view model
  informa fallo total y deja versión/borrador obsoletos.
- Archivos iniciales: repositorio y
  `lib/features/schedules/presentation/schedule_planner_view_model.dart`.
- Solución propuesta: hacer que PUT devuelva/consuma la nueva versión y marcar
  el commit como confirmado antes de recargar. Un fallo de refresh debe mostrar
  “guardado, pendiente de recarga”, no reintentar el PUT.
- Aplicar el mismo patrón a `saveGeneralConfig`.
- Validación: prueba del view model con PUT exitoso + GET fallido, y prueba de
  conflicto real de versión sin perder borrador.

Solución aplicada:

- `savePlanner` conserva y aplica la versión devuelta por el PUT antes de
  intentar la recarga.
- Si el GET posterior falla, el commit permanece confirmado, `dirty` queda
  limpio y el estado `refreshPending` bloquea nuevas ediciones hasta recuperar
  los IDs autoritativos del servidor.
- La UI distingue el guardado confirmado de la recarga fallida, muestra una
  advertencia y ofrece `Recargar` sin repetir el PUT.
- `saveGeneralConfig` devuelve la versión del backend y usa el mismo flujo de
  confirmación y recarga recuperable.

Decisiones tomadas:

- El booleano de guardado representa el resultado del commit, no el del GET.
- Mientras falta la proyección del servidor se bloquea la edición para evitar
  recrear bloques nuevos cuyos IDs aún no se conocen.

Archivos modificados:

- `lib/features/schedules/domain/teacher_schedule_editor_models.dart`.
- `lib/features/schedules/domain/schedule_planner_models.dart`.
- `lib/features/schedules/domain/schedule_planner_repository.dart`.
- `lib/features/schedules/data/api_schedule_planner_repository.dart`.
- `lib/features/schedules/presentation/schedule_planner_view_model.dart`.
- `lib/features/schedules/presentation/teaching_schedules_page.dart`.
- `test/api_schedule_planner_repository_test.dart`.
- `test/schedule_planner_view_model_test.dart`.
- `test/schedule_planner_drag_test.dart` (ajuste de contrato del doble).

Pruebas/comprobaciones:

- `flutter test test/api_schedule_planner_repository_test.dart test/schedule_planner_view_model_test.dart`:
  15 pruebas correctas, incluidos PUT exitoso + GET fallido para matriz y
  configuración.
- `flutter analyze`: sin issues.

Riesgo residual:

- La advertencia y botón de recarga se validaron por análisis estático, sin
  prueba de widget conforme a las reglas del repositorio.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-006 / AUD-012 — Derivar la matriz desde la jornada configurada

- Prioridad: **P1**.
- Estado: **Cerrado**.
- Skill: `asisteqr-baker-flutter-mvvm`.
- Bug breve: la UI fija mañana 07:30–13:30 y tarde 14:00–20:00; una jornada API
  fuera de esos rangos produce cero/slots negativos o valores inválidos.
- Archivos iniciales:
  `lib/features/schedules/presentation/teaching_schedules_page.dart` y modelos
  de configuración.
- Solución propuesta: derivar segmentos visibles de inicio/fin configurados,
  deshabilitar/ocultar segmentos sin intersección y usar siempre
  `max(inicioJornada, inicioSegmento)` al crear bloques. No cambiar la
  persistencia de bloques continuos.
- Validación manual permitida: 320, 390 y 1280 px, texto 130 %, jornadas
  06:00–07:00, 07:30–20:00 y 20:00–21:00. Ejecutar solo `flutter analyze`; no
  crear pruebas de widget/responsive.

Solución aplicada:

- Los tramos Mañana/Tarde se calculan desde `horaInicio`, `horaFin` e
  `intervaloMinutos` de la configuración API, usando un corte alineado a la
  grilla cercano a las 14:00.
- Los tramos sin intersección se omiten de los selectores y, si cambia la
  configuración, la selección activa se ajusta al primer tramo disponible.
- Matriz, agenda móvil, filtro de bloques y altas de clase usan el rango visible
  derivado; nunca calculan slots con una intersección vacía ni parten de una
  hora fija fuera de la jornada.

Decisiones tomadas:

- Una jornada completamente anterior a las 14:00 usa solo Mañana; una jornada
  posterior usa solo Tarde; una jornada que cruza el corte se divide sin dejar
  huecos y respetando la alineación configurada.

Archivos modificados:

- `lib/features/schedules/presentation/teaching_schedules_page.dart`.

Pruebas/comprobaciones:

- Inspección de rangos: 06:00–07:00 produce 2 slots de Mañana; 07:30–20:00
  produce tramos válidos 07:30–14:00 y 14:00–20:00; 20:00–21:00 produce 2
  slots de Tarde.
- `dart format lib/features/schedules/presentation/teaching_schedules_page.dart`.
- `flutter analyze`: sin issues.

Riesgo residual:

- Falta la comprobación manual en dispositivos/ventanas reales de 320, 390 y
  1280 px con texto al 130 %, mantenida en OPS-004. No se creó ni ejecutó una
  prueba de widget conforme a las reglas del repositorio.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-007 / AUD-006 — Definir asistencia con varias jornadas

- Prioridad: **P1**.
- Estado: **Cerrado**.
- Skills: `asisteqr-baker-backend-router`,
  `asisteqr-baker-feature-integral` y `asisteqr-baker-qr-multiplataforma`.
- Bug breve: el curso admite varias jornadas, pero escaneo/manual no identifican
  cuál y el backend toma la primera. La diaria colapsa por estudiante.

Solución aplicada:

- QR y registro manual exigen `jornada`; el backend resuelve el
  `HorarioIngreso` activo de esa jornada dentro de la matrícula vigente.
- La restricción existente conserva una sola marca por estudiante, horario y
  fecha local. Dos jornadas del mismo día son registros independientes y un
  segundo intento en la misma jornada devuelve el original como duplicado.
- `GET /asistencias/jornadas` publica las jornadas operativas disponibles. El
  escáner selecciona automáticamente cuando solo existe una y exige elección
  explícita cuando hay varias.
- La asistencia diaria proyecta una fila por estudiante y horario, con filtro
  opcional por jornada.
- `REGENTE` es el actor operativo de QR/manual y consulta diaria;
  `DOCENTE` conserva consulta, pero no puede registrar. Flutter refleja las
  mismas capacidades en rutas, navegación y acciones.

Decisiones tomadas:

- Negocio confirmó una asistencia por día y por jornada.
- La jornada se selecciona explícitamente en el punto de control; no se infiere
  por reloj ni por docente.
- El administrador mantiene la capacidad operativa de respaldo y el regente no
  recibe acceso a CRUD académico, historial ni reportes.

Archivos modificados:

- Backend: DTO, controller, service y pruebas de `asistencias`; prioridad de rol
  en autenticación; lectura de cursos para regente; semilla y migración del rol.
- Flutter: modelos/repositorios de asistencia, `ScannerViewModel`, escáner,
  resultado, asistencia diaria, dashboard, providers, sesión, router y shell.

Pruebas/comprobaciones:

- Backend: 16 pruebas de asistencia/autenticación cubren puntual, atraso y
  duplicado con jornadas seleccionadas, jornada inexistente, catálogo y diaria.
- Flutter: 12 pruebas enfocadas cubren payload/filtro de jornada, ausencia
  nullable, recientes ordenados y selección automática de jornada.
- `npm run lint -- --no-fix`, `nest build`, `prisma validate`, estado de 15
  migraciones y `flutter analyze`: correctos.

Riesgo residual:

- La migración crea el rol `REGENTE`, pero la cuenta local solo se crea al
  definir `SEED_REGENT_PASSWORD` en el `.env` privado y ejecutar la semilla.
- Falta validación manual de cámara y responsive mantenida en OPS-004.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-008 / AUD-004 — Definir capacidades multirrol

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skills: router backend y feature integral.
- Bug breve: la API devuelve `roles[0]`; el orden no establece que ADMIN tenga
  prioridad.
- Solución corta compatible: ordenar roles con prioridad `ADMIN > DOCENTE`
  antes de construir `rol` y fijarlo en pruebas.
- Solución de contrato más limpia: devolver `roles[]` y derivar capacidades en
  Flutter; implica migración coordinada del contrato.
- Validación: login y restauración de sesión de usuario con ambos roles.

Solución aplicada:

- `AuthService` usa una única función de rol principal para login y restauración
  de sesión, con prioridad estable `ADMINISTRADOR > DOCENTE`.
- Roles futuros no reconocidos conservan una salida determinista por orden
  alfabético y el fallback existente a `DOCENTE`.

Decisiones tomadas:

- Se aplicó la solución corta compatible; el contrato mantiene `rol` y Flutter
  no necesita migrar todavía a capacidades o `roles[]`.

Archivos modificados:

- Backend: `src/modulos/autenticacion/infraestructura/auth.service.ts`.
- Backend: `src/modulos/autenticacion/infraestructura/auth.service.spec.ts`.

Pruebas/comprobaciones:

- `npm test -- --runInBand auth.service.spec.ts`: 2 pruebas correctas, incluido
  un usuario cuyos roles llegan como `DOCENTE, ADMINISTRADOR` en login y sesión.
- `npm run lint -- --no-fix`: correcto.
- `npx --no-install nest build`: correcto.

Riesgo residual:

- Flutter sigue expresando una sola capacidad primaria. La migración a
  `roles[]` queda fuera de esta corrección compatible y requeriría feature
  integral.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-009 / AUD-005 — Mapear errores de asistencia por código

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skills: router backend, feature integral y QR multiplataforma.
- Bug breve: Flutter convierte todo `400` en `inactiveStudent`.
- Solución propuesta: respuestas backend con `code` estable para estudiante
  inactivo, inscripción ausente, horario ausente y configuración ausente;
  ampliar `AttendanceFailureKind` y el texto presentado.
- Validación: pruebas backend del código y pruebas del repositorio Flutter para
  cada respuesta.

Solución aplicada:

- El backend responde códigos estables para QR inválido, estudiante inexistente
  o inactivo, inscripción ausente, horario ausente y configuración ausente.
- Flutter prioriza `code` sobre el estado HTTP, conserva el mensaje seguro y
  presenta un título específico para cada causa. Un `400` desconocido ya no se
  clasifica como estudiante inactivo.

Archivos modificados:

- Backend: `attendance.service.ts` y `attendance.service.spec.ts`.
- Flutter: `attendance_models.dart`, `api_attendance_repository.dart`,
  `scanner_page.dart` y `api_attendance_repository_test.dart`.

Pruebas/comprobaciones:

- 8 pruebas de `AttendanceService` correctas.
- 9 pruebas enfocadas del repositorio de asistencia Flutter correctas.
- `npm run lint`, `nest build` y `flutter analyze`: correctos.

Riesgo residual:

- La selección de jornada para estudiantes con múltiples horarios sigue bajo
  la decisión de negocio de SOL-007; no se alteró en esta corrección.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-010 / AUD-007 — Representar ausencia sin timestamp

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skill: feature integral o Flutter MVVM si el contrato se mantiene nullable.
- Bug breve: `fechaHora: null` se transforma en `DateTime.now()`.

Solución aplicada:

- `AttendanceRecord.timestamp` es nullable y el repositorio conserva el `null`
  autoritativo de la API. La tabla y las tarjetas muestran `—` o “Sin registro
  de ingreso” para una ausencia.

Pruebas/comprobaciones:

- Prueba de mapeo de ausencia por jornada sin timestamp y `flutter analyze`
  correctos. No se creó prueba de widget conforme a las reglas del repositorio.

Riesgo residual: ninguno conocido dentro del contrato diario actual.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-011 / AUD-008 — Ordenar actividad reciente correctamente

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skill: Flutter MVVM; usar feature integral si se crea endpoint.
- Bug breve: se toman cinco elementos de una lista ordenada por curso/apellido.

Solución aplicada:

- El adaptador del dashboard filtra presentes, ordena por timestamp descendente
  y recién entonces toma cinco.

Pruebas/comprobaciones:

- Prueba con orden de respuesta distinto al orden temporal y `flutter analyze`
  correctos.

Riesgo residual:

- El dashboard sigue derivándose de la proyección diaria completa. Un endpoint
  agregado podrá reemplazarlo si el volumen futuro lo exige.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-012 / AUD-013 — Validar alineación al cambiar configuración

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skills: router backend y backend Prisma.
- Bug breve: cambiar inicio de jornada valida rango/recreos, pero no que los
  bloques existentes sigan alineados a la grilla de 30 minutos.
- Solución propuesta: extraer/reutilizar la validación de alineación del batch
  dentro de `saveGeneralConfig` antes de persistir.
- Validación: prueba backend de jornada desplazada a 07:45 con bloques a 08:00,
  y caso válido alineado.

Solución aplicada:

- La configuración general reutiliza la misma regla de alineación del batch
  respecto del inicio y el intervalo propuestos. Si un bloque existente queda
  desalineado responde `CONFIGURACION_AFECTA_CLASES` antes de actualizar.
- La prueba rechaza `07:45–13:45` con un bloque `08:00–09:00` y acepta
  `07:30–13:30` para ese mismo bloque.

Validación: 20 pruebas enfocadas de horarios correctas; lint y build backend
correctos.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-013 / AUD-014 — Endurecer el DTO y diff batch

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skills: router backend y backend Prisma.
- Bug breve: DTO permite sábado/domingo mientras PostgreSQL solo lunes-viernes;
  el mismo ID puede aparecer actualizado, duplicado y eliminado.
- Solución propuesta: `@Max(5)`, validar unicidad de IDs y disjunción entre
  estado activo y listas eliminadas antes de ejecutar `Promise.all`.
- Validación: pruebas negativas que esperen `400` y comprueben rollback/version
  sin cambios.

Solución aplicada:

- `diaSemana` queda limitado por DTO a lunes–viernes (`1..5`).
- Antes de abrir la transacción, el servicio exige IDs únicos dentro de activos
  y eliminados y disjunción entre ambas colecciones, tanto para asignaciones
  como para bloques. Un conflicto responde
  `PAYLOAD_PLANIFICADOR_CONTRADICTORIO`.
- Las pruebas cubren días `0`, `6`, `7`, duplicados en las cuatro listas y el
  cruce activo/eliminado; en los seis payloads contradictorios se comprueba que
  `$transaction` no fue invocado, por lo que versión y datos quedan intactos.

Validación: 20 pruebas enfocadas de horarios correctas; lint y build backend
correctos.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-014 / AUD-015 — Validación estricta de params y fechas

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skills: router backend y backend Prisma.
- Bug breve: UUID de URL llegan como string libre; regex+`Date` acepta fechas
  inexistentes por rollover.
- Solución propuesta: `ParseUUIDPipe` o DTO de params/query y helper Luxon que
  acepte exactamente `yyyy-MM-dd`, sea válido y se reformatee al mismo texto.
- Alcance: asistencia, reportes, historial, estudiantes, docentes, cursos,
  catálogos, horarios y filtros `cursoId`/`periodoId`.
- Validación: tabla de casos UUID inválido, `2026-02-29`, `2026-02-31`, fecha
  válida bisiesta y rangos invertidos; todos los inválidos deben ser `400`.

Solución aplicada:

- Se añadieron pipes compartidos para UUID v4 obligatorios y opcionales. Todos
  los IDs de ruta de estudiantes, docentes, cursos, horarios de ingreso,
  materias, aulas e historial, y los filtros `cursoId`, `docenteId` y
  `periodoId` inventariados, se validan ahora en el borde HTTP.
- `parseCalendarDate` usa Luxon con formato exacto y comprobación canónica de
  ida y vuelta. Asistencia diaria, resumen, exportación PDF e historial lo
  ejecutan antes de consultar Prisma; el historial también rechaza rangos
  invertidos.

Archivos modificados:

- Validación compartida: `src/comun/validacion/calendar-date.ts` y
  `src/comun/validacion/uuid-pipes.ts`, con sus specs.
- Controllers: asistencia, reportes/historial, cursos, estudiantes, docentes,
  catálogos y planificador de horarios.
- Servicios/specs: asistencia y reportes.

Pruebas/comprobaciones:

- 24 pruebas enfocadas correctas para UUID inválido/opcional, fechas
  inexistentes `29/30/31`, formato no canónico, fecha bisiesta válida, rango
  invertido y ausencia de consultas Prisma ante error.
- Inventario final sin `@Param` ni filtros UUID conocidos desprotegidos.
- `npm run lint`, `npx --no-install nest build` y `git diff --check`:
  correctos.

Riesgo residual:

- La exactitud histórica de cohortes y feriados pertenece a SOL-016/AUD-017 y
  continúa bloqueada por decisión de negocio; no se mezcló con esta validación
  sintáctica.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-015 / AUD-016 — Sincronizar el reset de AppDataTable

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skill: `asisteqr-baker-flutter-mvvm`.
- Bug breve: el dropdown usa `initialValue` con key estable y puede conservar el
  valor visual después de limpiar el filtro real.
- Solución propuesta: usar un campo controlado o incluir el valor actual en la
  key, preservando búsqueda, orden, paginación y filtros dinámicos compartidos.
- Validación manual: Asistencia, Estudiantes, Docentes y Cursos en Desktop;
  ejecutar `flutter analyze`, sin prueba widget.

Solución aplicada:

- Se conserva la key pública estable de cada filtro y el campo interno incorpora
  el valor seleccionado (`índice` o `all`) en su key. Al seleccionar o limpiar,
  Flutter crea el campo con el `initialValue` que coincide con el estado real.
- El cambio está en el único `AppDataTable` compartido por Asistencia,
  Estudiantes, Docentes y Cursos; no se duplicó lógica en las páginas.

Validación: inspección del ciclo de identidad del campo y `flutter analyze` sin
issues. No se crearon ni ejecutaron pruebas widget, conforme a `AGENTS.md`.

Riesgo residual: la comprobación física de viewports continúa consolidada en
OPS-004.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-016 / AUD-017 — Definir exactitud histórica de reportes

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skills: router backend y feature integral/backend Prisma.
- Bug breve: el resumen de cualquier rango usa inscritos activos hoy y todos
  los lunes-viernes; ignora vigencia de matrícula y feriados.
- Decisiones necesarias: alcance histórico requerido, efecto de altas/retiros,
  cambio de curso, periodos cerrados y calendario de feriados/recesos.
- Recomendación: primero fijar ejemplos numéricos de aceptación; después decidir
  si se requieren fechas de vigencia en inscripción y calendario académico.
- Validación: fixtures con alta/retiro a mitad de rango, cambio de periodo y un
  día no lectivo.

Solución aplicada:

- `Inscripcion` y `HorarioIngreso` conservan intervalos de vigencia
  `[vigenteDesde, vigenteHasta)`; cambiar de curso u horario cierra el tramo
  anterior y crea uno nuevo sin reescribir el histórico.
- `DiaNoLectivo` registra excepciones fechadas del calendario por periodo. La
  API permite listarlas y al administrador crearlas o retirarlas con auditoría.
- El resumen busca periodos `ACTIVO` o `CERRADO` que intersectan el rango y
  construye unidades esperadas por estudiante, fecha lectiva y jornada
  vigente. Sábados, domingos y días no lectivos no generan ausencias.
- Solo se computan marcas que correspondan a una unidad esperada. Las demás se
  informan como `registrosNoComputados` en JSON, Flutter y PDF.
- La planilla diaria usa los mismos intervalos y calendario al consultar una
  fecha histórica; el escaneo continúa siendo operación exclusiva del regente.

Decisiones tomadas:

- La fecha final es exclusiva: un retiro efectivo el jueves ya no genera
  expectativa el jueves; un traslado efectivo ese día deja de contar al curso
  anterior y empieza a contar al nuevo.
- Una asistencia esperada equivale a estudiante + fecha + jornada. Dos jornadas
  vigentes generan dos expectativas independientes.
- Los periodos planificados no generan esperadas; los cerrados sí conservan su
  histórico.
- La migración retroactiva fija el inicio de matrículas existentes en el inicio
  de su periodo y el de horarios existentes en el primer periodo de su gestión,
  porque el modelo anterior no guardaba la fecha real previa.

Ejemplo numérico de aceptación:

- Rango lunes 3 a viernes 7 de agosto, con miércoles 5 no lectivo.
- Estudiante A vigente toda la semana: 4 expectativas.
- Estudiante B ingresa el miércoles: 2 expectativas, jueves y viernes.
- Estudiante C se retira con efecto el jueves: 2 expectativas, lunes y martes.
- Total: 3 estudiantes históricos, 4 días lectivos y 8 asistencias esperadas.
  Una marca del miércoles y otra posterior al retiro quedan no computadas.

Archivos principales:

- Backend: `prisma/schema.prisma`, migración
  `20260822233000_historical_report_validity`, servicios de reportes, periodos,
  estudiantes, cursos y asistencia diaria.
- Flutter: contrato/mapeo de `ReportSummary`, repositorio API y presentación de
  Reportes.

Pruebas/comprobaciones:

- Backend completo: 78 pruebas en 16 suites; lint y build correctos.
- Prisma: schema válido, 16 migraciones aplicadas y base local al día; la nueva
  migración preservó 2 matrículas y 1 horario con vigencia.
- Flutter: 3 pruebas enfocadas de reportes y `flutter analyze` sin issues.
- Consulta real local del 10 al 14 de agosto: 1 periodo, 2 estudiantes, 5
  esperadas, 1 registro computado y 0 fuera de calendario.

Riesgo residual: los datos retirados o trasladados antes de esta migración no
pueden recuperar fechas que nunca fueron almacenadas. La base local no tenía
matrículas retiradas al aplicar el backfill; las nuevas transiciones sí quedan
historizadas.

Commit o revisión: árbol de trabajo local, sin commit.

### SOL-017 / AUD-018 — Evitar carreras entre cargas Flutter

- Prioridad: **P2**.
- Estado: **Cerrado**.
- Skill: `asisteqr-baker-flutter-mvvm`.
- Bug breve: una respuesta lenta de filtros viejos puede sobrescribir una
  selección nueva en reportes, estudiantes, docentes o cursos.
- Solución propuesta: contador/generación por carga o cancelación Dio; asignar
  resultado/error/loading solo si la generación sigue vigente.
- Validación: pruebas de view model con dos futures resueltos en orden inverso.

Solución aplicada:

- `ReportExportViewModel`, `StudentsViewModel`, `TeachersViewModel` y
  `CoursesViewModel` incrementan una generación al iniciar cada carga. Solo la
  generación vigente puede publicar datos, errores o finalizar `loading`.
- Las búsquedas con debounce invalidan inmediatamente la solicitud en curso,
  sin esperar los 320 ms para declarar obsoleta su respuesta. `dispose` también
  invalida cargas pendientes y evita notificaciones tardías.

Decisiones tomadas:

- Se descartaron respuestas en el view model en lugar de cancelar Dio. El
  contrato y los repositorios permanecen intactos y una solicitud ya enviada
  puede terminar, pero nunca sobrescribe el estado vigente.

Archivos modificados:

- View models de reportes, estudiantes, docentes y cursos.
- Pruebas unitarias focalizadas de esos cuatro view models.

Pruebas/comprobaciones:

- 12 pruebas enfocadas correctas en `report_view_model_test.dart`,
  `people_view_models_test.dart` y `courses_view_model_test.dart`; cuatro casos
  nuevos resuelven dos `Future` en orden inverso y cubren resultado o error
  obsoleto.
- `dart format` y `flutter analyze`: correctos, sin issues.

Riesgo residual: las solicitudes reemplazadas aún consumen transporte hasta
terminar; es un costo acotado y no afecta consistencia de UI. La validación
manual general de viewports continúa en OPS-004.

Commit o revisión: árbol de trabajo local, sin commit.

## Brechas de entrega

| ID | Estado | Tarea pendiente |
|---|---|---|
| OPS-001 | Pendiente | Configurar keystore local y `signingConfigs.release`; nunca versionar secretos. |
| OPS-002 | Pendiente | Crear `installer/` y `scripts/build_windows_msi.ps1` con IDs WiX exclusivos; construir solo en Windows sincronizado. |
| OPS-003 | Pendiente | Incrementar `version: X.Y.Z+N` antes de distribuir. |
| OPS-004 | Pendiente | Validar Android físico, cámara Windows y responsive 320/390/1280 con texto 130 %. |
| OPS-005 | Pendiente | Actualizar el `FRONTEND_PLAN.md` local después de integrar el planificador. |
| OPS-006 | Pendiente | Restaurar `test/jest-e2e.json` o ajustar `test:e2e` y documentar su entorno. |

## Línea base de validación

Resultados correctos observados el 2026-08-22:

- `flutter analyze`: sin issues.
- Flutter: 26 pruebas enfocadas en 9 archivos.
- backend lint sin autofix y `nest build`: correctos.
- backend: 17 pruebas en 7 suites enfocadas.
- `prisma validate`: correcto, con advertencia de configuración de Prisma 6.
- `prisma migrate status`: 14 migraciones aplicadas en PostgreSQL local.
- `git diff --check`: correcto en ambos repositorios.
- consultas de integridad: cero referencias activas hacia catálogos inactivos,
  cero cursos con dos horarios de la misma jornada y cero QR principales activos
  duplicados. Existe un periodo activo.

Al cerrar un lote, repetir solo las pruebas enfocadas correspondientes y los
checks de capa. No usar una compilación Flutter como sustituto del análisis.

## Plantilla de actualización

Copiar una fila por cada cambio de estado:

| Fecha/hora | Issue | Estado anterior → nuevo | Cambios | Validación | Agente |
|---|---|---|---|---|---|
| YYYY-MM-DD HH:mm TZ | AUD-NNN | Pendiente → En curso | Archivos/decisión breve | Comando y resultado | Identificador |

Después añadir debajo del issue:

```text
Solución aplicada:
Decisiones tomadas:
Archivos modificados:
Pruebas/comprobaciones:
Riesgo residual:
Commit o revisión:
```

## Historial de resolución

| Fecha/hora | Issue | Estado anterior → nuevo | Cambios | Validación | Agente |
|---|---|---|---|---|---|
| 2026-08-22 23:13 -04 | AUD-017 | Bloqueado por decisión → Cerrado | Vigencia histórica de matrícula/horario, calendario no lectivo y proyección estudiante-fecha-jornada compartida por resumen, PDF y diaria. | 78 pruebas backend, 3 Flutter, lint/build/Prisma/migración/analyze y consulta local correctos. | Codex |
| 2026-08-22 22:47 -04 | AUD-009 | Abierto → Cerrado | PATCH sin estado/activo; retiro explícito de estudiante mantiene matrícula, QR y auditoría atómicos. | 29 pruebas backend, 14 Flutter y checks de capas correctos. | Codex |
| 2026-08-22 22:47 -04 | AUD-010 | Abierto → Cerrado | Docentes y cursos rechazan con `409` y conteos si existen referencias activas. | Casos con/sin dependencias, planificador, lint/build/Prisma/analyze correctos. | Codex |
| 2026-08-22 22:17 -04 | AUD-006 | Bloqueado por decisión → Cerrado | Jornada explícita; unicidad estudiante+horario+fecha; REGENTE opera QR/manual y la diaria proyecta por horario. | 16 pruebas backend, 12 Flutter, lint/build/Prisma/analyze correctos. | Codex |
| 2026-08-22 22:17 -04 | AUD-007 | Pendiente → Cerrado | Timestamp nullable y ausencia presentada sin hora ficticia. | Prueba de mapeo enfocada y `flutter analyze` correctos. | Codex |
| 2026-08-22 22:17 -04 | AUD-008 | Pendiente → Cerrado | Actividad reciente ordenada por instante descendente antes de limitarla. | Prueba de orden enfocada y `flutter analyze` correctos. | Codex |
| 2026-08-22 21:50 -04 | AUD-018 | Pendiente → Cerrado | Generación vigente en cargas de reportes, estudiantes, docentes y cursos; debounce y dispose invalidan respuestas previas. | 12 pruebas enfocadas y `flutter analyze` correctos. | Codex |
| 2026-08-22 21:39 -04 | AUD-015 | Pendiente → Cerrado | UUID v4 en rutas/filtros y fechas calendario exactas antes de Prisma. | 24 pruebas enfocadas; inventario de controllers, lint, build y diff-check correctos. | Codex |
| 2026-08-22 21:18 -04 | AUD-016 | Pendiente → Cerrado | El campo de filtro cambia de identidad con su valor y el wrapper conserva la key pública. | Inspección del componente compartido y `flutter analyze` sin issues; sin tests UI por regla del repo. | Codex |
| 2026-08-22 21:16 -04 | AUD-013 | Pendiente → Cerrado | La configuración general valida la alineación de bloques existentes con el nuevo inicio. | Caso 07:45 rechazado y 07:30 aceptado; 20 pruebas, lint y build correctos. | Codex |
| 2026-08-22 21:16 -04 | AUD-014 | Pendiente → Cerrado | DTO limitado a lunes–viernes; IDs del diff únicos y disjuntos antes de transacción. | Días inválidos y seis payloads contradictorios cubiertos; 20 pruebas, lint y build correctos. | Codex |
| 2026-08-22 21:04 -04 | AUD-005 | Pendiente → Cerrado | Backend publica seis códigos funcionales y Flutter los mapea a causas/títulos específicos. | 8 pruebas backend y 9 Flutter correctas; lint, build y analyze correctos. | Codex |
| 2026-08-22 20:53 -04 | AUD-004 | Pendiente → Cerrado | Login y sesión eligen `ADMINISTRADOR` por encima de `DOCENTE`, sin cambiar contrato. | 2 pruebas de AuthService correctas; lint y build backend correctos. | Codex |
| 2026-08-22 20:35 -04 | AUD-012 | Pendiente → Cerrado | Tramos y altas usan la jornada API; los tramos vacíos se omiten. | Inspección de 06:00–07:00, 07:30–20:00 y 20:00–21:00; `flutter analyze` sin issues. | Codex |
| 2026-08-22 20:33 -04 | AUD-011 | Pendiente → Cerrado | El commit aplica la versión antes del GET; una recarga fallida queda recuperable y no repite PUT. | 15 pruebas focalizadas correctas; `flutter analyze` sin issues. | Codex |
| 2026-08-22 20:26 -04 | AUD-003 | Pendiente → Cerrado | `401` protegido invalida una sola vez el token y el estado observable; se ignoran respuestas tardías de tokens anteriores. | 3 pruebas focalizadas correctas; `flutter analyze` sin issues. | Codex |
| 2026-08-22 20:22 -04 | AUD-002 | Pendiente → Cerrado | La semilla crea/upsert la asignación canónica y enlaza el bloque en create/update. | Prisma válido; lint y build correctos; 14 migraciones+seed en esquema temporal; cero bloques activos sin asignación. | Codex |
| 2026-08-22 20:14 -04 | AUD-001 | Pendiente → Cerrado | Se retiraron asistencias simuladas y se dejó un estado vacío explícito. | Búsqueda de datos ficticios sin coincidencias; `flutter analyze` sin issues. | Codex |
| 2026-08-22 | AUD-001…AUD-018 | — → Pendiente | Se crea la cola de solución y el contexto de relevo; no se modifica runtime. | Consistencia documental y `git diff --check`. | Codex auditor |
