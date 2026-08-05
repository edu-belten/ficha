import 'dart:math';

import '../models/ficha.dart';
import '../models/mano.dart';
import '../models/mesa.dart';
import 'decision_ia.dart';
import 'estrategia_ia.dart';

/// Nivel Medio: usa información pública (lo ya jugado en la mesa) para
/// jugar con más criterio que Novato.
///
/// - Prioriza soltar mulas de valor alto (6-6, 5-5, 4-4) en cuanto
///   puede, en vez de cargarlas.
/// - Sin mula alta disponible, prioriza la ficha jugable de mayor
///   valor (deshacerse de pintas pesadas).
/// - Reconoce fichas/números agotados (vía ContadorFichas), aunque en
///   este nivel todavía no lo usa para jugar activamente en contra del
///   rival — eso empieza en Experto.
class Medio implements EstrategiaIA {
  final Random _random;

  Medio({Random? random}) : _random = random ?? Random();

  @override
  DecisionIA decidir(Mano mano, Mesa mesa) {
    final jugables = mano.fichasJugables(mesa);
    if (jugables.isEmpty) {
      throw StateError(
        'Medio.decidir() llamado sin jugadas legales disponibles',
      );
    }

    final ficha = _elegirFicha(jugables);

    if (mesa.estaVacia) {
      return DecisionIA(ficha, null);
    }

    return DecisionIA(ficha, _elegirExtremo(ficha, mesa));
  }

  Ficha _elegirFicha(List<Ficha> jugables) {
    // Prioridad 1: mulas de valor alto (4-4, 5-5, 6-6 → valor 8, 10, 12).
    final mulasAltas = jugables.where((f) => f.esMula && f.valor >= 8).toList();
    if (mulasAltas.isNotEmpty) {
      mulasAltas.sort((a, b) => b.valor.compareTo(a.valor));
      return mulasAltas.first;
    }

    // Prioridad 2: la ficha jugable de mayor valor. Empate se rompe al azar.
    final maxValor = jugables.map((f) => f.valor).reduce(max);
    final candidatas = jugables.where((f) => f.valor == maxValor).toList();
    return candidatas[_random.nextInt(candidatas.length)];
  }

  Extremo _elegirExtremo(Ficha ficha, Mesa mesa) {
    final extremosPosibles = <Extremo>[];
    final izq = mesa.extremoIzquierdo;
    final der = mesa.extremoDerecho;
    if (izq != null && ficha.calza(izq)) {
      extremosPosibles.add(Extremo.izquierdo);
    }
    if (der != null && ficha.calza(der)) {
      extremosPosibles.add(Extremo.derecho);
    }
    return extremosPosibles[_random.nextInt(extremosPosibles.length)];
  }
}
