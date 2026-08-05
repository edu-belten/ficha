import 'dart:math';

import '../models/ficha.dart';
import '../models/mesa.dart';
import 'contexto_jugada.dart';
import 'decision_ia.dart';
import 'estrategia_ia.dart';

/// Nivel Medio: usa información pública (lo ya jugado en la mesa) para
/// jugar con más criterio que Novato.
///
/// - Prioriza soltar mulas de valor alto (6-6, 5-5, 4-4) en cuanto
///   puede, en vez de cargarlas.
/// - Sin mula alta disponible, prioriza la ficha jugable de mayor
///   valor (deshacerse de pintas pesadas).
class Medio implements EstrategiaIA {
  final Random _random;

  Medio({Random? random}) : _random = random ?? Random();

  @override
  DecisionIA decidir(ContextoJugada contexto) {
    final mano = contexto.mano;
    final mesa = contexto.mesa;

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
    final mulasAltas = jugables.where((f) => f.esMula && f.valor >= 8).toList();
    if (mulasAltas.isNotEmpty) {
      mulasAltas.sort((a, b) => b.valor.compareTo(a.valor));
      return mulasAltas.first;
    }

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
