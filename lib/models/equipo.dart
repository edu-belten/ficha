import 'jugador.dart';

/// Representa un equipo de dos jugadores compañeros (ej. asientos 1+3).
class Equipo {
  final Jugador jugadorA;
  final Jugador jugadorB;
  final String nombre;

  /// Puntos acumulados por este equipo a lo largo de la sesión,
  /// hacia la meta de 100.
  int marcadorAcumulado = 0;

  Equipo({required this.jugadorA, required this.jugadorB, this.nombre = ''});

  /// Suma de las pintas en mano de AMBOS jugadores del equipo.
  /// Se usa para determinar el ganador en caso de tranca.
  int get totalPintasEnMano =>
      jugadorA.mano.totalPuntos + jugadorB.mano.totalPuntos;

  /// ¿Este jugador pertenece a este equipo?
  bool tieneJugador(Jugador jugador) =>
      jugador == jugadorA || jugador == jugadorB;

  /// Dado un jugador de este equipo, regresa a su compañero.
  Jugador companeroDe(Jugador jugador) {
    if (jugador == jugadorA) return jugadorB;
    if (jugador == jugadorB) return jugadorA;
    throw ArgumentError('$jugador no pertenece a este equipo');
  }

  /// Suma [puntos] al marcador acumulado del equipo.
  void agregarPuntos(int puntos) {
    marcadorAcumulado += puntos;
  }

  /// Resetea el marcador a cero (usado en la regla de "se raya").
  void resetearMarcador() {
    marcadorAcumulado = 0;
  }

  @override
  String toString() => '$jugadorA + $jugadorB';
}
