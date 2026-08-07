import 'dart:math';

import '../models/ficha.dart';
import '../models/mesa.dart';
import 'analisis_cierre.dart';
import 'contador_fichas.dart';
import 'contexto_jugada.dart';
import 'decision_ia.dart';
import 'estrategia_ia.dart';
import 'inferencia_jugadores.dart';

/// Nivel Experto: usa el historial público completo de la partida
/// (pases y jugadas) para razonar con más finura que Medio, sin fallar
/// nunca por descuido:
///
/// - **Descartado** (certeza): un rival/compañero pasó cuando ese
///   número estaba expuesto → seguro no lo tiene.
/// - **Reforzado** (apuesta calculada, no certeza): un rival/compañero
///   ya jugó ese número dos o más veces → probablemente tiene más.
/// - **Agotado + fórmula de 168**: si un número está agotado (nadie
///   más lo tiene) y la propia mano de Experto está "liviana" respecto
///   a lo que falta por jugar, forzar el bloqueo conviene; si su mano
///   está pesada, evitarlo.
/// - **Rol mano/seguidor**: como criterio de desempate fino, prefiere
///   soltar bajo si su equipo salió, alto si es seguidor.
///
/// Sin mesa todavía (salida) no hay extremos que analizar — decide con
/// el mismo criterio base que Medio.
class Experto implements EstrategiaIA {
  final Random _random;

  Experto({Random? random}) : _random = random ?? Random();

  @override
  DecisionIA decidir(ContextoJugada contexto) {
    final jugables = contexto.mano.fichasJugables(contexto.mesa);
    if (jugables.isEmpty) {
      throw StateError(
        'Experto.decidir() llamado sin jugadas legales disponibles',
      );
    }

    if (contexto.mesa.estaVacia) {
      return DecisionIA(_elegirSalida(jugables), null);
    }

    return _elegirConInferencia(jugables, contexto);
  }

  Ficha _elegirSalida(List<Ficha> jugables) {
    final mulasAltas = jugables.where((f) => f.esMula && f.valor >= 8).toList();
    if (mulasAltas.isNotEmpty) {
      mulasAltas.sort((a, b) => b.valor.compareTo(a.valor));
      return mulasAltas.first;
    }
    final maxValor = jugables.map((f) => f.valor).reduce(max);
    final candidatas = jugables.where((f) => f.valor == maxValor).toList();
    return candidatas[_random.nextInt(candidatas.length)];
  }

  DecisionIA _elegirConInferencia(
    List<Ficha> jugables,
    ContextoJugada contexto,
  ) {
    final descartados = InferenciaJugadores.numerosDescartados(
      contexto.historialPases,
    );
    final reforzados = InferenciaJugadores.numerosReforzados(
      contexto.historialJugadas,
    );

    final rivalesDescartados = <int>{};
    final rivalesReforzados = <int>{};
    descartados.forEach((jugador, numeros) {
      if (jugador != contexto.jugador && jugador != contexto.companero) {
        rivalesDescartados.addAll(numeros);
      }
    });
    reforzados.forEach((jugador, numeros) {
      if (jugador != contexto.jugador && jugador != contexto.companero) {
        rivalesReforzados.addAll(numeros);
      }
    });
    final companeroDescartados = descartados[contexto.companero] ?? <int>{};
    final companeroReforzado = reforzados[contexto.companero] ?? <int>{};

    final contador = ContadorFichas(contexto.mano, contexto.mesa);
    final pintasEnMiMano = contexto.mano.totalPuntos;
    final pintasYaJugadas = contexto.mesa.totalPintasJugadas;

    final izq = contexto.mesa.extremoIzquierdo;
    final der = contexto.mesa.extremoDerecho;

    DecisionIA? mejor;
    var mejorPuntaje = -1 << 30;

    for (final ficha in jugables) {
      final extremosValidos = <Extremo>[];
      if (izq != null && ficha.calza(izq))
        extremosValidos.add(Extremo.izquierdo);
      if (der != null && ficha.calza(der)) extremosValidos.add(Extremo.derecho);

      for (final extremo in extremosValidos) {
        final valorExtremo = extremo == Extremo.izquierdo ? izq! : der!;
        final nuevoNumero = ficha.extremoOpuesto(valorExtremo);

        var puntaje = 0;

        // Descartado (certeza) pesa más que reforzado (apuesta calculada).
        if (rivalesDescartados.contains(nuevoNumero)) {
          puntaje += 100;
        } else if (rivalesReforzados.contains(nuevoNumero)) {
          puntaje -= 30; // probablemente tiene más, evita regalarle
        }

        if (companeroDescartados.contains(nuevoNumero)) {
          puntaje -= 50;
        } else if (companeroReforzado.contains(nuevoNumero)) {
          puntaje += 40; // probablemente tiene más, le abres camino
        }

        // Fórmula de 168: bono o penalización según si conviene
        // forzar el bloqueo, no un bono ciego como en versiones previas.
        puntaje += AnalisisCierre.bonoPorAgotado(
          numeroAgotado: contador.estaAgotado(nuevoNumero),
          pintasEnMiMano: pintasEnMiMano,
          pintasYaJugadasEnMesa: pintasYaJugadas,
        );

        // Rol mano/seguidor como desempate fino.
        puntaje += contexto.esEquipoMano ? -ficha.valor : ficha.valor;

        if (mejor == null ||
            puntaje > mejorPuntaje ||
            (puntaje == mejorPuntaje && _random.nextBool())) {
          mejorPuntaje = puntaje;
          mejor = DecisionIA(ficha, extremo);
        }
      }
    }

    return mejor!;
  }
}
