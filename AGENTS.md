# AGENTS.md

## Proyecto

AsisteQR Baker es una aplicacion Flutter responsive para Desktop y Android. Usa
Riverpod, GoRouter y una arquitectura por funcionalidades con capas `domain`,
`data` y `presentation`.

El producto esta en etapa MVP y aun no opera en produccion. Las instrucciones
de empaquetado o despliegue describen preparacion de entrega y no autorizan a
tratar usuarios, datos o servicios remotos como un entorno productivo activo.

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

## Skills locales del proyecto

Este repositorio es el workspace principal de desarrollo para todo AsisteQR
Baker, incluido el backend externo. El paquete canonico para Flutter, NestJS y
PostgreSQL vive en `.agents/skills/`; iniciar aqui las tareas y abrir
`/home/nini/IdeaProjects/asisteqr_baker_backend` solo cuando la skill aplicable
requiera implementar o verificar servidor, contrato o persistencia. No mantener
una segunda copia del paquete en el backend.

Si el pedido puede tocar backend, ejecutar primero
`asisteqr-baker-backend-router` y despues la skill ejecutora que nombre su
ficha. Para trabajo puramente Flutter, activar directamente la skill mas
especifica. Usar la orquestadora integral solo cuando el cambio cruce
fronteras:

- `asisteqr-baker-backend-router`: entrada obligatoria para cualquier pedido
  que pueda tocar API, endpoint, autenticacion, roles, Prisma o PostgreSQL;
  identifica propietario, rutas, consumidor Flutter y skill ejecutora antes de
  editar.
- `asisteqr-baker-feature-integral`: recorridos completos entre contrato,
  backend, persistencia, repositorio Flutter, view model y UI.
- `asisteqr-baker-flutter-mvvm`: domain, data, presentation, Riverpod,
  navegacion, componentes compartidos y responsive Flutter.
- `asisteqr-baker-backend-prisma`: endpoints NestJS, sesiones, roles,
  servicios, transacciones, Prisma, migraciones y PostgreSQL despues del
  enrutamiento.
- `asisteqr-baker-qr-multiplataforma`: camara y QR en Android, Linux y Windows,
  fallback manual y registro autoritativo de asistencia.

No existe una skill de incidentes productivos, release ni base de datos
separada: el producto sigue siendo MVP y la persistencia Prisma forma parte del
backend. Crear esas fronteras solo cuando la operacion real lo justifique.

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

## Entregas de produccion: APK, EXE y MSI

La URL productiva canonica es:

```text
https://soft-miranda-luisfluoxetina-b6930636.koyeb.app/api/v1
```

- Toda entrega productiva debe compilarse con esa URL mediante
  `--dart-define=API_BASE_URL=...`. Si se omite, Android usara `10.0.2.2` y
  Desktop usara `127.0.0.1`, por lo que el artefacto no consumira produccion.
- `DATABASE_URL`, las claves de Supabase y cualquier otra credencial pertenecen
  solo al backend. Nunca incluirlas en Dart, `.env` sincronizados, argumentos de
  compilacion, instaladores o informes.
- Koyeb puede permanecer pausado durante la compilacion, pero una aplicacion ya
  instalada no podra iniciar sesion ni cargar datos mientras el servicio este
  pausado. Antes de validar o entregar, reanudarlo o dejarlo en Scale-to-Zero y
  comprobar `GET /api/v1/health`.
- Apagar y volver a encender el mismo servicio no requiere recompilar. Si cambia
  el dominio productivo, se deben regenerar APK y MSI.
- Antes de cada entrega, actualizar `version: X.Y.Z+N` en `pubspec.yaml`. No
  reutilizar una version ya instalada o distribuida.
- Ejecutar `flutter pub get` y `flutter analyze` antes de compilar. No usar una
  compilacion como sustituto del analisis.

### APK Android

El APK se genera en Linux desde la raiz del proyecto:

```bash
flutter pub get
flutter analyze
flutter build apk --release \
  --dart-define=API_BASE_URL=https://soft-miranda-luisfluoxetina-b6930636.koyeb.app/api/v1
sha256sum build/app/outputs/flutter-apk/app-release.apk
```

La salida esperada es
`build/app/outputs/flutter-apk/app-release.apk`. Antes de distribuirla:

- comprobar que el `versionName` y `versionCode` coinciden con `pubspec.yaml`;
- comprobar que el APK esta firmado con la clave de produccion;
- instalarlo en un Android real y validar acceso contra la API productiva;
- informar ruta, tamano, version y SHA-256 del artefacto.

Actualmente `android/app/build.gradle.kts` no configura una clave de firma de
release. Mientras siga asi, no presentar el APK como entrega productiva: primero
configurar `android/key.properties` y `signingConfigs.release` siguiendo el
procedimiento oficial de Flutter. El keystore y sus contrasenas son locales,
quedan ignorados por Git y nunca se sincronizan mediante Syncthing.

### Windows, Syncthing y MSI

Flutter Windows debe compilarse dentro de Windows; no intentar generar el EXE o
el MSI desde Linux. El flujo toma como referencia la instalacion funcional de
`/home/nini/StudioProjects/bora_asai`, sin compartir sus identificadores WiX ni
sus archivos de instalador.

Configuracion prevista para AsisteQR Baker:

