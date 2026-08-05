import 'dart:math';

import 'equipo.dart';
import 'ficha.dart';
import 'jugador.dart';
import 'mesa.dart';

/// Orquesta una partida individual: reparto de fichas, equipos, turno
/// actual, jugadas, pases (con detección de pase en falso) y —
/// más adelante — detección de fin de partida.
class Partida {
  final List<Jugador> jugadores; // siempre en orden de asiento: 1,2,3,4
  final Mesa mesa;
  final Equipo equipoA; // asientos 1 + 3
  final Equipo equipoB; // asientos 2 + 4

  int _asientoEnTurno;

  Partida._({
    required this.jugadores,
    required this.mesa,
    required this.equipoA,
    required this.equipoB,
    required int asientoInicial,
  }) : _asientoEnTurno = asientoInicial;

  /// Crea una nueva partida: baraja las 28 fichas, reparte 7 a cada
  /// jugador, arma los dos equipos (asientos 1+3 y 2+4, según la regla
  /// del proyecto), y determina quién empieza (el que tenga la mula 6-6,
  /// regla de la primera partida de la sesión).
  factory Partida.repartir(List<Jugador> jugadores, {Random? random}) {
    if (jugadores.length != 4) {
      throw ArgumentError('Una partida requiere exactamente 4 jugadores');
    }

    final asientos = jugadores.map((j) => j.asiento).toSet();
    if (asientos.length != 4 || !asientos.containsAll([1, 2, 3, 4])) {
      throw ArgumentError(
        'Los jugadores deben tener asientos 1, 2, 3 y 4 sin repetir',
      );
    }

    final jugadoresOrdenados = List<Jugador>.from(jugadores)
      ..sort((a, b) => a.asiento.compareTo(b.asiento));

    final set = <Ficha>[];
    for (var i = 0; i <= 6; i++) {
      for (var j = i; j <= 6; j++) {
        set.add(Ficha(i, j));
      }
    }
    assert(set.length == 28);

    set.shuffle(random ?? Random());

    for (var i = 0; i < jugadoresOrdenados.length; i++) {
      final inicio = i * 7;
      final manoFichas = set.sublist(inicio, inicio + 7);
      for (final ficha in manoFichas) {
        jugadoresOrdenados[i].mano.agregar(ficha);
      }
    }

    final mula = Ficha(6, 6);
    final jugadorInicial = jugadoresOrdenados.firstWhere(
      (j) => j.mano.tieneFicha(mula),
      orElse: () => throw StateError(
        'Ninguna mano tiene la mula 6-6; algo salió mal en el reparto',
      ),
    );

    // Asientos 1+3 son equipo, 2+4 son el otro (compañeros sentados enfrente).
    final equipoA = Equipo(
      jugadorA: jugadoresOrdenados[0], // asiento 1
      jugadorB: jugadoresOrdenados[2], // asiento 3
      nombre: 'Equipo 1-3',
    );
    final equipoB = Equipo(
      jugadorA: jugadoresOrdenados[1], // asiento 2
      jugadorB: jugadoresOrdenados[3], // asiento 4
      nombre: 'Equipo 2-4',
    );

    return Partida._(
      jugadores: jugadoresOrdenados,
      mesa: Mesa(),
      equipoA: equipoA,
      equipoB: equipoB,
      asientoInicial: jugadorInicial.asiento,
    );
  }

  /// El jugador cuyo turno es ahora mismo.
  Jugador get jugadorEnTurno =>
      jugadores.firstWhere((j) => j.asiento == _asientoEnTurno);

  /// Regresa el equipo (A o B) al que pertenece [jugador].
  Equipo equipoDe(Jugador jugador) =>
      equipoA.tieneJugador(jugador) ? equipoA : equipoB;

  /// Avanza el turno al siguiente jugador (hacia la derecha, en contra del reloj).
  void avanzarTurno() {
    _asientoEnTurno = (_asientoEnTurno % 4) + 1;
  }

  /// [jugador] coloca [ficha]. Si la mesa está vacía, se coloca como
  /// ficha de salida y [extremo] se ignora. Si la mesa ya tiene fichas,
  /// [extremo] es obligatorio e indica contra cuál extremo se juega.
  ///
  /// Lanza error si no es el turno de [jugador], si no tiene esa ficha
  /// en mano, o si la ficha no calza en el extremo indicado.
  void jugar(Jugador jugador, Ficha ficha, {Extremo? extremo}) {
    _validarTurno(jugador);

    if (!jugador.mano.tieneFicha(ficha)) {
      throw ArgumentError('$jugador no tiene la ficha $ficha en su mano');
    }

    if (mesa.estaVacia) {
      mesa.colocarFichaSalida(ficha);
    } else {
      if (extremo == null) {
        throw ArgumentError('Debes indicar en qué extremo se juega la ficha');
      }
      mesa.jugar(ficha, extremo); // lanza error si la ficha no calza
    }

    jugador.mano.quitar(ficha);
    avanzarTurno();
  }

  /// [jugador] declara "paso". Si en realidad sí tenía jugada legal
  /// disponible, es un "pase en falso": se aplica automáticamente
  /// la penalización de +25 puntos al equipo de [jugador]
  /// (ver sección "Penalizaciones" en Las Reglas de la Ficha).
  ///
  /// Regresa `true` si fue un pase en falso (y por lo tanto penalizado),
  /// `false` si fue un paso legítimo.
  bool pasar(Jugador jugador) {
    _validarTurno(jugador);

    final fueFalso = jugador.mano.tieneJugadaLegal(mesa);
    if (fueFalso) {
      equipoDe(jugador).agregarPuntos(25);
    }

    avanzarTurno();
    return fueFalso;
  }

  void _validarTurno(Jugador jugador) {
    if (jugador.asiento != _asientoEnTurno) {
      throw StateError('No es el turno de $jugador');
    }
  }
}
