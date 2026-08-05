import 'dart:math';

import 'equipo.dart';
import 'jugador.dart';
import 'partida.dart';
import 'resultado_partida.dart';

/// Orquesta una sesión completa: varias partidas seguidas, con marcador
/// acumulado persistente entre ellas, la regla de "se raya" (empate
/// exacto resetea a 0), y detección de cuándo un equipo llega a 100
/// puntos y gana la sesión.
class Sesion {
  final List<Jugador> jugadores; // en orden de asiento: 1,2,3,4
  final Equipo equipoA; // asientos 1 + 3, persistente toda la sesión
  final Equipo equipoB; // asientos 2 + 4, persistente toda la sesión

  /// Multiplicador informativo/cosmético de "se raya". Empieza en 1
  /// (sin rayadas todavía) y se duplica cada vez que ocurre un empate
  /// exacto. No afecta el cálculo real de puntos.
  int multiplicadorRayada = 1;

  final List<ResultadoPartida> historial = [];

  Partida? partidaActual;
  Equipo? _equipoGanadorSesion;

  Sesion._({
    required this.jugadores,
    required this.equipoA,
    required this.equipoB,
  });

  factory Sesion(List<Jugador> jugadores) {
    if (jugadores.length != 4) {
      throw ArgumentError('Una sesión requiere exactamente 4 jugadores');
    }
    final asientos = jugadores.map((j) => j.asiento).toSet();
    if (asientos.length != 4 || !asientos.containsAll([1, 2, 3, 4])) {
      throw ArgumentError(
        'Los jugadores deben tener asientos 1, 2, 3 y 4 sin repetir',
      );
    }

    final ordenados = List<Jugador>.from(jugadores)
      ..sort((a, b) => a.asiento.compareTo(b.asiento));

    final equipoA = Equipo(
      jugadorA: ordenados[0],
      jugadorB: ordenados[2],
      nombre: 'Equipo 1-3',
    );
    final equipoB = Equipo(
      jugadorA: ordenados[1],
      jugadorB: ordenados[3],
      nombre: 'Equipo 2-4',
    );

    return Sesion._(jugadores: ordenados, equipoA: equipoA, equipoB: equipoB);
  }

  /// El equipo que ganó la sesión (llegó a 100+), o `null` si sigue en curso.
  Equipo? get equipoGanadorSesion => _equipoGanadorSesion;

  /// ¿La sesión ya terminó?
  bool get haTerminado => _equipoGanadorSesion != null;

  /// El jugador en turno de la partida actual.
  /// Lanza error si todavía no se ha iniciado ninguna partida.
  Jugador get jugadorEnTurno {
    final partida = partidaActual;
    if (partida == null) {
      throw StateError('Todavía no hay una partida en curso');
    }
    return partida.jugadorEnTurno;
  }

  /// Inicia la primera partida de la sesión. Quién sale se determina
  /// buscando la mula 6-6 (regla de la primera partida).
  void iniciarPrimeraPartida({Random? random}) {
    if (partidaActual != null) {
      throw StateError('Ya se inició una partida en esta sesión');
    }
    partidaActual = Partida.repartir(
      jugadores,
      random: random,
      equipoA: equipoA,
      equipoB: equipoB,
    );
  }

  /// Inicia la siguiente partida de la sesión, después de que la
  /// anterior haya terminado y se haya registrado su resultado.
  ///
  /// [jugadorQueSale] es el jugador que el equipo ganador de la partida
  /// anterior decidió que pusiera la ficha de salida (decisión interna
  /// del equipo — ver "Determinar quién sale" en Las Reglas de la Ficha).
  void iniciarSiguientePartida(Jugador jugadorQueSale, {Random? random}) {
    if (haTerminado) {
      throw StateError('La sesión ya terminó');
    }
    final anterior = partidaActual;
    if (anterior == null || !anterior.haTerminado) {
      throw StateError(
        'La partida actual todavía no ha terminado; no se puede iniciar la siguiente',
      );
    }
    partidaActual = Partida.repartir(
      jugadores,
      random: random,
      equipoA: equipoA,
      equipoB: equipoB,
      jugadorQueSale: jugadorQueSale,
    );
  }

  /// Debe llamarse justo después de que [partidaActual] termine (ya sea
  /// por dominación o tranca). Registra el resultado en el historial,
  /// revisa si el marcador quedó exactamente empatado ("se raya" —
  /// resetea ambos a 0 y duplica el multiplicador), y si no hubo
  /// empate, revisa si algún equipo ya llegó a 100 y ganó la sesión.
  void registrarResultadoPartidaActual() {
    final partida = partidaActual;
    final resultado = partida?.resultado;
    if (partida == null || resultado == null) {
      throw StateError('La partida actual todavía no ha terminado');
    }

    historial.add(resultado);

    // "Se raya": empate exacto, sin importar el valor. Se revisa ANTES
    // de comprobar los 100, y resetea de inmediato.
    if (equipoA.marcadorAcumulado == equipoB.marcadorAcumulado) {
      equipoA.resetearMarcador();
      equipoB.resetearMarcador();
      multiplicadorRayada *= 2;
      return;
    }

    if (equipoA.marcadorAcumulado >= 100) {
      _equipoGanadorSesion = equipoA;
    } else if (equipoB.marcadorAcumulado >= 100) {
      _equipoGanadorSesion = equipoB;
    }
  }
}
