import '../models/ficha.dart';
import '../models/mano.dart';
import '../models/mesa.dart';

/// Utilidad de conteo de información pública: cuántas fichas que
/// contienen cada número (0-6) ya son visibles (jugadas en la mesa, o
/// en la propia mano), y si un número está "agotado" (las 7 fichas
/// que lo contienen ya están todas contabilizadas, así que ningún
/// otro jugador puede tenerlo).
///
/// Solo usa información pública (mesa) + la propia mano — nunca manos
/// ajenas, respetando la regla central del proyecto: la IA no ve
/// fichas de los demás jugadores.
class ContadorFichas {
  final Mano manoPropia;
  final Mesa mesa;

  ContadorFichas(this.manoPropia, this.mesa);

  /// Cuántas fichas distintas que contienen el número [n] ya son
  /// visibles (jugadas en la mesa o presentes en la propia mano).
  /// El máximo posible es 7 (todas las fichas que incluyen ese número).
  int fichasVisiblesDe(int n) {
    final vistas = <Ficha>{};
    vistas.addAll(mesa.historial.where((f) => f.a == n || f.b == n));
    vistas.addAll(manoPropia.fichas.where((f) => f.a == n || f.b == n));
    return vistas.length;
  }

  /// ¿Ya se vieron las 7 fichas que contienen el número [n]? Si es así,
  /// ningún otro jugador (rival o compañero) puede tener fichas de ese
  /// número — está matemáticamente agotado.
  bool estaAgotado(int n) => fichasVisiblesDe(n) >= 7;
}
