import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/sesion.dart';

List<Jugador> crearJugadores() => [
  Jugador(asiento: 1, nombre: 'J1'),
  Jugador(asiento: 2, nombre: 'J2'),
  Jugador(asiento: 3, nombre: 'J3'),
  Jugador(asiento: 4, nombre: 'J4'),
];

/// Fuerza que la partida actual de [sesion] termine por dominación,
/// con el jugador en turno (el salidor) cerrando de inmediato con una
/// sola ficha, y con el equipo rival cargando exactamente
/// [puntosParaGanadorInicial] puntos en mano.
///
/// Regresa los puntos realmente otorgados (deberían coincidir).
int jugarPartidaForzada(
  Sesion sesion, {
  required int puntosParaGanadorInicial,
}) {
  final partida = sesion.partidaActual!;
  final jugadorInicial = partida.jugadorEnTurno;

  // Vaciamos las 4 manos para controlar el escenario por completo.
  for (final j in partida.jugadores) {
    for (final f in List.of(j.mano.fichas)) {
      j.mano.quitar(f);
    }
  }

  final fichaSalida = Ficha(0, 0);
  jugadorInicial.mano.agregar(fichaSalida);

  final equipoRival = partida.equipoDe(jugadorInicial) == partida.equipoA
      ? partida.equipoB
      : partida.equipoA;

  var restante = puntosParaGanadorInicial;
  while (restante > 12) {
    equipoRival.jugadorA.mano.agregar(Ficha(6, 6));
    restante -= 12;
  }
  if (restante > 0) {
    final a = restante > 6 ? 6 : restante;
    final b = restante - a;
    equipoRival.jugadorA.mano.agregar(Ficha(a, b));
  }

  partida.jugar(jugadorInicial, fichaSalida);
  sesion.registrarResultadoPartidaActual();

  return partida.resultado!.puntosGanados;
}

void main() {
  group('Sesion - iniciar partidas', () {
    test('iniciarPrimeraPartida crea la partida y determina quién sale', () {
      final sesion = Sesion(crearJugadores());
      sesion.iniciarPrimeraPartida(random: Random(42));

      expect(sesion.partidaActual, isNotNull);
      expect(sesion.partidaActual!.mesa.estaVacia, isTrue);
    });

    test('lanza error si se intenta iniciar la primera partida dos veces', () {
      final sesion = Sesion(crearJugadores());
      sesion.iniciarPrimeraPartida(random: Random(42));

      expect(
        () => sesion.iniciarPrimeraPartida(random: Random(1)),
        throwsStateError,
      );
    });

    test(
      'lanza error si se intenta iniciar la siguiente partida sin terminar la actual',
      () {
        final sesion = Sesion(crearJugadores());
        sesion.iniciarPrimeraPartida(random: Random(42));

        final cualquiera = sesion.jugadores.first;
        expect(
          () => sesion.iniciarSiguientePartida(cualquiera),
          throwsStateError,
        );
      },
    );
  });

  group('Sesion - acumulación de marcador entre partidas', () {
    test('el marcador persiste y crece entre partidas sucesivas', () {
      final sesion = Sesion(crearJugadores());
      sesion.iniciarPrimeraPartida(random: Random(42));

      jugarPartidaForzada(sesion, puntosParaGanadorInicial: 30);

      final equipoLider = sesion.equipoA.marcadorAcumulado == 30
          ? sesion.equipoA
          : sesion.equipoB;
      expect(equipoLider.marcadorAcumulado, 30);
      expect(sesion.haTerminado, isFalse);

      // El mismo equipo vuelve a salir y a ganar en la siguiente partida.
      sesion.iniciarSiguientePartida(equipoLider.jugadorA, random: Random(7));
      jugarPartidaForzada(sesion, puntosParaGanadorInicial: 20);

      expect(equipoLider.marcadorAcumulado, 50);
      expect(sesion.historial.length, 2);
    });

    test('detecta cuando un equipo llega a 100 y termina la sesión', () {
      final sesion = Sesion(crearJugadores());
      sesion.iniciarPrimeraPartida(random: Random(42));

      jugarPartidaForzada(sesion, puntosParaGanadorInicial: 40);
      final equipoLider = sesion.equipoA.marcadorAcumulado == 40
          ? sesion.equipoA
          : sesion.equipoB;

      sesion.iniciarSiguientePartida(equipoLider.jugadorA, random: Random(7));
      jugarPartidaForzada(sesion, puntosParaGanadorInicial: 40);
      expect(equipoLider.marcadorAcumulado, 80);
      expect(sesion.haTerminado, isFalse);

      sesion.iniciarSiguientePartida(equipoLider.jugadorA, random: Random(11));
      jugarPartidaForzada(sesion, puntosParaGanadorInicial: 25);

      expect(equipoLider.marcadorAcumulado, 105);
      expect(sesion.haTerminado, isTrue);
      expect(sesion.equipoGanadorSesion, equals(equipoLider));
    });
  });

  group('Sesion - "se raya"', () {
    test(
      'empate exacto resetea ambos marcadores y duplica el multiplicador',
      () {
        final sesion = Sesion(crearJugadores());
        sesion.iniciarPrimeraPartida(random: Random(42));

        jugarPartidaForzada(sesion, puntosParaGanadorInicial: 30);
        final equipoGanador1 = sesion.equipoA.marcadorAcumulado == 30
            ? sesion.equipoA
            : sesion.equipoB;
        final equipoPerdedor1 = equipoGanador1 == sesion.equipoA
            ? sesion.equipoB
            : sesion.equipoA;

        expect(sesion.multiplicadorRayada, 1);

        // El equipo que iba perdiendo ahora gana, empatando el marcador.
        sesion.iniciarSiguientePartida(
          equipoPerdedor1.jugadorA,
          random: Random(3),
        );
        jugarPartidaForzada(sesion, puntosParaGanadorInicial: 30);

        expect(sesion.equipoA.marcadorAcumulado, 0);
        expect(sesion.equipoB.marcadorAcumulado, 0);
        expect(sesion.multiplicadorRayada, 2);
        expect(sesion.haTerminado, isFalse);
      },
    );

    test(
      'una segunda rayada en la misma sesión duplica el multiplicador de nuevo',
      () {
        final sesion = Sesion(crearJugadores());
        sesion.iniciarPrimeraPartida(random: Random(42));

        jugarPartidaForzada(sesion, puntosParaGanadorInicial: 15);
        final equipoGanador1 = sesion.equipoA.marcadorAcumulado == 15
            ? sesion.equipoA
            : sesion.equipoB;
        final equipoPerdedor1 = equipoGanador1 == sesion.equipoA
            ? sesion.equipoB
            : sesion.equipoA;

        sesion.iniciarSiguientePartida(
          equipoPerdedor1.jugadorA,
          random: Random(3),
        );
        jugarPartidaForzada(sesion, puntosParaGanadorInicial: 15);
        expect(sesion.multiplicadorRayada, 2); // primera rayada

        // Repetimos el patrón para forzar una segunda rayada.
        sesion.iniciarSiguientePartida(
          equipoGanador1.jugadorA,
          random: Random(9),
        );
        jugarPartidaForzada(sesion, puntosParaGanadorInicial: 10);

        sesion.iniciarSiguientePartida(
          equipoPerdedor1.jugadorA,
          random: Random(13),
        );
        jugarPartidaForzada(sesion, puntosParaGanadorInicial: 10);

        expect(sesion.multiplicadorRayada, 4); // segunda rayada
        expect(sesion.equipoA.marcadorAcumulado, 0);
        expect(sesion.equipoB.marcadorAcumulado, 0);
      },
    );
  });
}
