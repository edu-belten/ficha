import '../models/mano.dart';
import '../models/mesa.dart';
import 'decision_ia.dart';

/// Interfaz común para los 4 niveles de Game AI (novato, medio, experto,
/// máster). Cada nivel implementa su propia lógica de decisión, pero
/// todos se usan de la misma forma desde el resto del motor.
abstract class EstrategiaIA {
  /// Decide qué ficha jugar y en qué extremo, dado el estado de [mano]
  /// y [mesa]. Solo se llama cuando ya se confirmó que existe al menos
  /// una jugada legal (mano.tieneJugadaLegal(mesa) == true) — esta
  /// función nunca decide "pasar", eso lo maneja el llamador.
  DecisionIA decidir(Mano mano, Mesa mesa);
}
