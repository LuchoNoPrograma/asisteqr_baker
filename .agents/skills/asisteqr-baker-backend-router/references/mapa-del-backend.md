# Mapa del backend de AsisteQR Baker

Usar este mapa para ubicar el primer propietario. Confirmar siempre la ruta y
los simbolos en el codigo vigente antes de implementar.

Todas las rutas HTTP tienen el prefijo global `/api/v1`, configurado en
`src/main.ts`.

## Modulos y consumidores

| Pedido o dato mencionado | Propietario backend | Rutas y simbolos iniciales | Consumidor Flutter |
|---|---|---|---|
| Login, restaurar sesion, logout, token opaco | `autenticacion` y `comun/seguridad` | `/autenticacion/*`; `AuthController`, `AuthService`, `SessionAuthGuard` | `lib/features/auth/`, `lib/core/network/api_client.dart`, router |
| Roles, acceso denegado, actor autenticado | `comun/seguridad` con el modulo de la ruta | `RolesGuard`, `Roles`, `CurrentUser`, `AuthenticatedUser` | `SessionViewModel`, `app_router.dart`, vistas protegidas |
| Escanear QR, ingreso manual, puntualidad, atraso, duplicado diario | `asistencias` | `/asistencias/escanear`, `/asistencias/manual`, `/asistencias/diaria`; `AttendanceController`, `AttendanceService` | `lib/features/attendance/` |
| CRUD, baja o datos de estudiante | `estudiantes` | `/estudiantes`; `StudentsController`, `StudentsService` | `ApiPeopleRepository`, `StudentsViewModel`, `StudentsPage` |
| Baja de estudiante que revoca credenciales | `estudiantes`; secundario `credenciales` como dato revocado | `DELETE /estudiantes/:id`; `StudentsController`, `StudentsService` | `ApiPeopleRepository`, `StudentsViewModel`, `StudentsPage` |
| Historial de un estudiante | `reportes`, no `estudiantes` | `GET /estudiantes/:id/historial`; `reports.controller.ts` `StudentsController`, `ReportsService` | `ApiAttendanceRepository.getStudentHistory`, `StudentHistoryPage` |
| CRUD o baja de docente | `docentes` | `/docentes`; `TeachersController`, `TeachersService` | `ApiPeopleRepository`, `TeachersViewModel`, `TeachersPage` |
| CRUD de curso y horarios de ingreso | `cursos` | `/cursos`, `/cursos/:id/horarios`; `CoursesController`, `CoursesService` | `ApiCourseRepository`, `CoursesViewModel`; opciones de curso en `ApiPeopleRepository` |
| Periodo academico activo | `periodos` | `GET /periodos/activo`; `PeriodsController`, `PeriodsService` | Sin consumidor directo confirmado; revisar planificador antes de crear otro |
| Planificador, bloques, asignaciones, recreos, version y configuracion general | `horarios` | `GET /horarios-clase`, `GET /horarios-clase/planificador`, `PUT /horarios-clase/planificador`, `PUT /horarios-clase/configuracion/general`; `TeachingSchedulesController`, `TeachingSchedulesService` | `ApiSchedulePlannerRepository`, `SchedulePlannerViewModel`, `TeachingSchedulesPage` |
| Materias y aulas | `horarios` | `/materias`, `/aulas`; `ScheduleCatalogsController`, `ScheduleCatalogsService` | `ApiSchedulePlannerRepository`, paneles y dialogos del planificador |
| Credenciales imprimibles, PDF y QR persistente | `credenciales` | `POST /credenciales/imprimibles`; `CredentialsController`, `CredentialsService` | `ApiCredentialRepository`, `CredentialsViewModel`, `CredentialsPage` |
| Resumen y exportacion PDF | `reportes` | `/reportes/resumen`, `/reportes/exportar/pdf`; `ReportsController`, `ReportsService` | `ApiReportRepository`, `ReportExportViewModel`, vistas de reportes |
| Health, conexion PostgreSQL o arranque | `salud`, `comun/configuracion` o composition root | `/health`; `HealthController`, `HealthService`, `environment.ts`, `main.ts`, `AppModule` | Sin feature Flutter propietaria; `API_BASE_URL` vive en `lib/core/config/` |
| Schema, relaciones, indices, unicidad, enums, migraciones o semilla | `prisma/` mas el service propietario de la regla | `prisma/schema.prisma`, `prisma/migrations/`, `prisma/seed.ts` | Todos los repositorios afectados por el contrato |

## Modelos y ownership funcional

- `Usuario`, `Rol`, `UsuarioRol` y `Sesion`: autenticacion y seguridad.
- `Estudiante` e `Inscripcion`: estudiantes; reportes solo proyecta historial.
- `Docente`: docentes, con consumo adicional desde horarios.
- `Curso` y `HorarioIngreso`: cursos; asistencia los consulta para registrar.
- `PeriodoAcademico`: `periodos` posee la consulta publica del periodo activo;
  `horarios` posee su uso transaccional dentro del planificador. Elegir por la
  operacion, no por el modelo compartido.
- `ConfiguracionHorario`, `RecreoHorario`, `AsignacionAcademica`,
  `HorarioClase`, `Materia` y `Aula`: horarios.
- `CredencialQr`: credenciales para emision, asistencias para validacion y
  estudiantes para revocacion durante una baja. Elegir por la operacion y
  declarar los otros como secundarios cuando participen en la misma regla.
- `Asistencia`: asistencias para escritura; reportes para lectura agregada.
- `Auditoria`: la escribe el service que posee cada operacion sensible; no es
  un modulo funcional independiente.

Un modelo compartido no traslada ownership. Elegir propietario por la regla y
la transaccion que cambian, luego tratar a los demas como consumidores.

## Seleccion de skill ejecutora

- Solo backend con contrato Flutter intacto: `asisteqr-baker-backend-prisma`.
- Cambia request, response, errores, permisos o proyeccion Flutter:
  `asisteqr-baker-feature-integral`, que usa
  `asisteqr-baker-backend-prisma` para el tramo servidor y
  `asisteqr-baker-flutter-mvvm` para el consumidor.
- Cambia captura de camara, lectura del token, credencial QR o registro de
  asistencia por escaneo: `asisteqr-baker-qr-multiplataforma`; agregar
  `asisteqr-baker-backend-prisma` si cambia el servidor.
- Solo cambia domain, data o presentation Flutter sin contrato servidor:
  `asisteqr-baker-flutter-mvvm`.

## Ficha obligatoria de salida

Antes de editar, devolver:

```text
Modulo propietario:
Modulos secundarios:
Rutas HTTP:
Controller, service y module:
DTO y modelos Prisma:
Consumidor Flutter:
Skill ejecutora:
Validacion focalizada:
Fuera de alcance:
```

No dejar campos vacios. Usar `No aplica` y explicar por que cuando una fila no
corresponda.
