---
name: asisteqr-baker-feature-integral
description: Orquestar funcionalidades integrales de AsisteQR Baker que crucen Flutter, contrato HTTP, NestJS y PostgreSQL. Usar al agregar o cambiar un recorrido completo del MVP; no usar para un ajuste visual aislado, una migracion aislada ni una correccion confinada a una sola capa.
---

# AsisteQR Baker Feature Integral

## Proposito

Coordinar cambios verticales del MVP sin duplicar reglas entre el cliente y el servidor ni convertir una entrega pequena en arquitectura prematura.

## Alcance del proyecto

- Workspace coordinador en `/home/nini/StudioProjects/asisteqr_baker`; todas las tareas del producto comienzan desde este repositorio.
- Cliente Flutter en `lib/` y pruebas dirigidas en `test/`.
- API NestJS, Prisma y PostgreSQL en `/home/nini/IdeaProjects/asisteqr_baker_backend` cuando el recorrido requiera contrato, autoridad o persistencia.
- MVP para Android, Linux y Windows; Web no forma parte del alcance y no existen usuarios ni datos productivos que justifiquen ceremonias de compatibilidad operativa.
- Arquitectura vigente `Flutter -> API NestJS -> PostgreSQL`; los repositorios API son la unica fuente configurada para ejecucion normal.

## Fuentes

- Leer `AGENTS.md` y `README.md` del workspace principal, y `/home/nini/IdeaProjects/asisteqr_baker_backend/README.md` cuando la tarea cruce al servidor.
- Leer los modelos, contratos de repositorio, view models, DTO, controller, service y modelos Prisma del recorrido afectado.
- Usar Bora Asai solo para comparar coordinacion entre repositorios; no importar sus reglas de POS, Supabase, RLS, multi-tenant ni operacion productiva.

## Patrones del proyecto

- `lib/app/providers.dart` - `apiClientProvider` y providers de repositorio/view model: composition root que inyecta implementaciones API sin selector de mocks en runtime.
- `lib/features/schedules/data/api_schedule_planner_repository.dart` - `ApiSchedulePlannerRepository.savePlanner`: traduce un borrador completo a un unico contrato batch y conserva la version del servidor.
- `/home/nini/IdeaProjects/asisteqr_baker_backend/src/modulos/horarios/infraestructura/teaching-schedules.service.ts` - `TeachingSchedulesService.savePlanner`: posee validacion autoritativa, bloqueo por periodo, diff, transaccion, version y auditoria.

## Flujo

1. Permanecer en el workspace `asisteqr_baker` como punto de entrada y usar `asisteqr-baker-backend-router` para identificar el propietario del servidor antes de trazar el recorrido integral.
2. Definir actor, criterio de aceptacion observable, estados, request, response, errores, ownership y exclusiones antes de editar consumidores.
3. Cambiar primero persistencia y backend cuando la capacidad autoritativa no exista, luego adaptar repositorio/view model Flutter y finalmente la presentacion.
4. Mantener el cambio mas pequeno que complete el recorrido y actualizar documentacion solo cuando cambie un contrato o una regla estable.
5. Validar cada frontera modificada con la comprobacion focalizada mas barata y revisar el diff de ambos repositorios.

## Reglas

- No duplicar en Flutter permisos, conflictos de horario, consecutivos, registro de asistencia ni otras reglas que el backend ya decide.
- No agregar cache autoritativa, modo offline, colas, microservicios, repositories adicionales en NestJS ni abstracciones por una expansion hipotetica.
- No copiar rutas, credenciales, identificadores de despliegue ni invariantes comerciales de Bora Asai.
- Aunque sea MVP, proteger sesiones, datos personales, transacciones y operaciones destructivas; una baja logica no se convierte en borrado fisico por simplificacion.
- No exigir compatibilidad con clientes publicados ni planes de rollback productivo mientras AsisteQR Baker siga fuera de produccion; resolver juntos los dos repositorios cuando cambie el contrato.

## Validacion

- Ejecutar `dart format` sobre los Dart tocados y `flutter analyze` en el cliente.
- Ejecutar la prueba Flutter focalizada de repositorio o view model cuando cambie persistencia, mapeo o guardado; no crear ni ejecutar pruebas de UI solo para validar layout o texto.
- Con `/home/nini/IdeaProjects/asisteqr_baker_backend` como directorio de trabajo, ejecutar la spec Jest minima del servicio afectado, `npm run lint -- --no-fix` y `npx --no-install nest build` cuando cambien contrato, transaccion o wiring.
- Si cambia Prisma, ejecutar `npx prisma validate` desde el backend y revisar schema, migracion nueva, semilla y consumidores sin resetear la base.

## Autoevaluacion

- El cambio cruza realmente mas de una frontera y necesita esta orquestadora?
- Cada regla autoritativa quedo en NestJS o PostgreSQL y Flutter solo presenta o valida formato?
- Se evito infraestructura de produccion o abstraccion que el MVP aun no necesita?
