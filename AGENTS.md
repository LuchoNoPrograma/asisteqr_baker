# AGENTS.md

## Proyecto

AsisteQR Baker es una aplicacion Flutter responsive para Desktop y Android. Usa
Riverpod, GoRouter y una arquitectura por funcionalidades con capas `domain`,
`data` y `presentation`.

La arquitectura de presentacion es MVVM. Las vistas renderizan estado y
despachan comandos; los view models coordinan casos de uso, borradores y estados
de carga; los repositorios encapsulan por completo el acceso a la API.

Los destinos del proyecto son:

- Desktop: Linux y Windows.
- Movil: Android.
- Web no forma parte del alcance. No ejecutar, compilar, servir ni validar la
  aplicacion como Flutter Web.

Antes de modificar comportamiento o estructura, leer `README.md` y, si existe
en el entorno local, `FRONTEND_PLAN.md`. El plan es un archivo de trabajo local
y no forma parte del repositorio. Para descubrir codigo, usar primero el grafo
MCP de codebase-memory y mantener su indice actualizado.

## Datos y ejecucion

- La interfaz productiva debe consumir la API; los mocks se reservan para
  pruebas y demostraciones controladas.
- La aplicacion siempre usa los repositorios API; no existe un selector de
  mocks para ejecucion.
- En Desktop, definir
  `--dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1`.
- En el emulador Android, definir
  `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1`.
- En un Android fisico, usar una URL alcanzable desde el dispositivo; no usar
  `127.0.0.1` ni `10.0.2.2`.
- No usar `tool/serve_web.mjs` como mecanismo de ejecucion del proyecto.
- Los datos visibles llegan desde la API, que es la unica fuente configurada
  por los providers de la aplicacion.
- El backend de desarrollo esta en
  `/home/nini/IdeaProjects/asisteqr_baker_backend` y usa PostgreSQL local en
  `127.0.0.1:5432`, base `sistema-educativo-baker`.
- No asumir que PostgreSQL se ejecuta en Docker ni iniciar contenedores para
  trabajar con este proyecto. Las credenciales pertenecen al `.env` local del
  backend y nunca deben copiarse a documentacion, codigo Flutter o logs.
- Antes de proponer cambios de persistencia, contrastar `prisma/schema.prisma`,
  las migraciones aplicadas y, cuando corresponda, la base local real.
- `prisma migrate reset` es destructivo y se reserva para desarrollo. Ejecutarlo
  unicamente cuando el usuario lo solicite o apruebe y despues de cuadrar
  migraciones y semilla.
- No compilar la aplicacion solamente para probar cambios. Usar analisis
  estatico y pruebas enfocadas; compilar solo cuando se necesite generar un
  artefacto ejecutable o el usuario lo pida.
- Para lanzar Desktop durante desarrollo, usar `flutter run -d linux` o el
  dispositivo Desktop solicitado, con la URL de API definida de forma
  explicita. La ejecucion normal no usa mocks.
- Para lanzar Android, seleccionar el emulador o dispositivo mediante
  `flutter devices` y ejecutar `flutter run` con la URL de API apropiada.

## Tablas de gestion

Las vistas de Asistencia, Estudiantes, Docentes y Cursos deben compartir
`AppDataTable<T>` en escritorio. No crear tablas locales con apariencia o
comportamiento diferentes.

Toda tabla de gestion debe:

- ocupar el ancho disponible del area de trabajo;
- usar datos recibidos del repositorio, sin filas simuladas dentro del widget;
- incluir busqueda local sobre los campos relevantes;
- ofrecer filtros derivados dinamicamente de los datos cargados;
- permitir ordenar desde los encabezados configurados;
- paginar con opciones de 10, 25 y 50 filas;
- conservar acciones CRUD y estados de carga, error y lista vacia;
- usar scroll horizontal cuando las columnas no caben, sin provocar overflow;
- mantener una alternativa movil legible cuando el ancho sea reducido.

Los filtros de cada modulo pertenecen a la tabla en escritorio. Evitar una
segunda barra de filtros duplicada encima del componente.

## MVVM

- `domain` contiene entidades, value objects, normalizacion y contratos sin
  dependencias de Flutter, Dio ni widgets.
- `data` implementa repositorios API y traduce DTO; no expone mapas JSON a
  presentacion.
- `presentation` separa pagina, widgets y view model. El view model conserva el
  estado de negocio y ofrece comandos explicitos como `load`, `save`, `undo` y
  `redo`.
- Los widgets no llaman HTTP ni repositorios. `setState` se limita a estado
  efimero puramente visual, por ejemplo hover, foco o arrastre en curso.
- Los providers construyen e inyectan dependencias; no deben convertirse en una
  segunda capa de reglas de negocio.
- Los formularios complejos trabajan sobre un borrador del view model, con
  estado original, cambios pendientes, errores y resultado de guardado
  representados explicitamente.

## Horarios academicos

- La vista especializada de un docente debe abrirse desde Gestion de Docentes y
  usar una ruta identificable por `docenteId`.
- La matriz usa dias como columnas e intervalos de 30 minutos como filas, pero
  las celdas son solo una proyeccion visual. La persistencia usa bloques
  continuos con inicio y fin; no se crea un registro ni una peticion por celda.
- El borrador completo se edita localmente y se guarda con una sola operacion
  batch de la API. Nunca emitir `POST`, `PATCH` o `DELETE` por cada celda pintada.
- Un guardado de matriz debe resolverse en una unica transaccion del backend:
  bloquear la planificacion del periodo, validar docente/curso/aula/recreos,
  aplicar el diff, incrementar version y registrar una sola auditoria.
- El backend es la autoridad final para conflictos de docente, curso y aula. La
  validacion local mejora la respuesta visual, pero no reemplaza la validacion
  transaccional.
- Los recreos son configuracion general del periodo o jornada y se muestran
  como intervalos bloqueados en todas las matrices afectadas.
- El editor Desktop admite hover, seleccion por arrastre, mover y redimensionar
  bloques, teclado, deshacer y rehacer. Android conserva una agenda diaria
  tactil legible y no intenta comprimir cinco dias en 320 px.

## Responsive y calidad

- Auditar Android al menos a 320 y 390 px, incluyendo texto al 130%, y Desktop
  al menos a 1280 px.
- Ningun texto, boton, dialogo, fila o barra de filtros debe desbordar su
  contenedor.
- Las tablas pueden desplazarse horizontalmente, pero el layout de la pagina no
  debe producir scroll lateral global.
- Usar los patrones visuales existentes: interfaz institucional sobria, radios
  de hasta 8 px y color reservado para acciones y estados.
- Antes de cerrar cambios de UI, ejecutar `flutter analyze` y las pruebas
  enfocadas relevantes. No usar `flutter build` como sustituto de pruebas.

## Edicion

- Mantener los cambios acotados al pedido y respetar modificaciones existentes.
- Usar `apply_patch` para ediciones manuales.
- Preferir componentes compartidos sobre duplicacion entre pantallas.
- No revertir archivos o cambios ajenos sin una solicitud explicita.
