import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';

void main() {
  group('Ficha', () {
    test('guarda los valores en orden canónico (menor primero)', () {
      final f1 = Ficha(5, 3);
      final f2 = Ficha(3, 5);
      expect(f1.a, 3);
      expect(f1.b, 5);
      expect(f1, equals(f2)); // deben ser "la misma" ficha
    });

    test('detecta correctamente si es mula', () {
      expect(Ficha(4, 4).esMula, isTrue);
      expect(Ficha(4, 5).esMula, isFalse);
    });

    test('calcula el valor en puntos correctamente', () {
      expect(Ficha(3, 5).valor, 8);
      expect(Ficha(6, 6).valor, 12);
      expect(Ficha(0, 0).valor, 0);
    });

    test('calza() detecta si la ficha es jugable contra un extremo', () {
      final f = Ficha(3, 5);
      expect(f.calza(3), isTrue);
      expect(f.calza(5), isTrue);
      expect(f.calza(6), isFalse);
    });

    test('extremoOpuesto() regresa el número correcto tras jugar', () {
      final f = Ficha(3, 5);
      expect(f.extremoOpuesto(3), 5);
      expect(f.extremoOpuesto(5), 3);
    });

    test('extremoOpuesto() lanza error si el extremo no calza', () {
      final f = Ficha(3, 5);
      expect(() => f.extremoOpuesto(6), throwsArgumentError);
    });
  });
}
