import 'dart:math';

import '../models/ficha.dart';
import '../models/mano.dart';
import '../models/mesa.dart';
import 'decision_ia.dart';
import 'estrategia_ia.dart';

/// Nivel Novato: juega cualquier ficha jugable, con preferencia leve
/// por soltar fichas de valor alto primero. Sin memoria — no cuenta
/// fichas jugadas ni infiere nada sobre las manos ajenas.
class Novato implements EstrategiaIA {
  final Random _random;

  Novato({Random? random}) : _random = random ?? Random();

  @override
  DecisionIA decidir(Mano mano, Mesa mesa) {
    final jugables = mano.fichasJugables(mesa);
    if (jugables.isEmpty) {
      throw StateError(
        'Novato.decidir() llamado sin jugadas legales disponibles',
      );
    }

    final ficha = _elegirConPreferenciaPorValorAlto(jugables);

    if (mesa.estaVacia) {
      return DecisionIA(ficha, null);
    }

    return DecisionIA(ficha, _elegirExtremo(ficha, mesa));
  }

  /// Elige una ficha al azar entre las jugables, dando más peso
  /// (probabilidad) a las de mayor valor. Cada ficha pesa (valor + 1)
  /// para que incluso la mula 0-0 tenga probabilidad distinta de cero.
  Ficha _elegirConPreferenciaPorValorAlto(List<Ficha> jugables) {
    final pesos = jugables.map((f) => f.valor + 1).toList();
    final total = pesos.fold<int>(0, (a, b) => a + b);

    var punto = _random.nextInt(total);
    for (var i = 0; i < jugables.length; i++) {
      if (punto < pesos[i]) {
        return jugables[i];
      }
      punto -= pesos[i];
    }
    return jugables.last; // fallback defensivo, no debería alcanzarse
  }

  /// Si [ficha] calza en ambos extremos, elige uno al azar.
  Extremo _elegirExtremo(Ficha ficha, Mesa mesa) {
    final extremosPosibles = <Extremo>[];
    final izq = mesa.extremoIzquierdo;
    final der = mesa.extremoDerecho;
    if (izq != null && ficha.calza(izq))
      extremosPosibles.add(Extremo.izquierdo);
    if (der != null && ficha.calza(der)) extremosPosibles.add(Extremo.derecho);
    return extremosPosibles[_random.nextInt(extremosPosibles.length)];
  }
}