- Linux es la fuente del codigo y la carpeta Syncthing debe ser **Send Only**.
- Windows es el destino de compilacion y debe ser **Receive Only**.
- Usar un Folder ID propio, `asisteqr-baker`, separado de `bora-asai`.
- Ruta Linux: `/home/nini/StudioProjects/asisteqr_baker`.
- Ruta Windows recomendada: `C:\\dev\\asisteqr_baker`.
- La API local de Syncthing en Windows es `http://127.0.0.1:8384`.
- `.env*`, `.git`, `.dart_tool`, `build`, `dist`, `installer/bin`,
  `installer/obj`, `ephemeral` y `android/local.properties` deben excluirse en
  `.stignore`. El `.env` productivo requerido por Windows se crea localmente y
  solo contiene `API_BASE_URL`; no se sincroniza.

Mientras no exista la carpeta Syncthing `asisteqr-baker`, el flujo Windows aun
no esta preparado. No reutilizar el Folder ID `bora-asai` ni compilar una copia
manual cuya revision no pueda demostrarse.

Antes de cada compilacion en Windows:

```powershell
Get-Process -Name asisteqr_baker -ErrorAction SilentlyContinue | Stop-Process

[xml]$cfg = Get-Content -LiteralPath "$env:LOCALAPPDATA\Syncthing\config.xml"
$headers = @{ 'X-API-Key' = [string]$cfg.configuration.gui.apikey }

Invoke-RestMethod -Method Post `
  -Uri 'http://127.0.0.1:8384/rest/db/scan?folder=asisteqr-baker' `
  -Headers $headers | Out-Null

$status = Invoke-RestMethod `
  -Uri 'http://127.0.0.1:8384/rest/db/status?folder=asisteqr-baker' `
  -Headers $headers

$status | Select-Object state, needTotalItems, needBytes, errors
```

Solo continuar cuando el estado sea `idle`, no existan elementos ni bytes
pendientes y `errors` sea cero. Ademas:

- revisar `$env:LOCALAPPDATA\Syncthing\syncthing.log` buscando fallos recientes;
- buscar archivos `~syncthing~*` abandonados;
- verificar en Windows un marcador funcional de la revision que se quiere
  entregar y comparar el SHA-256 de al menos un archivo fuente relevante;
- no usar **Revert Local Changes** en una carpeta Receive Only;
- no modificar Dart desde Windows durante una tarea de sincronizacion y build.

Luego, desde `C:\dev\asisteqr_baker`:

```powershell
flutter pub get
flutter analyze
flutter build windows --release `
  --dart-define=API_BASE_URL=https://soft-miranda-luisfluoxetina-b6930636.koyeb.app/api/v1
```

El ejecutable queda en
`build\windows\x64\runner\Release\asisteqr_baker.exe`, pero no se debe entregar
el `.exe` aislado: Flutter requiere todas las DLL y el directorio `data` de la
carpeta Release.

### Instalador MSI

El MSI debe empaquetar la carpeta Release completa, instalar en
`Program Files\AsisteQR Baker`, crear acceso directo y registrarse en
Aplicaciones instaladas. Debe construirse con WiX desde un script propio:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\build_windows_msi.ps1 `
  -Version X.Y.Z
```

Mientras no existan `installer/` y `scripts/build_windows_msi.ps1`, una tarea de
MSI es primero una tarea de configuracion del instalador; no afirmar que el MSI
puede generarse todavia. Al crearlos se puede adaptar la estructura de Bora
Asai, pero es obligatorio generar un `UpgradeCode` exclusivo para AsisteQR
Baker. Nunca copiar el `UpgradeCode`, `ProductCode`, nombre de producto o rutas
de Bora Asai.

El script de AsisteQR debe:

- leer localmente `API_BASE_URL` sin imprimir su valor;
- exigir que la version coincida con `pubspec.yaml`;
- ejecutar `flutter build windows --release` con la URL productiva;
- comprobar que existe `asisteqr_baker.exe` y empaquetar Release completo;
- rechazar `.env`, `.db`, `.sqlite`, `.sqlite3`, `.dart` y secretos;
- generar `dist\AsisteQR-Baker-Setup-X.Y.Z-x64.msi` y su SHA-256;
- conservar un `UpgradeCode` fijo y usar un `ProductCode` diferente por version.

Antes de entregar el MSI, validarlo con WiX, comprobar version, arquitectura
x64, nombre `AsisteQR Baker`, fabricante, contenido, SHA-256 y estado de firma
digital. Informar expresamente `NotSigned` mientras no exista un certificado de
firma de codigo. No versionar APK, Release, MSI ni archivos locales de firma.

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

- `AsignacionAcademica` es la unidad canonica de carga: periodo, curso,
  materia, docente y minutos semanales. `HorarioClase` representa una sesion
  concreta con dia, rango y aula; no duplicar horarios por perspectiva.
- `/horarios` es el planificador general y proyecta el mismo borrador por
  `Curso | Docente | Aula`. Cursos y Docentes solo enlazan al planificador o al
  editor contextual; no mantienen una segunda fuente de horarios.
- Las bajas del guardado batch deben ser explicitas y logicas. No reemplazar el
  periodo mediante `deleteMany` seguido de recreacion masiva.
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
- Crear y ejecutar pruebas unicamente cuando el cambio afecte el nucleo de
  persistencia: repositorios, mapeo de datos, transacciones, migraciones o
  guardado. No crear ni ejecutar pruebas de UI, widgets, responsive, navegacion
  o textos.
- Antes de cerrar cambios de UI, ejecutar solamente `flutter analyze`. No usar
  `flutter build` como sustituto del analisis estatico.

## Edicion

- Mantener los cambios acotados al pedido y respetar modificaciones existentes.
- Usar `apply_patch` para ediciones manuales.
- Preferir componentes compartidos sobre duplicacion entre pantallas.
- No revertir archivos o cambios ajenos sin una solicitud explicita.
