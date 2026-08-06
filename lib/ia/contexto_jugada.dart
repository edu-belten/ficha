import '../models/jugador.dart';
import '../models/mano.dart';
import '../models/mesa.dart';
import '../models/partida.dart';
import '../models/registro_jugada.dart';
import '../models/registro_pase.dart';

/// Todo lo que un nivel de IA puede legítimamente saber al decidir su
/// jugada: su propia mano, el estado público de la mesa, los
/// historiales públicos de pases y jugadas, quién es su compañero, si
/// su equipo tiene la mano (salió) en esta partida, y cuántas fichas
/// le quedan a su compañero (dato público, aunque no cuáles).
///
/// Nunca incluye las manos de otros jugadores — eso rompería la regla
/// central del proyecto: la IA no ve fichas ajenas.
class ContextoJugada {
  final Jugador jugador;
  final Jugador companero;
  final Mano mano;
  final Mesa mesa;
  final List<RegistroPase> historialPases;
  final List<RegistroJugada> historialJugadas;

  /// ¿El equipo de [jugador] fue el que salió en esta partida?
  /// ("equipo mano", ver desambiguación en Las Reglas de la Ficha —
  /// distinto de "traer la mano").
  final bool esEquipoMano;

  /// Cuántas fichas le quedan al compañero — información pública
  /// (todos ven el conteo), aunque no cuáles fichas son. Se usa para
  /// determinar quién de la pareja "trae la mano" en este momento.
  final int fichasCompanero;

  ContextoJugada({
    required this.jugador,
    required this.companero,
    required this.mano,
    required this.mesa,
    required this.historialPases,
    this.historialJugadas = const [],
    this.esEquipoMano = false,
    this.fichasCompanero = 7,
  });

  /// Construye el contexto de [jugador] a partir del estado actual de
  /// [partida] — la forma normal de crear un ContextoJugada en el
  /// juego real (fuera de tests).
  factory ContextoJugada.desdePartida(Partida partida, Jugador jugador) {
    final equipo = partida.equipoDe(jugador);
    final companero = equipo.companeroDe(jugador);
    return ContextoJugada(
      jugador: jugador,
      companero: companero,
      mano: jugador.mano,
      mesa: partida.mesa,
      historialPases: List.unmodifiable(partida.historialPases),
      historialJugadas: List.unmodifiable(partida.historialJugadas),
      esEquipoMano: partida.equipoMano == equipo,
      fichasCompanero: companero.mano.cantidadFichas,
    );
  }
}
