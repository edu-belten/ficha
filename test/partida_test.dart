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

      expect(partida.jugadorEnTurno.asiento, asientoInicial);
    });
  });

  group('Partida - jugar()', () {
    test('lanza error si no es el turno del jugador', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));

      final otroAsiento = jugadores.firstWhere(
        (j) => j.asiento != partida.jugadorEnTurno.asiento,
      );
      final ficha = otroAsiento.mano.fichas.first;

      expect(() => partida.jugar(otroAsiento, ficha), throwsStateError);
    });

    test('lanza error si el jugador no tiene esa ficha en mano', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final actual = partida.jugadorEnTurno;

      final fichaAjena = jugadores
          .firstWhere((j) => j != actual)
          .mano
          .fichas
          .firstWhere((f) => !actual.mano.tieneFicha(f));

      expect(() => partida.jugar(actual, fichaAjena), throwsArgumentError);
    });

    test(
      'la primera jugada (salida) no requiere extremo y quita la ficha de la mano',
      () {
        final jugadores = crearJugadores();
        final partida = Partida.repartir(jugadores, random: Random(42));
        final actual = partida.jugadorEnTurno;
        final ficha = actual.mano.fichas.first;
        final cantidadAntes = actual.mano.cantidadFichas;

        partida.jugar(actual, ficha);

        expect(partida.mesa.estaVacia, isFalse);
        expect(actual.mano.cantidadFichas, cantidadAntes - 1);
        expect(actual.mano.tieneFicha(ficha), isFalse);
      },
    );

    test('jugar() avanza el turno al siguiente jugador', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final actual = partida.jugadorEnTurno;
      final asientoAntes = actual.asiento;
      final ficha = actual.mano.fichas.first;

      partida.jugar(actual, ficha);

      final asientoEsperado = (asientoAntes % 4) + 1;
      expect(partida.jugadorEnTurno.asiento, asientoEsperado);
    });

    test(
      'lanza error si se juega sin extremo cuando la mesa ya tiene fichas',
      () {
        final jugadores = crearJugadores();
        final partida = Partida.repartir(jugadores, random: Random(42));
        final j1 = partida.jugadorEnTurno;
        partida.jugar(j1, j1.mano.fichas.first);

        final j2 = partida.jugadorEnTurno;
        final fichaJugable = j2.mano.fichas.firstWhere(
          (f) => partida.mesa.sePuedeJugar(f),
          orElse: () => j2.mano.fichas.first,
        );

        expect(() => partida.jugar(j2, fichaJugable), throwsArgumentError);
      },
    );
  });

  group('Partida - pasar()', () {
    test('lanza error si no es el turno del jugador', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final otroAsiento = jugadores.firstWhere(
        (j) => j.asiento != partida.jugadorEnTurno.asiento,
      );

      expect(() => partida.pasar(otroAsiento), throwsStateError);
    });

    test('pasar() avanza el turno cuando el jugador no tiene jugada legal', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final j1 = partida.jugadorEnTurno;
      partida.jugar(j1, j1.mano.fichas.first);

      final j2 = partida.jugadorEnTurno;

      final fichasOriginales = List.of(j2.mano.fichas);
      for (final f in fichasOriginales) {
        j2.mano.quitar(f);
      }
      final extremos = {
        partida.mesa.extremoIzquierdo,
        partida.mesa.extremoDerecho,
      };
      final valorImposible = [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
      ].firstWhere((v) => !extremos.contains(v));
      j2.mano.agregar(Ficha(valorImposible, valorImposible));

      final asientoAntes = j2.asiento;
      partida.pasar(j2);
      expect(partida.jugadorEnTurno.asiento, (asientoAntes % 4) + 1);
    });

    test('lanza error (pase en falso) si el jugador sí tenía jugada legal', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final j1 = partida.jugadorEnTurno;
      partida.jugar(j1, j1.mano.fichas.first);

      final j2 = partida.jugadorEnTurno;
      final extremo = partida.mesa.extremoIzquierdo!;
      j2.mano.agregar(Ficha(extremo, 6));

      expect(() => partida.pasar(j2), throwsStateError);
    });
  });
}
