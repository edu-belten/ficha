import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/registro_pase.dart';
import 'package:ficha_app/ia/inferencia_jugadores.dart';

void main() {
  group('InferenciaJugadores', () {
    test('sin historial, regresa un mapa vacío', () {
      final resultado = InferenciaJugadores.numerosDescartados([]);
      expect(resultado, isEmpty);
    });

    test('un pase agrega ambos extremos al conjunto de descartados', () {
      final rival = Jugador(asiento: 2, nombre: 'Rival');
      final historial = [
        RegistroPase(jugador: rival, extremoIzquierdo: 2, extremoDerecho: 5),
      ];

      final resultado = InferenciaJugadores.numerosDescartados(historial);

      expect(resultado[rival], equals({2, 5}));
    });

    test(
      'varios pases del mismo jugador acumulan descartados sin duplicar',
      () {
        final rival = Jugador(asiento: 2, nombre: 'Rival');
        final historial = [
          RegistroPase(jugador: rival, extremoIzquierdo: 2, extremoDerecho: 5),
          RegistroPase(jugador: rival, extremoIzquierdo: 2, extremoDerecho: 6),
        ];

        final resultado = InferenciaJugadores.numerosDescartados(historial);

        expect(resultado[rival], equals({2, 5, 6}));
      },
    );

    test('distingue correctamente entre distintos jugadores', () {
      final rival1 = Jugador(asiento: 2, nombre: 'R1');
      final rival2 = Jugador(asiento: 4, nombre: 'R2');
      final historial = [
        RegistroPase(jugador: rival1, extremoIzquierdo: 1, extremoDerecho: 2),
        RegistroPase(jugador: rival2, extremoIzquierdo: 5, extremoDerecho: 6),
      ];

      final resultado = InferenciaJugadores.numerosDescartados(historial);

      expect(resultado[rival1], equals({1, 2}));
      expect(resultado[rival2], equals({5, 6}));
    });
  });
}
