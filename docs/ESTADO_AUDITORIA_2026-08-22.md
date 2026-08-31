# Estado de auditoría — 2026-08-22

## Dictamen ejecutivo

**El MVP tiene una arquitectura sólida y sus validaciones automatizadas pasan,
pero el estado actual no es apto para entrega.** El semáforo técnico es
**amarillo** y el semáforo de entrega es **rojo**.

La separación Flutter MVVM/API/Prisma está bien aplicada, la seguridad base es
razonable y las dos operaciones más sensibles —registro de asistencia y
guardado batch de horarios— tienen buenas protecciones transaccionales. Sin
embargo, la auditoría abrió **18 hallazgos: 1 crítico, 7 altos y 10 medios**. El
bloqueo inmediato es que la pantalla del escáner muestra dos registros
simulados como si fueran recientes. También hay riesgos altos en semilla limpia,
expiración de sesión, jornadas múltiples, bajas lógicas y confirmación del
guardado de horarios.

El código auditado no es una revisión limpia: Flutter parte de `a37a913` con 23
entradas locales previas a esta documentación; backend parte de `4ae0130` con 5
entradas locales. La mayor parte corresponde a la consolidación en curso del
planificador. Este informe describe exactamente ese árbol de trabajo y no debe
atribuirse sin más al último commit.

## Actualización de cierre — 2026-08-22 23:13 -04

Los **18 hallazgos de código están cerrados** con evidencia en
`BITACORA_AUDITORIA.md`; el semáforo técnico de la auditoría pasa a **verde**.
El semáforo de entrega continúa **rojo** por las seis brechas `OPS`: firma APK,
infraestructura MSI, incremento de versión, validación física/responsive y
cobertura E2E reproducible.

El último cierre, AUD-017, incorporó vigencia histórica de matrículas y
horarios, calendario no lectivo y cálculo por estudiante-fecha-jornada para
resumen, PDF y planilla diaria. La validación final completó 78 pruebas backend,
3 pruebas Flutter enfocadas, lint, build, Prisma, migración local número 16 y
`flutter analyze`, todo correctamente. No se ejecutó Flutter Web, build Flutter
ni `prisma migrate reset`.

## Estado por área

| Área | Estado | Evaluación |
|---|---|---|
| Arquitectura Flutter | Bueno | MVVM por feature, repositorios API y providers de inyección; no se hallaron llamadas HTTP desde widgets. |
| Contrato/API | Atención | Cobertura funcional amplia, pero faltan códigos de error estables y validación transversal de UUID/fechas. |
| Autenticación/autorización | Atención | Sesiones opacas, Argon2, guards y roles correctos en backend; Flutter no reacciona completamente a un 401. |
| Asistencia/QR | Atención | Transacción y unicidad robustas; la selección de jornada es ambigua y existen datos simulados visibles. |
| CRUD académico | Atención | Flujos completos; algunas transiciones de estado eluden efectos laterales y las bajas pueden dejar referencias activas. |
| Planificador | Atención | Buen borrador local y batch transaccional; la UI asume turnos fijos y existe una ventana de falso fallo después del commit. |
| Reportes | Atención | Resumen/PDF funcionan; el histórico se calcula con matrícula actual y días hábiles simplificados. |
| Prisma/PostgreSQL local | Bueno con bloqueo de bootstrap | 14 migraciones aplicadas y base actual consistente; la semilla no satisface una restricción nueva en una base limpia. |
| Calidad automatizada | Bueno, cobertura insuficiente | Análisis, build backend y 43 pruebas enfocadas pasan; los bordes identificados no están cubiertos. |
| Entrega APK/MSI | No preparado | Sin firma Android, sin infraestructura MSI, versión inicial y cámaras físicas pendientes. |

## Fortalezas verificadas

- La ejecución normal inyecta repositorios API; los mocks no son una fuente
  seleccionable para la interfaz productiva.
- `domain`, `data` y `presentation` conservan responsabilidades diferenciadas;
  los widgets despachan comandos a view models.
- El backend aplica validación global, guards de sesión/roles, Helmet, límite de
  cuerpo y rate limiting. Las contraseñas usan Argon2 y las sesiones guardan el
  hash de un token opaco.
- El registro de asistencia usa hora/zona del servidor, una transacción y una
  restricción única por estudiante, horario y fecha. Las carreras devuelven el
  registro ya existente como duplicado.
- El planificador guarda el estado con un único batch: toma un bloqueo por
  periodo, comprueba versión, catálogos, rangos, recreos y conflictos de
  docente/curso/aula, aplica bajas lógicas y genera una auditoría resumida.
- PostgreSQL impide más de una credencial QR principal activa por estudiante y
  conserva el token QR para reimpresiones.
- La base local no presenta las inconsistencias latentes buscadas: un solo
  periodo activo y cero referencias activas hacia catálogos inactivos.

## Riesgo priorizado

