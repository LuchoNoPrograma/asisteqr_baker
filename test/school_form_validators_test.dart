import 'package:asisteqr_baker/core/validation/school_form_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SchoolFormValidators.personName', () {
    test('acepta nombres escolares con acentos, espacios y guiones', () {
      expect(
        SchoolFormValidators.personName(
          "María-José O'Connor",
          label: 'los nombres',
        ),
        isNull,
      );
    });

    test('rechaza números y símbolos en nombres', () {
      expect(
        SchoolFormValidators.personName('Juan 2', label: 'los nombres'),
        isNotNull,
      );
    });
  });

  test('valida teléfonos bolivianos y formatos internacionales', () {
    expect(SchoolFormValidators.phone('71234567', label: 'teléfono'), isNull);
    expect(
      SchoolFormValidators.phone('+591 71234567', label: 'teléfono'),
      isNull,
    );
    expect(
      SchoolFormValidators.phone('teléfono', label: 'teléfono'),
      isNotNull,
    );
  });

  test('recorta espacios y normaliza los textos escolares en mayúsculas', () {
    expect(
      SchoolFormValidators.normalizeUpper('  María   Elena  '),
      'MARÍA ELENA',
    );
    expect(
      SchoolFormValidators.normalizeLower('  DOCENTE@BAKER.EDU.BO  '),
      'docente@baker.edu.bo',
    );
  });
}
