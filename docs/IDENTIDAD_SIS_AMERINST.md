# Cambio de identidad a SIS AMERINST

Implementado el 11 de septiembre de 2026 en Flutter y en el backend NestJS local.

## Identidad y recursos

- Sistema: **SIS AMERINST**.
- Institución: **Unidad Educativa Evangélica Metodista AMERINST**, Cobija.
- Colores: azul `#142454`, azul oscuro `#08163D`, rojo institucional `#C81932`
  y blanco. Los estados de éxito, advertencia y error mantienen su significado.
- Flutter centraliza textos y rutas en `lib/core/config/app_brand.dart`.
  El backend usa `src/comun/configuracion/brand.ts`.
- Escudo maestro: `assets/branding/amerinst-crest.png`. Fue restaurado mediante
  la herramienta integrada ImageGen a partir de la imagen aportada por el
  usuario, retirando el botón de cámara y completando el contorno recortado.
  Es una reconstrucción gráfica, no un original vectorial certificado: los
  detalles que no estaban completos en la referencia no pueden considerarse
  una reproducción documental exacta.
- Instrucción de generación: restaurar el escudo completo sobre blanco,
  conservar UNIDAD EDUCATIVA EVANGELICA METODISTA, AMERINST, COBIJA,
  MENTE, ALMA y CUERPO, anillos, triángulo, libro, pluma y follaje; retirar
  elementos de captura y no incorporar el nombre del sistema dentro del escudo.
- Las plantillas `amerinst-credential-front.svg` y
  `amerinst-credential-back.svg` son fuentes editables propias. Sus PNG son
  exportaciones usadas por Flutter y PDF. Las bandas de las cabeceras se
  dibujan junto al texto para impedir desajustes entre la imagen y las letras.
- Los iconos PNG de Android/Linux y el ICO multirresolución de Windows derivan
  del mismo maestro. Android incluye icono adaptativo con margen seguro y splash.
- Se retiraron los antiguos `baker-*`, la escena de campus y las dos plantillas
  de credenciales sustituidas. Los recursos Web heredados se limpiaron sin
  ejecutar, compilar ni habilitar Flutter Web.

## Cobertura del cambio

Se actualizaron acceso, arranque, navegación, marca de agua, mensajes de cámara,
nombres de respaldo, títulos nativos, metadatos de Windows, paquete Dart
`sis_amerinst`, imports y clase `SisAmerinstApp`. El acceso usa una composición
institucional con el escudo en lugar de atribuir una fotografía ajena al colegio.

Credenciales: anverso, reverso, vista previa, nombre de impresión, nombre de
descarga, autor del PDF y textos institucionales. Se conservan las medidas
85,6 × 54 mm, los datos del estudiante y el contenido QR emitido por la API.

Reportes: título, institución, escudo, colores, metadatos y nombre de descarga
en Flutter y backend. `nest-cli.json` incluye el escudo en `dist/assets/branding`
y la imagen queda disponible también al empaquetar `dist` en el contenedor.
No cambian consultas, permisos ni resultados estadísticos.

## Compatibilidad y referencias antiguas intencionales

- Android conserva `com.nini.asisteqr_baker`, su namespace y la configuración
  local de firma. El nombre visible y el icono ya son SIS AMERINST.
- Linux conserva `APPLICATION_ID` porque identifica también el almacén
  libsecret. Su ejecutable pasa a `sis_amerinst`.
- Windows usa `sis_amerinst.exe` y metadatos nuevos, conservando
  `STORAGE_PREFIX=asisteqr_baker` para reutilizar la clave de cifrado del plugin.
- `WindowsSessionMigration` mueve únicamente el archivo cifrado de sesión
  desde la ruta anterior de Roaming AppData. No descifra ni imprime su contenido,
  no sobrescribe una sesión nueva y deja un marcador persistente para evitar
  recuperar una sesión antigua después de cerrar sesión. Esta adaptación está
  basada en `flutter_secure_storage_windows` 4.2.2 del lockfile actual.
- La clave `asisteqr_session_token` y el protocolo QR `AQB1` siguen vigentes.
  Reimprimir una credencial no renueva ni revoca el QR.
- Los directorios reales de trabajo, nombre de base PostgreSQL, migraciones
  históricas y nombres técnicos de las instrucciones locales siguen siendo
  referencias válidas. No se cambió la URL de API ni se ejecutó la semilla.
- Nombres/correos almacenados de personas, fotografías personales, capturas
  históricas y documentación de auditorías no se sustituyen por branding.
  Pueden contener la denominación anterior; no son assets institucionales activos.

## Verificación

- `flutter pub get` y `flutter analyze`: sin incidencias en el análisis.
- Seis pruebas focalizadas de migración de sesión, invalidación HTTP y
  repositorio de autenticación pasaron sobre los mismos archivos fuente,
  enlazados desde un paquete temporal con dependencias mínimas. La invocación
  inicial desde el proyecto activaba una descarga/compilación de OpenCV ajena
  al cambio y se detuvo. No se ejecutaron pruebas de widgets ni responsive.
- Se corrigió el fixture de autenticación para usar un ID entero, coherente con
  `Usuario.id` y el contrato actual; no se cambió el mapeo de producción.
- Backend: `npm run lint -- --no-fix` y `npx --no-install nest build` pasaron.
- Se renderizaron ambos modos de credenciales con cinco estudiantes de
  demostración, incluyendo nombre largo, ausencia de fotografía y última fila
  impar. Se revisaron las páginas y se confirmó el autor SIS AMERINST y la
  ausencia de marca antigua en el texto. El renderer se ejecutó sin cambiar
  su layout, sustituyendo únicamente rootBundle por lectura de assets desde disco.
- Se renderizaron reportes del servicio real con 0 y 35 filas de demostración,
  usando una fuente de datos en memoria sin acceder a PostgreSQL. Se revisaron
  encabezado, escudo, lista vacía y salto de página.
- La revisión responsive de este cambio es estructural: acceso desplazable,
  composición lateral solo desde 900 px y credenciales escaladas desde su lienzo
  fijo. No equivale a una prueba visual en dispositivos a 320/390/1280 px.
- No se generaron APK, EXE ni MSI, no se desplegó y no se probó una actualización
  real en Windows/Android. Antes de una entrega se debe incrementar la versión
  y validar instalación, lectura de sesión y escaneo en los destinos reales.

Los cambios locales previos de README, firma Android, URL release y versión
`1.0.3+4` se conservaron. Esta tarea no publica una nueva versión.
