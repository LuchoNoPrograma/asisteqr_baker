# AGENTS.md

## Proyecto

AsisteQR Baker es una aplicacion Flutter responsive para Desktop y Android. Usa
Riverpod, GoRouter y una arquitectura por funcionalidades con capas `domain`,
`data` y `presentation`.

Los destinos del proyecto son:

- Desktop: Linux y Windows.
- Movil: Android.
- Web no forma parte del alcance. No ejecutar, compilar, servir ni validar la
  aplicacion como Flutter Web.

Antes de modificar comportamiento o estructura, leer `README.md` y
`FRONTEND_PLAN.md`. Para descubrir codigo, usar primero el grafo MCP de
codebase-memory y mantener su indice actualizado.

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
- No compilar la aplicacion solamente para probar cambios. Usar analisis
  estatico y pruebas enfocadas; compilar solo cuando se necesite generar un
  artefacto ejecutable o el usuario lo pida.
- Para lanzar Desktop durante desarrollo, usar `flutter run -d linux` o el
  dispositivo Desktop solicitado, con la API y los mocks definidos de forma
  explicita.
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
