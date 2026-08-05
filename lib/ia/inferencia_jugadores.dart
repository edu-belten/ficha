import '../models/jugador.dart';
import '../models/registro_pase.dart';

/// A partir del historial público de pases legítimos, calcula qué
/// números sabemos que cada jugador NO tiene en mano — porque en algún
/// momento pasó cuando ese número estaba expuesto en un extremo de la
/// mesa. Solo usa información pública (RegistroPase), nunca manos
/// ajenas.
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
}
