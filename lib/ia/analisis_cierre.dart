/// Implementa el refrán "Para cerrar, saca la cuenta, no la corazonada":
/// el set completo de dominó suma 168 puntos (pintas) en total. Si tu
/// propia mano pesa menos que la mitad de lo que falta por jugar, te
/// conviene forzar un bloqueo (tranca) — terminarías con menos puntos
/// que el promedio esperado. Si pesa más, te conviene evitarlo.
///
/// Solo usa tu propia mano (que conoces con certeza) y el total
/// público de pintas ya jugadas en la mesa — no requiere ver manos
/// ajenas. Por eso tanto Medio como Experto pueden usarla.
class AnalisisCierre {
  /// ¿Conviene forzar un bloqueo ahora mismo, según el peso de mi
  /// propia mano contra lo que falta por jugar?
  static bool convieneForzarBloqueo({
    required int pintasEnMiMano,
    required int pintasYaJugadasEnMesa,
  }) {
    final restante = 168 - pintasYaJugadasEnMesa;
    return pintasEnMiMano < restante / 2;
  }

  /// El ajuste de puntaje a aplicar cuando una jugada dejaría expuesto
  /// un número agotado (nadie más lo tiene). Si conviene forzar el
  /// bloqueo, es un bono; si no conviene, se invierte en penalización
  /// — evita que la IA bloquee "a ciegas" sin pensar si le sirve.
  static int bonoPorAgotado({
    required bool numeroAgotado,
    required int pintasEnMiMano,
    required int pintasYaJugadasEnMesa,
    int magnitud = 20,
  }) {
    if (!numeroAgotado) return 0;
    final conviene = convieneForzarBloqueo(
      pintasEnMiMano: pintasEnMiMano,
      pintasYaJugadasEnMesa: pintasYaJugadasEnMesa,
    );
    return conviene ? magnitud : -magnitud;
  }
}
