import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/ia/analisis_cierre.dart';

void main() {
  group('AnalisisCierre', () {
    test('conviene forzar bloqueo cuando la mano propia es liviana', () {
      // Restante = 168 - 100 = 68; mitad = 34. Mi mano pesa 10 < 34.
      final conviene = AnalisisCierre.convieneForzarBloqueo(
        pintasEnMiMano: 10,
        pintasYaJugadasEnMesa: 100,
      );
      expect(conviene, isTrue);
    });

    test('no conviene forzar bloqueo cuando la mano propia es pesada', () {
      // Restante = 168 - 100 = 68; mitad = 34. Mi mano pesa 40 > 34.
      final conviene = AnalisisCierre.convieneForzarBloqueo(
        pintasEnMiMano: 40,
        pintasYaJugadasEnMesa: 100,
      );
      expect(conviene, isFalse);
    });

    test('bonoPorAgotado es 0 si el número no está agotado', () {
      final bono = AnalisisCierre.bonoPorAgotado(
        numeroAgotado: false,
        pintasEnMiMano: 10,
        pintasYaJugadasEnMesa: 100,
      );
      expect(bono, 0);
    });

    test('bonoPorAgotado es positivo cuando conviene forzar bloqueo', () {
      final bono = AnalisisCierre.bonoPorAgotado(
        numeroAgotado: true,
        pintasEnMiMano: 10,
        pintasYaJugadasEnMesa: 100,
      );
      expect(bono, greaterThan(0));
    });

    test('bonoPorAgotado es negativo cuando NO conviene forzar bloqueo', () {
      final bono = AnalisisCierre.bonoPorAgotado(
        numeroAgotado: true,
        pintasEnMiMano: 40,
        pintasYaJugadasEnMesa: 100,
      );
      expect(bono, lessThan(0));
    });
  });
}
