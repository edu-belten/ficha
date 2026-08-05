import '../models/jugador.dart';
import '../models/mano.dart';
import '../models/mesa.dart';
import '../models/partida.dart';
import '../models/registro_pase.dart';

/// Todo lo que un nivel de IA puede legítimamente saber al decidir su
/// jugada: su propia mano, el estado público de la mesa, el historial
/// público de pases, quién es (para distinguir sus propios pases de
/// los ajenos) y quién es su compañero (para poder jugar a favor del
/// equipo, no solo en contra del rival).
///
/// Nunca incluye las manos de otros jugadores — eso rompería la regla
/// central del proyecto: la IA no ve fichas ajenas.
class ContextoJugada {
  final Jugador jugador;
  final Jugador companero;
  final Mano mano;
  final Mesa mesa;
  final List<RegistroPase> historialPases;

  ContextoJugada({
    required this.jugador,
    required this.companero,
    required this.mano,
    required this.mesa,
    required this.historialPases,
  });

  /// Construye el contexto de [jugador] a partir del estado actual de
  /// [partida] — la forma normal de crear un ContextoJugada en el
  /// juego real (fuera de tests).
  factory ContextoJugada.desdePartida(Partida partida, Jugador jugador) {
    final equipo = partida.equipoDe(jugador);
    return ContextoJugada(
      jugador: jugador,
      companero: equipo.companeroDe(jugador),
      mano: jugador.mano,
      mesa: partida.mesa,
      historialPases: List.unmodifiable(partida.historialPases),
    );
  }
}
