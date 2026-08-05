import 'equipo.dart';

/// Las dos formas en que puede terminar una partida.
enum TipoCierre { dominacion, tranca }

/// Describe cómo terminó una partida: quién ganó, cuántos puntos,
/// y por qué mecanismo (dominación o tranca).
class ResultadoPartida {
  final TipoCierre tipoCierre;
  final Equipo equipoGanador;
  final Equipo equipoPerdedor;
  final int puntosGanados;

  /// Solo relevante en tranca: true si el resultado se decidió por la
  /// regla de desempate ("gana el equipo que tenía la mano"), no por
  /// tener menos pintas de forma clara.
  final bool desempatePorMano;

  ResultadoPartida({
    required this.tipoCierre,
    required this.equipoGanador,
    required this.equipoPerdedor,
    required this.puntosGanados,
    this.desempatePorMano = false,
  });

  @override
  String toString() {
    final tipo = tipoCierre == TipoCierre.dominacion ? 'Dominación' : 'Tranca';
    final desempate = desempatePorMano ? ' (desempate por mano)' : '';
    return '$tipo$desempate: $equipoGanador gana $puntosGanados puntos';
  }
}
