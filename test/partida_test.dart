import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/partida.dart';
import 'package:ficha_app/models/resultado_partida.dart';

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

    test('arma los equipos correctamente (1+3 y 2+4)', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));

      final j1 = jugadores.firstWhere((j) => j.asiento == 1);
      final j2 = jugadores.firstWhere((j) => j.asiento == 2);
      final j3 = jugadores.firstWhere((j) => j.asiento == 3);
      final j4 = jugadores.firstWhere((j) => j.asiento == 4);

      expect(partida.equipoA.tieneJugador(j1), isTrue);
      expect(partida.equipoA.tieneJugador(j3), isTrue);
      expect(partida.equipoA.tieneJugador(j2), isFalse);

      expect(partida.equipoB.tieneJugador(j2), isTrue);
      expect(partida.equipoB.tieneJugador(j4), isTrue);
      expect(partida.equipoB.tieneJugador(j1), isFalse);
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

    test(
      'pasar() avanza el turno y regresa false cuando no hay jugada legal',
      () {
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
        final fueFalso = partida.pasar(j2);

        expect(fueFalso, isFalse);
        expect(partida.jugadorEnTurno.asiento, (asientoAntes % 4) + 1);
        expect(partida.equipoDe(j2).marcadorAcumulado, 0);
      },
    );

    test(
      'pase en falso: regresa true, penaliza +25 al equipo, y el turno igual avanza',
      () {
        final jugadores = crearJugadores();
        final partida = Partida.repartir(jugadores, random: Random(42));
        final j1 = partida.jugadorEnTurno;
        partida.jugar(j1, j1.mano.fichas.first);

        final j2 = partida.jugadorEnTurno;
        final extremo = partida.mesa.extremoIzquierdo!;
        j2.mano.agregar(Ficha(extremo, 6)); // garantiza jugada legal

        final equipoDeJ2 = partida.equipoDe(j2);
        final marcadorAntes = equipoDeJ2.marcadorAcumulado;
        final asientoAntes = j2.asiento;

        final fueFalso = partida.pasar(j2);

        expect(fueFalso, isTrue);
        expect(equipoDeJ2.marcadorAcumulado, marcadorAntes + 25);
        expect(partida.jugadorEnTurno.asiento, (asientoAntes % 4) + 1);
      },
    );
  });

  group('Partida - equipoDe()', () {
    test('identifica correctamente el equipo de cada jugador', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));

      final j1 = jugadores.firstWhere((j) => j.asiento == 1);
      final j2 = jugadores.firstWhere((j) => j.asiento == 2);

      expect(partida.equipoDe(j1), equals(partida.equipoA));
      expect(partida.equipoDe(j2), equals(partida.equipoB));
    });
  });

  group('Partida - fin de partida por dominación', () {
    test(
      'termina y calcula puntos correctamente cuando un jugador se queda sin fichas',
      () {
        final jugadores = crearJugadores();
        final partida = Partida.repartir(jugadores, random: Random(42));
        final jugadorInicial = partida.jugadorEnTurno;

        // Forzamos que jugadorInicial tenga una sola ficha: su salida.
        for (final f in List.of(jugadorInicial.mano.fichas)) {
          jugadorInicial.mano.quitar(f);
        }
        final fichaSalida = Ficha(1, 2);
        jugadorInicial.mano.agregar(fichaSalida);

        final equipoGanadorEsperado = partida.equipoDe(jugadorInicial);
        final equipoRival = equipoGanadorEsperado == partida.equipoA
            ? partida.equipoB
            : partida.equipoA;
        final puntosEsperados = equipoRival.totalPintasEnMano;

        partida.jugar(jugadorInicial, fichaSalida);

        expect(partida.haTerminado, isTrue);
        expect(partida.resultado!.tipoCierre, TipoCierre.dominacion);
        expect(partida.resultado!.equipoGanador, equals(equipoGanadorEsperado));
        expect(partida.resultado!.equipoPerdedor, equals(equipoRival));
        expect(partida.resultado!.puntosGanados, puntosEsperados);
        expect(equipoGanadorEsperado.marcadorAcumulado, puntosEsperados);
      },
    );

    test('lanza error si se intenta jugar o pasar después de que terminó', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final jugadorInicial = partida.jugadorEnTurno;

      for (final f in List.of(jugadorInicial.mano.fichas)) {
        jugadorInicial.mano.quitar(f);
      }
      final fichaSalida = Ficha(1, 2);
      jugadorInicial.mano.agregar(fichaSalida);
      partida.jugar(jugadorInicial, fichaSalida);

      expect(partida.haTerminado, isTrue);
      expect(() => partida.pasar(jugadorInicial), throwsStateError);
    });
  });

  group('Partida - fin de partida por tranca', () {
    test('detecta tranca, calcula el ganador por menor suma de pintas', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final jugadorInicial = partida.jugadorEnTurno;

      // Vaciamos las 4 manos para construir un escenario controlado.
      for (final j in jugadores) {
        for (final f in List.of(j.mano.fichas)) {
          j.mano.quitar(f);
        }
      }

      // jugadorInicial: sale con 0-1, y le queda una ficha que no calzará
      // después (2-3), para que también quede bloqueado tras jugar.
      jugadorInicial.mano.agregar(Ficha(0, 1));
      jugadorInicial.mano.agregar(Ficha(2, 3)); // 5 pintas

      final partnerInicial = jugadores.firstWhere(
        (j) =>
            j != jugadorInicial &&
            partida.equipoDe(jugadorInicial).tieneJugador(j),
      );
      final rivales = jugadores
          .where((j) => j != jugadorInicial && j != partnerInicial)
          .toList();

      // Ninguna de las fichas restantes contiene 0 ni 1, para que
      // nadie tenga jugada legal después de la salida.
      partnerInicial.mano.agregar(Ficha(2, 4)); // 6 pintas
      rivales[0].mano.agregar(Ficha(2, 2)); // 4 pintas
      rivales[1].mano.agregar(Ficha(3, 4)); // 7 pintas

      final equipoEsperado = partida.equipoDe(jugadorInicial); // 5+6=11
      final equipoRivalEsperado = equipoEsperado == partida.equipoA
          ? partida.equipoB
          : partida.equipoA; // 4+7=11... ver siguiente test para empate

      partida.jugar(jugadorInicial, Ficha(0, 1));

      expect(partida.haTerminado, isTrue);
      expect(partida.resultado!.tipoCierre, TipoCierre.tranca);
      // Con 11 vs 11 esto en realidad cae en empate; ver assertions abajo.
      expect(partida.resultado!.equipoGanador, equals(equipoEsperado));
      expect(partida.resultado!.equipoPerdedor, equals(equipoRivalEsperado));
      expect(partida.resultado!.desempatePorMano, isTrue);
      expect(partida.resultado!.puntosGanados, 11);
      expect(equipoEsperado.marcadorAcumulado, 11);
    });

    test('gana el equipo con menos pintas cuando no hay empate', () {
      final jugadores = crearJugadores();
      final partida = Partida.repartir(jugadores, random: Random(42));
      final jugadorInicial = partida.jugadorEnTurno;

      for (final j in jugadores) {
        for (final f in List.of(j.mano.fichas)) {
          j.mano.quitar(f);
        }
      }

      jugadorInicial.mano.agregar(Ficha(0, 1));
      jugadorInicial.mano.agregar(Ficha(2, 3)); // 5 pintas

      final partnerInicial = jugadores.firstWhere(
        (j) =>
            j != jugadorInicial &&
            partida.equipoDe(jugadorInicial).tieneJugador(j),
      );
      final rivales = jugadores
          .where((j) => j != jugadorInicial && j != partnerInicial)
          .toList();

      partnerInicial.mano.agregar(Ficha(2, 2)); // 4 pintas -> equipo inicial: 9
      rivales[0].mano.agregar(Ficha(4, 4)); // 8 pintas
      rivales[1].mano.agregar(Ficha(5, 5)); // 10 pintas -> equipo rival: 18

      final equipoEsperado = partida.equipoDe(jugadorInicial);
      final equipoRivalEsperado = equipoEsperado == partida.equipoA
          ? partida.equipoB
          : partida.equipoA;

      partida.jugar(jugadorInicial, Ficha(0, 1));

      expect(partida.haTerminado, isTrue);
      expect(partida.resultado!.tipoCierre, TipoCierre.tranca);
      expect(partida.resultado!.equipoGanador, equals(equipoEsperado));
      expect(partida.resultado!.desempatePorMano, isFalse);
      expect(partida.resultado!.puntosGanados, 18); // pintas del rival
      expect(equipoEsperado.marcadorAcumulado, 18);
    });
  });
}
