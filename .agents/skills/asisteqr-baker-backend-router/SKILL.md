---
name: asisteqr-baker-backend-router
description: Enrutar cualquier solicitud de AsisteQR Baker que pueda tocar backend, API, endpoint, autenticacion, roles, Prisma o PostgreSQL. Usar antes de implementar para identificar modulo propietario, contrato, consumidor Flutter y skill ejecutora; no usar para trabajo puramente visual o local de Flutter.
---

# AsisteQR Baker Backend Router

## Proposito

Resolver ownership del backend desde el workspace principal y entregar una ruta de trabajo explicita antes de modificar codigo.

## Alcance del proyecto

- Punto de entrada unico `/home/nini/StudioProjects/asisteqr_baker`; el backend externo se inspecciona en `/home/nini/IdeaProjects/asisteqr_baker_backend`.
- Modulos NestJS de autenticacion, asistencias, estudiantes, docentes, cursos, horarios, periodos, credenciales, reportes y salud, mas fronteras comunes y Prisma.
- Seleccion entre `asisteqr-baker-backend-prisma`, `asisteqr-baker-feature-integral`, `asisteqr-baker-qr-multiplataforma` y `asisteqr-baker-flutter-mvvm`; este router no reemplaza su implementacion.

## Fuentes

- Leer [mapa-del-backend.md](references/mapa-del-backend.md) y confirmar la ruta o simbolo vigente en el codigo antes de decidir ownership.
- Leer `AGENTS.md` del workspace principal y `/home/nini/IdeaProjects/asisteqr_baker_backend/src/app.module.ts` para comprobar wiring global.
- Leer controller, service, module y consumidor Flutter de la ruta elegida. Leer DTO, spec y modelos Prisma cuando existan o correspondan; registrar su ausencia en la ficha en vez de inventarlos.

## Patrones del proyecto

- `/home/nini/IdeaProjects/asisteqr_baker_backend/src/app.module.ts` - `AppModule`: registro autoritativo de modulos conectados al runtime; una carpeta no importada no demuestra ownership operativo.
- `/home/nini/IdeaProjects/asisteqr_baker_backend/src/modulos/horarios/infraestructura/teaching-schedules.module.ts` - `TeachingSchedulesModule`: un mismo limite funcional puede agrupar varios controllers y services sin crear un modulo por endpoint.
- `lib/app/providers.dart` - providers de repositorio: identifica que feature Flutter consume cada contrato y cuando una tarea deja de ser solo backend.

## Flujo

1. Extraer del pedido sustantivos, accion, actor, ruta conocida, dato afectado y pantalla consumidora sin asumir que el nombre visible coincide con el modulo.
2. Buscar primero ruta y controller; confirmar service y module, localizar DTO, modelos Prisma y spec aplicables, y contrastar el consumidor Flutter en el mapa.
3. Elegir un propietario primario por regla o transaccion y listar modulos secundarios solo como dependencias o consumidores.
4. Seleccionar `asisteqr-baker-backend-prisma` para una implementacion confinada al servidor, `asisteqr-baker-feature-integral` si cambia contrato o Flutter, y `asisteqr-baker-qr-multiplataforma` si intervienen captura, credencial o registro QR.
5. Entregar antes de editar exactamente la ficha definida en `mapa-del-backend.md`; no abreviarla ni omitir campos.
6. Si dos propietarios siguen siendo plausibles, trazar llamadas o imports hasta encontrar quien posee la regla; no implementar mientras el ownership siga ambiguo.

## Reglas

- No elegir modulo solo por nombre de tabla, pantalla o carpeta; la ruta, el controller y el service vigente tienen prioridad.
- No convertir el router en ejecutor ni duplicar reglas detalladas de las skills especializadas.
- No crear un modulo, controller, DTO o repository nuevo para resolver una ambiguedad que el codigo actual ya responde.
- La ruta `GET /estudiantes/:id/historial` pertenece actualmente a `reportes`, no al controller CRUD de estudiantes.
- Materias y aulas pertenecen actualmente al modulo `horarios` mediante `ScheduleCatalogsController`, aunque sus rutas no tengan prefijo `horarios`.
- Si cambia request, response, errores o permisos consumidos por Flutter, el trabajo es integral aunque la solicitud mencione solo backend.

## Validacion

- Comprobar que todo controller, service, module, DTO, spec, modelo Prisma y consumidor Flutter citado existe. Marcar `No aplica` con motivo para artefactos que la capacidad no tenga.
- Buscar todas las rutas del controller y todos los consumidores del endpoint para evitar ownership parcial.
- Verificar que la skill ejecutora elegida permite la validacion requerida sin ampliar el alcance ni ejecutar builds para validar este router.

## Autoevaluacion

- La ficha nombra un unico propietario primario y explica por que?
- Se identificaron rutas no obvias, consumidores Flutter y modelos de datos realmente afectados?
- La skill ejecutora puede comenzar sin volver a decidir ownership?
