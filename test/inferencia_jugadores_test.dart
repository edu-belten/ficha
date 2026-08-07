import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/mesa.dart';
import 'package:ficha_app/models/registro_jugada.dart';
import 'package:ficha_app/models/registro_pase.dart';
import 'package:ficha_app/ia/inferencia_jugadores.dart';

void main() {
  group('InferenciaJugadores.numerosDescartados', () {
    test('sin historial, regresa un mapa vacío', () {
      expect(InferenciaJugadores.numerosDescartados([]), isEmpty);
    });

    test('un pase agrega ambos extremos al conjunto de descartados', () {
      final rival = Jugador(asiento: 2, nombre: 'Rival');
      final historial = [
        RegistroPase(jugador: rival, extremoIzquierdo: 2, extremoDerecho: 5),
      ];
      final resultado = InferenciaJugadores.numerosDescartados(historial);
      expect(resultado[rival], equals({2, 5}));
    });

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

  group('InferenciaJugadores.numerosReforzados', () {
    test('sin historial, regresa un mapa vacío', () {
      expect(InferenciaJugadores.numerosReforzados([]), isEmpty);
    });

    test(
      'un solo uso de un número no cuenta como reforzado (umbral default 2)',
      () {
        final rival = Jugador(asiento: 2, nombre: 'Rival');
        final historial = [
          RegistroJugada(jugador: rival, ficha: Ficha(3, 5), extremo: null),
        ];
        final resultado = InferenciaJugadores.numerosReforzados(historial);
        expect(resultado[rival], isNull);
      },
    );

    test('jugar el mismo número dos veces sí cuenta como reforzado', () {
      final rival = Jugador(asiento: 2, nombre: 'Rival');
      final historial = [
        RegistroJugada(jugador: rival, ficha: Ficha(3, 5), extremo: null),
        RegistroJugada(
          jugador: rival,
          ficha: Ficha(3, 6),
          extremo: Extremo.izquierdo,
        ),
      ];
      final resultado = InferenciaJugadores.numerosReforzados(historial);
      expect(resultado[rival], equals({3}));
    });

    test('una mula cuenta una sola vez su número, no dos', () {
      final rival = Jugador(asiento: 2, nombre: 'Rival');
      // Jugar la mula 4-4 una vez: cuenta como una aparición del 4, no dos.
      final historial = [
        RegistroJugada(jugador: rival, ficha: Ficha(4, 4), extremo: null),
      ];
      final resultado = InferenciaJugadores.numerosReforzados(historial);
      expect(resultado[rival], isNull); // solo 1 aparición, no llega al umbral
    });

    test('respeta un umbral personalizado', () {
      final rival = Jugador(asiento: 2, nombre: 'Rival');
      final historial = [
        RegistroJugada(jugador: rival, ficha: Ficha(3, 5), extremo: null),
        RegistroJugada(
          jugador: rival,
          ficha: Ficha(3, 6),
          extremo: Extremo.izquierdo,
        ),
      ];
      final resultado = InferenciaJugadores.numerosReforzados(
        historial,
        umbral: 3,
      );
      expect(resultado[rival], isNull); // solo 2 apariciones, umbral pide 3
    });
  });
}
