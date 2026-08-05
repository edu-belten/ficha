import '../models/ficha.dart';
import '../models/mesa.dart';

/// La decisión de un nivel de IA: qué ficha jugar y en qué extremo.
/// [extremo] es `null` únicamente cuando la mesa está vacía (la ficha
/// se coloca como salida, sin extremo que elegir).
class DecisionIA {
  final Ficha ficha;
  final Extremo? extremo;

  DecisionIA(this.ficha, this.extremo);

  @override
  String toString() =>
      extremo == null ? 'Jugar $ficha (salida)' : 'Jugar $ficha en $extremo';
}
