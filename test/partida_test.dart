import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/partida.dart';

List<Jugador> crearJugadores() => [
  Jugador(asiento: 1, nombre: 'J1'),
  Jugador(asiento: 2, nombre: 'J2'),
  Jugador(asiento: 3, nombre: 'J3'),
  Jugador(asiento: 4, nombre: 'J4'),
];

void main() {
  group('Partida.repartir', () {
    test('reparte 7 fichas a cada jugador (28 en total)', () {
      final jugadores = crearJugadores();
      Partida.repartir(jugadores, random: Random(42));

      for (final j in jugadores) {
        expect(j.mano.cantidadFichas, 7);
      }
    });

    test('lanza error si no se le dan exactamente 4 jugadores', () {
      final jugadores = crearJugadores().sublist(0, 3);
      expect(() => Partida.repartir(jugadores), throwsArgumentError);
    });

    test('lanza error si los asientos no son 1,2,3,4 sin repetir', () {
      final jugadores = [
        Jugador(asiento: 1, nombre: 'A'),
        Jugador(asiento: 1, nombre: 'B'), // repetido
        Jugador(asiento: 3, nombre: 'C'),
        Jugador(asiento: 4, nombre: 'D'),
      ];
      expect(() => Partida.repartir(jugadores), throwsArgumentError);
    });

    test('el jugador con la mula 6-6 empieza la partida', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));

      final ganadorDeLaMula = jugadores.firstWhere(
        (j) => j.mano.tieneFicha(Ficha(6, 6)),
      );

      expect(partida.jugadorEnTurno, equals(ganadorDeLaMula));
    });

    test('la mesa empieza vacía', () {
      final partida = Partida.repartir(crearJugadores(), random: Random(1));
      expect(partida.mesa.estaVacia, isTrue);
    });
  });

  group('Partida - avanzar turno', () {
    test('el turno avanza en orden 1 -> 2 -> 3 -> 4 -> 1', () {
      // Forzamos que empiece el asiento 1 usando una semilla fija
      // y verificando cuál asiento quedó con el turno inicial.
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));

      final asientoInicial = partida.jugadorEnTurno.asiento;
      final ordenEsperado = List.generate(
        4,
        (i) => ((asientoInicial - 1 + i) % 4) + 1,
      );

      for (var i = 0; i < 4; i++) {
        expect(partida.jugadorEnTurno.asiento, ordenEsperado[i]);
        partida.avanzarTurno();
      }

      // Después de 4 avances, debe regresar al asiento inicial.
      expect(partida.jugadorEnTurno.asiento, asientoInicial);
    });
  });
}
