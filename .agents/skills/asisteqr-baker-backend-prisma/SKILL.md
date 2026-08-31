---
name: asisteqr-baker-backend-prisma
description: Ejecutar cambios concretos en API NestJS, servicios, DTO, Prisma y PostgreSQL de AsisteQR Baker despues de que backend-router identifique el propietario. Usar para implementar endpoints, autenticacion, roles, transacciones, consultas, schema, migraciones, auditoria o reglas autoritativas; no usar para decidir ownership, UI Flutter ni infraestructura productiva especulativa.
---

# AsisteQR Baker Backend Prisma

## Proposito

Implementar la ficha entregada por `asisteqr-baker-backend-router` en un backend MVP seguro y directo donde controllers traducen HTTP y servicios modulares poseen reglas y persistencia Prisma.

## Alcance del proyecto

- La skill se activa desde `/home/nini/StudioProjects/asisteqr_baker`; no exige abrir el backend como proyecto de trabajo independiente.
- Destino de implementacion `/home/nini/IdeaProjects/asisteqr_baker_backend`, principalmente `src/modulos/`, `src/comun/`, `prisma/` y specs Jest.
- Requiere la ficha completa de `asisteqr-baker-backend-router`: propietario, modulos secundarios, rutas, controller/service/module, DTO/modelos Prisma, consumidor Flutter, skill ejecutora, validacion y fuera de alcance.
- Monolito modular NestJS con servicios que usan `PrismaService` directamente; no existe una capa repository separada como convencion del proyecto.
- PostgreSQL local `sistema-educativo-baker` como entorno de desarrollo; AsisteQR Baker aun no opera con datos productivos.

## Fuentes

- Leer `AGENTS.md` del workspace principal y `/home/nini/IdeaProjects/asisteqr_baker_backend/README.md`, `package.json`, controller, service y module de la capacidad afectada; leer DTO y spec cuando existan o correspondan.
- Leer `prisma/schema.prisma`, migraciones relacionadas y `prisma/seed.ts` cuando cambien datos o invariantes.
- Leer el repositorio API y modelos Flutter consumidores cuando cambie el contrato HTTP.

## Patrones del proyecto

- `src/modulos/asistencias/infraestructura/attendance.controller.ts` - `AttendanceController`: aplica guards, roles y throttle, recibe actor/IP y delega sin consultar Prisma.
- `src/modulos/asistencias/infraestructura/attendance.service.ts` - `AttendanceService.registerAttendance`: usa una transaccion, unicidad con `ON CONFLICT`, zona horaria y auditoria para registrar una sola asistencia diaria.
- `src/modulos/horarios/infraestructura/teaching-schedules.service.ts` - `TeachingSchedulesService.savePlanner`: bloquea el periodo, valida version y conflictos, aplica bajas logicas y guarda el batch en una transaccion.

## Flujo

1. Leer la ficha del router y abrir en el backend externo solamente la ruta, DTO, guards, service, modelos Prisma, migraciones y spec que fueron delimitados.
2. Definir autorizacion, validacion, respuesta, errores e invariantes; mantener el controller delgado y la regla en el service.
3. Usar una transaccion Prisma para operaciones atomicas y el mismo `TransactionClient` para todas sus lecturas, escrituras y auditoria.
4. Crear una migracion Prisma nueva cuando cambie el schema; actualizar schema, semilla y consumidores sin reescribir migraciones aplicadas.
5. Acotar consultas, seleccionar o incluir solo datos necesarios y respaldar carreras con unicidad, version o bloqueo segun la invariante real.
6. Actualizar el cliente Flutter en la misma entrega del MVP si cambia un contrato que aun no tiene versiones publicadas.

## Reglas

- No agregar una capa repository, DDD, CQRS, microservicios, eventos o caches solo para completar una plantilla.
- No volver a decidir ownership durante la implementacion; si la ficha falta o una evidencia la contradice, detenerse y ejecutar `asisteqr-baker-backend-router` nuevamente.
- No confiar en usuario, rol, hora oficial, estado de asistencia, conflictos ni consecutivos calculados por Flutter.
- Mantener sesiones opacas revocables y almacenar solo hashes; nunca registrar tokens, contrasenas, `Authorization`, `DATABASE_URL` ni secretos.
- No reemplazar bajas logicas por borrados fisicos ni perder auditoria en operaciones sensibles.
- No ejecutar `prisma migrate reset`, borrar datos ni modificar una base sin solicitud o aprobacion explicita.
- No copiar RLS, tenancy, Supabase, IDs bigint ni otras decisiones de Bora Asai que no existen en este schema UUID de Prisma.

## Validacion

- Con `/home/nini/IdeaProjects/asisteqr_baker_backend` como directorio de trabajo, ejecutar la spec Jest minima del service, guard o validacion afectada cuando cambie una regla critica.
- Ejecutar `npm run lint -- --no-fix` y `npx --no-install nest build` desde el backend para cambios TypeScript o wiring.
- Ejecutar `npx prisma validate` desde el backend y revisar el SQL generado o migracion nueva cuando cambie el schema; no aplicar ni resetear la base solo para validar Markdown.
- Comprobar que el repositorio API Flutter mapea request, response y errores si el contrato cambio.

## Autoevaluacion

- El controller solo traduce HTTP y el service posee la regla?
- La operacion critica conserva transaccion, concurrencia y auditoria?
- El cambio sigue siendo apropiado para un MVP sin debilitar sesiones, datos personales o integridad?
