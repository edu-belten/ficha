import '../models/jugador.dart';
import '../models/registro_jugada.dart';
import '../models/registro_pase.dart';

/// A partir del historial público de la partida, calcula dos tipos de
/// señal sobre cada jugador (nunca viendo manos ajenas, solo pases y
/// jugadas ya hechas):
///
/// - **Descartados**: números que un jugador seguro NO tiene, porque
///   pasó cuando ese número estaba expuesto.
/// - **Reforzados**: números que un jugador probablemente SÍ tiene más
///   de una, porque ya jugó ese número repetidas veces — formaliza el
///   refrán "lo que no repites, no lo pides prestado" / el principio
///   de "repite la ficha" de las Nueve Erres.
///
/// Ninguna de las dos es certeza absoluta salvo "descartados" (esa sí
/// es determinística); "reforzados" es una apuesta calculada, no una
/// certeza.
class InferenciaJugadores {
  static Map<Jugador, Set<int>> numerosDescartados(
    List<RegistroPase> historialPases,
  ) {
    final resultado = <Jugador, Set<int>>{};
    for (final registro in historialPases) {
      final set = resultado.putIfAbsent(registro.jugador, () => <int>{});
      if (registro.extremoIzquierdo != null) {
        set.add(registro.extremoIzquierdo!);
      }
      if (registro.extremoDerecho != null) {
        set.add(registro.extremoDerecho!);
      }
    }
    return resultado;
  }

  /// Números que cada jugador ha jugado al menos [umbral] veces —
  /// señal (no certeza) de que probablemente tiene más fichas de ese
  /// número en mano.
  static Map<Jugador, Set<int>> numerosReforzados(
    List<RegistroJugada> historialJugadas, {
    int umbral = 2,
  }) {
    final conteos = <Jugador, Map<int, int>>{};
    for (final registro in historialJugadas) {
      final porNumero = conteos.putIfAbsent(registro.jugador, () => {});
      porNumero[registro.ficha.a] = (porNumero[registro.ficha.a] ?? 0) + 1;
      if (registro.ficha.b != registro.ficha.a) {
        porNumero[registro.ficha.b] = (porNumero[registro.ficha.b] ?? 0) + 1;
      }
    }

    final resultado = <Jugador, Set<int>>{};
    conteos.forEach((jugador, porNumero) {
      final reforzados = porNumero.entries
          .where((e) => e.value >= umbral)
          .map((e) => e.key)
          .toSet();
      if (reforzados.isNotEmpty) resultado[jugador] = reforzados;
    });
    return resultado;
  }
}
