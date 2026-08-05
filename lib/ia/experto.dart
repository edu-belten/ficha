import 'dart:math';

import '../models/ficha.dart';
import '../models/mesa.dart';
import 'contexto_jugada.dart';
import 'decision_ia.dart';
import 'estrategia_ia.dart';
import 'inferencia_jugadores.dart';

/// Nivel Experto: usa inferencia por pases (información pública) para
/// saber qué números seguramente NO tiene cada rival (porque pasó
/// cuando ese número estaba expuesto), y juega activamente:
///
/// - Prefiere dejar expuesto un número que un RIVAL ya descartó
///   (lo "ahoga" — no va a poder jugar en ese extremo).
/// - Evita, cuando puede, dejar expuesto un número que su COMPAÑERO ya
///   descartó (no le sirve de nada abrirle ese camino).
///
/// Sin información de pases todavía (ej. inicio de la partida), decide
/// con el mismo criterio base que Medio.
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
      // Sin mesa todavía no hay extremos ni pases que analizar.
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

    final rivalesDescartados = <int>{};
    descartados.forEach((jugador, numeros) {
      if (jugador != contexto.jugador && jugador != contexto.companero) {
        rivalesDescartados.addAll(numeros);
      }
    });
    final companeroDescartados = descartados[contexto.companero] ?? <int>{};

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

        var puntaje = ficha.valor;
        if (rivalesDescartados.contains(nuevoNumero)) puntaje += 100;
        if (companeroDescartados.contains(nuevoNumero)) puntaje -= 50;

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
