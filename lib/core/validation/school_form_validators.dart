import 'package:flutter/services.dart';

abstract final class SchoolFormValidators {
  static final RegExp _personName = RegExp(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ '\-][A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$",
  );
  static final RegExp _document = RegExp(
    r'^[A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ]+(?:[ .\-][A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ]+)*$',
  );
  static final RegExp _phone = RegExp(r'^\+?[0-9][0-9 ()\-]{6,18}$');
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static final TextInputFormatter personNameFormatter =
      FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ '\-]"));

  static final TextInputFormatter uppercaseFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final uppercase = newValue.text.toUpperCase();
        return newValue.copyWith(
          text: uppercase,
          selection: newValue.selection,
          composing: TextRange.empty,
        );
      });

  static String normalizeText(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String normalizeUpper(String value) =>
      normalizeText(value).toUpperCase();

  static String normalizeLower(String value) =>
      normalizeText(value).toLowerCase();

  static String? personName(String? value, {required String label}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Ingresa $label.';
    if (normalized.length < 2) return 'Debe tener al menos 2 caracteres.';
    if (normalized.length > 120) return 'No puede superar 120 caracteres.';
    if (!_personName.hasMatch(normalized)) {
      return 'Usa solo letras, espacios, apóstrofes o guiones.';
    }
    return null;
  }

  static String? document(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;
    if (normalized.length < 4 || normalized.length > 30) {
      return 'Usa entre 4 y 30 caracteres.';
    }
    return _document.hasMatch(normalized) ? null : 'Documento no válido.';
  }

  static String? phone(String? value, {required String label}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;
    return _phone.hasMatch(normalized) ? null : 'Ingresa un $label válido.';
  }

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return null;
    return _email.hasMatch(normalized) ? null : 'Correo no válido.';
  }

  static String? requiredText(
    String? value, {
    required String label,
    int maxLength = 120,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Ingresa $label.';
    if (normalized.length > maxLength) {
      return 'No puede superar $maxLength caracteres.';
    }
    return null;
  }
}
