#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly API_BASE_URL="https://soft-miranda-luisfluoxetina-b6930636.koyeb.app/api/v1"
readonly APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
readonly KEY_PROPERTIES_PATH="$PROJECT_DIR/android/key.properties"

cd "$PROJECT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: Flutter no esta disponible en PATH." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl no esta disponible en PATH." >&2
  exit 1
fi

if [[ ! -f "$KEY_PROPERTIES_PATH" ]]; then
  echo "Error: falta android/key.properties para firmar la APK release." >&2
  exit 1
fi

version="$(awk '/^version: / { print $2; exit }' pubspec.yaml)"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]]; then
  echo "Error: la version de pubspec.yaml no tiene el formato X.Y.Z+N." >&2
  exit 1
fi

echo "Comprobando API productiva..."
curl --fail --silent --show-error \
  --connect-timeout 15 \
  --max-time 30 \
  "$API_BASE_URL/health" >/dev/null

echo "Preparando dependencias..."
flutter pub get

echo "Ejecutando analisis estatico..."
flutter analyze

echo "Compilando APK release $version contra la API productiva..."
flutter build apk --release --dart-define="API_BASE_URL=$API_BASE_URL"

if [[ ! -f "$APK_PATH" ]]; then
  echo "Error: Flutter no genero $APK_PATH." >&2
  exit 1
fi

android_sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/home/nini/Android/Sdk}}"
build_tools="$(find "$android_sdk/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
apksigner="$build_tools/apksigner"
if [[ ! -x "$apksigner" ]]; then
  echo "Error: no se encontro apksigner en el Android SDK." >&2
  exit 1
fi

if ! "$apksigner" verify "$APK_PATH"; then
  echo "Error: la APK release no tiene una firma valida." >&2
  exit 1
fi

echo "APK generada: $APK_PATH"
echo "Firma: verificada"
echo "Version: $version"
echo "Tamano: $(du -h "$APK_PATH" | awk '{ print $1 }')"
sha256sum "$APK_PATH"
