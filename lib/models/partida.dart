import 'dart:math';

import 'ficha.dart';
import 'jugador.dart';
import 'mesa.dart';

/// Orquesta una partida individual: reparto de fichas, turno actual,
/// y (más adelante) jugadas, pases y detección de fin de partida.
class Partida {
  final List<Jugador> jugadores; // siempre en orden de asiento: 1,2,3,4
  final Mesa mesa;

  int _asientoEnTurno;

  Partida._({
    required this.jugadores,
    required this.mesa,
    required int asientoInicial,
  }) : _asientoEnTurno = asientoInicial;

  /// Crea una nueva partida: baraja las 28 fichas y reparte 7 a cada
  /// jugador. El jugador que tenga la mula 6-6 empieza
  /// (regla de la primera partida de la sesión).
  ///
  /// [jugadores] debe tener exactamente 4 elementos, con asientos 1-4
  /// (no necesariamente en ese orden en la lista, se ordenan internamente).
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

    // Ordenamos por asiento para que el resto de la clase pueda
    // confiar en que jugadores[0] es asiento 1, jugadores[1] es asiento 2, etc.
    final jugadoresOrdenados = List<Jugador>.from(jugadores)
      ..sort((a, b) => a.asiento.compareTo(b.asiento));

    // Construir las 28 fichas del set completo (0-0 hasta 6-6).
    final set = <Ficha>[];
    for (var i = 0; i <= 6; i++) {
      for (var j = i; j <= 6; j++) {
        set.add(Ficha(i, j));
      }
    }
    assert(set.length == 28);

    set.shuffle(random ?? Random());

    // Repartir 7 fichas a cada jugador, en orden de asiento.
    for (var i = 0; i < jugadoresOrdenados.length; i++) {
      final inicio = i * 7;
      final manoFichas = set.sublist(inicio, inicio + 7);
      for (final ficha in manoFichas) {
        jugadoresOrdenados[i].mano.agregar(ficha);
      }
    }

    // Encontrar quién tiene la mula 6-6 para que empiece.
    final mula = Ficha(6, 6);
    final jugadorInicial = jugadoresOrdenados.firstWhere(
      (j) => j.mano.tieneFicha(mula),
      orElse: () => throw StateError(
        'Ninguna mano tiene la mula 6-6; algo salió mal en el reparto',
      ),
    );

    return Partida._(
      jugadores: jugadoresOrdenados,
      mesa: Mesa(),
      asientoInicial: jugadorInicial.asiento,
    );
  }

  /// El jugador cuyo turno es ahora mismo.
  Jugador get jugadorEnTurno =>
      jugadores.firstWhere((j) => j.asiento == _asientoEnTurno);

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

  /// [jugador] declara "paso".
  ///
  /// TODO(Fase 1 - pendiente): cuando Partida tenga referencia a los
  /// Equipos, un pase en falso (tener jugada legal y pasar de todos modos)
  /// deberá aplicar la penalización de +25 puntos al equipo infractor,
  /// en vez de bloquear la acción como se hace por ahora.
  /// (ver sección "Penalizaciones" en Las Reglas de la Ficha).
  void pasar(Jugador jugador) {
    _validarTurno(jugador);

    if (jugador.mano.tieneJugadaLegal(mesa)) {
      throw StateError(
        '$jugador tiene jugada legal disponible; no puede pasar (pase en falso)',
      );
    }

    avanzarTurno();
  }

  void _validarTurno(Jugador jugador) {
    if (jugador.asiento != _asientoEnTurno) {
      throw StateError('No es el turno de $jugador');
    }
  }
}
