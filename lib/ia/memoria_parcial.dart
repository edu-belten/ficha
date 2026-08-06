import 'dart:math';

import '../models/registro_pase.dart';

/// Simula la memoria imperfecta del nivel Medio: de todos los pases
/// legítimos ya ocurridos (información pública completa, la que usa
/// Experto sin fallar nunca), Medio solo "recuerda" una parte — con
/// más probabilidad en los casos más obvios/memorables — y el resto
/// lo pasa por alto, como haría un jugador humano de nivel intermedio.
class MemoriaParcial {
  final Random _random;

  MemoriaParcial({Random? random}) : _random = random ?? Random();

  /// Regresa el subconjunto de [historialPases] que Medio "recuerda"
  /// esta vez. Se recalcula en cada llamada — Medio puede recordar un
  /// pase hoy y no la próxima vez que decida, simulando memoria
  /// humana imperfecta, no un fallo sistemático y repetible.
  List<RegistroPase> recordar(List<RegistroPase> historialPases) {
    final recordados = <RegistroPase>[];
    for (var i = 0; i < historialPases.length; i++) {
      final registro = historialPases[i];
      if (_random.nextDouble() < _probabilidadDeRecordar(registro, i)) {
        recordados.add(registro);
      }
    }
    return recordados;
  }

  double _probabilidadDeRecordar(RegistroPase registro, int indice) {
    // Caso muy memorable: ambos extremos mostraban el mismo número —
    // típico de un pase justo después de que alguien salió con mula
    // (o de una mesa ya "cuadrada" al mismo número). Ejemplo ancla:
    // "sale con la mula de 3, el siguiente pasa" — eso se recuerda casi
    // siempre, por el resto de la partida.
    final ambosExtremosIguales =
        registro.extremoIzquierdo != null &&
        registro.extremoIzquierdo == registro.extremoDerecho;
    if (ambosExtremosIguales) return 0.9;

    // Pases tempranos en la partida: todavía hay poca información en
    // la mesa, más fácil de rastrear mentalmente.
    if (indice < 2) return 0.5;

    // Cualquier otro pase: Medio se "pierde" entre tanta información
    // acumulada, a diferencia de Experto, que nunca falla.
    return 0.15;
  }
}
