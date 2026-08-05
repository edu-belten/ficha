import 'contexto_jugada.dart';
import 'decision_ia.dart';

/// Interfaz común para los 4 niveles de Game AI (novato, medio, experto,
/// máster). Cada nivel implementa su propia lógica de decisión, pero
/// todos se usan de la misma forma desde el resto del motor.
abstract class EstrategiaIA {
  /// Decide qué ficha jugar y en qué extremo, dado [contexto]. Solo se
  /// llama cuando ya se confirmó que existe al menos una jugada legal
  /// — esta función nunca decide "pasar", eso lo maneja el llamador.
  DecisionIA decidir(ContextoJugada contexto);
}