| Prioridad | IDs | Acción recomendada |
|---|---|---|
| P0, antes de cualquier demo/entrega | AUD-001 | Eliminar los registros simulados del escáner y usar datos API/estado vacío. |
| P1, antes de ampliar pruebas de aceptación | AUD-002, AUD-003, AUD-006, AUD-009, AUD-010, AUD-011, AUD-012 | Corregir invariantes y estados transaccionales; añadir pruebas de regresión no visuales donde corresponda. |
| P2, antes de cerrar MVP | AUD-004, AUD-005, AUD-007, AUD-008, AUD-013, AUD-014, AUD-015, AUD-016, AUD-017, AUD-018 | Endurecer contrato, exactitud de datos y coherencia asíncrona. |
| Entrega | OPS-001 a OPS-006 | Completar firma, versión, MSI, E2E y validación manual en hardware/responsive. |

El detalle, evidencia y criterio de cierre de cada caso vive en
`BITACORA_AUDITORIA.md`. El recorrido funcional completo está en
`FLUJOS_FUNCIONALES.md`. La cola priorizada y el contexto para que otro agente
continúe están en `BITACORA_SOLUCION_ISSUES.md`.

## Validaciones ejecutadas

| Comprobación | Resultado |
|---|---|
| `flutter analyze` | Correcto, sin issues (17,2 s). |
| 9 archivos de pruebas Flutter de repositorios/mapeo/view models afectados | 26 pruebas correctas. |
| `npm run lint -- --no-fix` | Correcto. |
| `npx --no-install nest build` | Correcto. |
| 7 suites Jest enfocadas | 17 pruebas correctas. |
| `npx --no-install prisma validate` | Correcto; advertencia deprecatoria de configuración de Prisma 6. |
| `npx --no-install prisma migrate status` | 14 migraciones; esquema local al día. |
| `git diff --check` en Flutter y backend | Correcto. |

No se ejecutó Flutter Web ni se compiló Flutter. No se crearon ni ejecutaron
pruebas de UI, widgets, responsive, navegación o textos, conforme a las reglas
del repositorio. Las pruebas Flutter ejecutadas se limitaron a lógica de
repositorio, mapeo y guardado afectada por los cambios locales. Tampoco se usó
`prisma migrate reset` ni se modificó la base.

### Suites enfocadas

Flutter:

- repositorio y view model del planificador;
- repositorios de asistencia, autenticación y credenciales;
- sesión del cliente API;
- view models de cursos, personas y reportes.

Backend:

- planificador, asistencia y credenciales;
- guard de sesión y autenticación;
- cursos y reportes.

Que estas 43 pruebas pasen confirma el camino cubierto, no la ausencia de los
18 fallos de borde documentados.

## Comprobación de persistencia local

Sin exponer credenciales, se contrastó `prisma/schema.prisma`, las migraciones
aplicadas y PostgreSQL local. Se confirmaron las restricciones de:

- unicidad de asistencia por estudiante, horario y fecha;
- una credencial principal activa por estudiante;
- minutos semanales entre 30 y 2400 y divisibles por 30;
- intervalo general de 30 minutos, rango/tolerancia válidos y versión positiva;
- asignación obligatoria para todo bloque de clase activo;
- día de clase entre lunes y viernes.

Consultas de integridad sobre la base actual:

| Condición | Conteo |
|---|---:|
| Periodos activos | 1 |
| Cursos con más de un horario activo en la misma jornada | 0 |
| Asignaciones activas con curso/materia/docente inactivo | 0 |
| Bloques activos con referencia inactiva | 0 |
| Inscripciones activas en curso inactivo | 0 |
| Estudiantes con más de una credencial principal activa | 0 |

Estos ceros indican que la base local está consistente hoy; no eliminan los
caminos de API capaces de crear inconsistencias futuras.

## Cobertura funcional

Se identificaron **24 flujos de usuario/operación** y **43 rutas HTTP**. Cubren
sesión, panel, asistencia QR/manual/diaria, historial, estudiantes, docentes,
cursos, horarios de ingreso, materias, aulas, planificador, configuración,
credenciales, reportes, PDF y salud. El inventario, roles, autoridad y estados
de error se documentan en `FLUJOS_FUNCIONALES.md`.

## Limitaciones de esta auditoría

- El grafo MCP de codebase-memory solicitado por `AGENTS.md` no está disponible
  en el entorno y su directorio local no contiene un índice utilizable. El
  descubrimiento se hizo con inventario de archivos, búsqueda de referencias y
  trazado manual de controller a persistencia.
- No se hizo validación visual/manual en Android 320/390 px, Desktop 1280 px,
  texto al 130 % ni cámaras reales. Esas comprobaciones siguen abiertas.
- No se probó un bootstrap destructivo de la base; AUD-002 se demuestra por la
  contradicción directa entre semilla y CHECK aplicado.
- No se auditó un servicio remoto ni se asumió un entorno de producción activo.

## Criterio para cambiar el dictamen

El semáforo de código puede pasar a verde cuando AUD-001 y los siete hallazgos
altos estén cerrados con evidencia, los medios tengan corrección o aceptación
explícita de negocio y se repitan las validaciones. El semáforo de entrega solo
puede pasar a verde además cuando se cierren las brechas OPS aplicables al
artefacto solicitado.
