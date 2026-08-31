---
name: asisteqr-baker-flutter-mvvm
description: Implementar o mantener features Flutter MVVM de AsisteQR Baker con Riverpod, GoRouter, repositorios API y UI responsive para Android y Desktop. Usar para cambios en domain, data, presentation, providers, navegacion o componentes compartidos; no usar para reglas autoritativas del backend ni para Web.
---

# AsisteQR Baker Flutter MVVM

## Proposito

Conservar una presentacion responsive y un cliente API tipado sin mezclar widgets, estado de negocio y transporte.

## Alcance del proyecto

- `lib/features/*/{domain,data,presentation}`, `lib/app/` y componentes compartidos en `lib/core/`.
- Android, Linux y Windows con corte responsive vigente alrededor de 840 px; Flutter Web queda fuera del proyecto.
- Repositorios API como fuente de datos en runtime, Riverpod como composition root y `ChangeNotifier` como view model actual.

## Fuentes

- Leer `AGENTS.md`, `README.md`, la feature afectada y el componente compartido vecino antes de crear uno nuevo.
- Leer controller y DTO reales del backend cuando cambien request, response, errores o permisos.
- Leer los tests de repositorio o view model cercanos solo cuando la regla de validacion permita ejecutarlos.

## Patrones del proyecto

- `lib/app/providers.dart` - `peopleRepositoryProvider` y `studentsViewModelProvider`: dependencias finales construidas e inyectadas por Riverpod, con carga iniciada en el provider cuando corresponde.
- `lib/features/schedules/presentation/schedule_planner_view_model.dart` - `SchedulePlannerViewModel`: borrador, dirty state, undo/redo, conflictos y guardado batch pertenecen al view model, no a la matriz visual.
- `lib/features/people/presentation/students_page.dart` - `StudentsPage` y `_StudentsTable`: adapta movil/escritorio y reutiliza `AppDataTable` sin consultar HTTP desde widgets.

## Flujo

1. Ubicar modelos y contrato en domain, mapeo y errores en data, estado/comandos en el view model y render/callbacks en presentation.
2. Confirmar el contrato HTTP antes de editar el mapeo y representar estados loading, error, vacio, guardando y exito de forma explicita.
3. Inyectar repositorio y view model desde `lib/app/providers.dart`; no construir clientes o servicios de negocio dentro de widgets.
4. Reutilizar `AdaptiveShell`, `AppDataTable`, feedback, dialog headers, badges y tema antes de crear variantes locales.
5. Comprobar movil y escritorio por estructura y overflow; mantener la alternativa movil legible para tablas, formularios y planificador.

## Reglas

- `domain` no depende de Flutter, Dio ni JSON; `data` no expone mapas a presentation; widgets no llaman HTTP.
- Usar `setState` solo para estado efimero visual como foco, hover, seleccion o arrastre; el borrador y el resultado remoto viven en el view model.
- No agregar mocks al flujo normal, una segunda fuente de datos ni secretos mediante `.env` o `--dart-define`.
- No ejecutar, compilar ni adaptar la aplicacion como Flutter Web.
- No duplicar filtros de escritorio fuera de `AppDataTable` ni crear tablas de gestion con comportamiento divergente.
- No mostrar exito antes de la respuesta API ni ocultar errores de contrato con valores inventados.

## Validacion

- Ejecutar `dart format` sobre los archivos Dart tocados y `flutter analyze`.
- Ejecutar pruebas focalizadas solo cuando cambien repositorios, mapeo, persistencia, guardado o una regla de view model que protege datos.
- No crear ni ejecutar pruebas de widget, responsive, navegacion o textos; revisar esos cambios con analisis estatico e inspeccion de los viewports requeridos.

## Autoevaluacion

- La vista solo renderiza estado y despacha comandos?
- El repositorio traduce el contrato sin filtrar JSON hacia presentation?
- La solucion funciona en Android y Desktop sin asumir Web ni duplicar componentes compartidos?
