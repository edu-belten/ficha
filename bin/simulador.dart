import 'dart:math';

import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/mesa.dart';
import 'package:ficha_app/models/partida.dart';
import 'package:ficha_app/models/resultado_partida.dart';
import 'package:ficha_app/models/sesion.dart';

/// Simulador de partidas aleatorias, para validar que el motor nunca
/// rompe sus propias reglas bajo volumen.
///
/// IMPORTANTE: esto NO es la Game AI real (eso es Fase 2) — aquí cada
/// jugador elige al azar entre sus jugadas legales, solo para estresar
/// el motor con miles de partidas y detectar errores que 56 tests
/// manuales no alcanzarían a cubrir.
///
/// Uso: dart run bin/simulador.dart [cantidad_de_sesiones]
/// (por default corre 1000 sesiones si no se especifica)
void main(List<String> args) {
  final cantidadSesiones = args.isNotEmpty ? int.parse(args[0]) : 1000;

  final random = Random();
  var sesionesCompletas = 0;
  var partidasJugadas = 0;
  var cierresPorDominacion = 0;
  var cierresPorTranca = 0;
  var rayadasTotales = 0;
  var erroresInesperados = 0;

  for (var s = 0; s < cantidadSesiones; s++) {
    try {
      final jugadores = [
        Jugador(asiento: 1, nombre: 'J1'),
        Jugador(asiento: 2, nombre: 'J2'),
        Jugador(asiento: 3, nombre: 'J3'),
        Jugador(asiento: 4, nombre: 'J4'),
      ];
      final sesion = Sesion(jugadores);
      sesion.iniciarPrimeraPartida(random: random);

      while (!sesion.haTerminado) {
        _jugarPartidaAleatoria(sesion, random);
        partidasJugadas++;

        final resultado = sesion.historial.last;
        if (resultado.tipoCierre == TipoCierre.dominacion) {
          cierresPorDominacion++;
        } else {
          cierresPorTranca++;
        }

        if (sesion.haTerminado) break;

        // El equipo ganador decide quién sale (aquí: al azar entre los dos).
        final equipoGanador = resultado.equipoGanador;
        final jugadorQueSale = random.nextBool()
            ? equipoGanador.jugadorA
            : equipoGanador.jugadorB;

        sesion.iniciarSiguientePartida(jugadorQueSale, random: random);
      }

      // El multiplicador solo se duplica en cada rayada, así que
      // log2(multiplicador) nos dice cuántas hubo en esta sesión.
      var m = sesion.multiplicadorRayada;
      while (m > 1) {
        rayadasTotales++;
        m ~/= 2;
      }

      sesionesCompletas++;
    } catch (e, st) {
      erroresInesperados++;
      // ignore: avoid_print
      print('ERROR en sesión $s: $e\n$st');
    }

    if ((s + 1) % 100 == 0) {
      // ignore: avoid_print
      print('Progreso: ${s + 1}/$cantidadSesiones sesiones...');
    }
  }

  // ignore: avoid_print
  print('''
=== Resultados del simulador ===
Sesiones simuladas:      $cantidadSesiones
Sesiones completadas OK: $sesionesCompletas
Errores inesperados:     $erroresInesperados
Partidas jugadas total:  $partidasJugadas
  - por dominación:      $cierresPorDominacion
  - por tranca:           $cierresPorTranca
Rayadas totales:          $rayadasTotales
''');

  if (erroresInesperados > 0) {
    // ignore: avoid_print
    print(
      '⚠️  Se encontraron $erroresInesperados errores. Revisa el log arriba.',
    );
  } else {
    // ignore: avoid_print
    print(
      '✅ Ninguna violación de reglas detectada en $cantidadSesiones sesiones.',
    );
  }
}

/// Juega una partida completa turno por turno, con cada jugador
/// eligiendo al azar entre sus jugadas legales (o pasando si no tiene).
/// Revisa la invariante de 168 puntos totales en cada paso.
void _jugarPartidaAleatoria(Sesion sesion, Random random) {
  final partida = sesion.partidaActual!;

  while (!partida.haTerminado) {
    final jugador = partida.jugadorEnTurno;
    final jugables = jugador.mano.fichasJugables(partida.mesa);

    if (jugables.isEmpty) {
      partida.pasar(jugador);
    } else {
      final ficha = jugables[random.nextInt(jugables.length)];

      if (partida.mesa.estaVacia) {
        partida.jugar(jugador, ficha);
      } else {
        final extremosPosibles = <Extremo>[];
        final izq = partida.mesa.extremoIzquierdo;
        final der = partida.mesa.extremoDerecho;
        if (izq != null && ficha.calza(izq))
          extremosPosibles.add(Extremo.izquierdo);
        if (der != null && ficha.calza(der))
          extremosPosibles.add(Extremo.derecho);

        final extremo =
            extremosPosibles[random.nextInt(extremosPosibles.length)];
        partida.jugar(jugador, ficha, extremo: extremo);
      }
    }

    _verificarInvariante168(partida);
  }

  sesion.registrarResultadoPartidaActual();
}

/// El set completo de dominó siempre suma 168 puntos (pintas) en total.
/// En cualquier momento de la partida, lo que está en las 4 manos más
/// lo que ya se jugó en la mesa debe seguir sumando exactamente 168.
/// Si esto alguna vez falla, hay un bug real en el motor.
void _verificarInvariante168(Partida partida) {
  final pintasEnManos = partida.jugadores.fold<int>(
    0,
    (acc, j) => acc + j.mano.totalPuntos,
  );
  final total = pintasEnManos + partida.mesa.totalPintasJugadas;

  if (total != 168) {
    throw StateError(
      'Invariante violada: total de pintas en juego = $total (se esperaba 168)',
    );
  }
}
