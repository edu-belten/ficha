import 'dart:math';

import 'equipo.dart';
import 'ficha.dart';
import 'jugador.dart';
import 'mesa.dart';
import 'registro_pase.dart';
import 'resultado_partida.dart';

/// Orquesta una partida individual: reparto de fichas, equipos, turno
/// actual, jugadas, pases (con detección de pase en falso y registro
/// público de pases legítimos para inferencia), y detección de fin de
/// partida (dominación o tranca).
class Partida {
  final List<Jugador> jugadores; // siempre en orden de asiento: 1,2,3,4
  final Mesa mesa;
  final Equipo equipoA; // asientos 1 + 3
  final Equipo equipoB; // asientos 2 + 4
  final Equipo equipoMano; // equipo del jugador que salió en esta partida

  /// Historial público de pases legítimos: quién pasó y qué extremos
  /// estaban expuestos en ese momento. Los pases en falso NO se
  /// agregan aquí. Es la base de la inferencia del nivel Experto.
  final List<RegistroPase> historialPases = [];

  int _asientoEnTurno;
  ResultadoPartida? _resultado;

  Partida._({
    required this.jugadores,
    required this.mesa,
    required this.equipoA,
    required this.equipoB,
    required this.equipoMano,
    required int asientoInicial,
  }) : _asientoEnTurno = asientoInicial;

  /// Crea una nueva partida: vacía las manos (por si estos jugadores
  /// vienen de una partida anterior en la misma sesión), baraja las 28
  /// fichas, reparte 7 a cada jugador, arma los dos equipos (asientos
  /// 1+3 y 2+4), y determina quién empieza (el que tenga la mula 6-6,
  /// regla de la primera partida de la sesión).
  factory Partida.repartir(
    List<Jugador> jugadores, {
    Random? random,
    Equipo? equipoA,
    Equipo? equipoB,
    Jugador? jugadorQueSale,
  }) {
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

    // Vaciamos las manos por si estos jugadores vienen de una partida
    // anterior en la misma sesión.
    for (final j in jugadoresOrdenados) {
      j.mano.vaciar();
    }

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

    // Asientos 1+3 son equipo, 2+4 son el otro (compañeros sentados enfrente).
    final equipoAFinal =
        equipoA ??
        Equipo(
          jugadorA: jugadoresOrdenados[0], // asiento 1
          jugadorB: jugadoresOrdenados[2], // asiento 3
          nombre: 'Equipo 1-3',
        );
    final equipoBFinal =
        equipoB ??
        Equipo(
          jugadorA: jugadoresOrdenados[1], // asiento 2
          jugadorB: jugadoresOrdenados[3], // asiento 4
          nombre: 'Equipo 2-4',
        );

    Jugador jugadorInicial;
    if (jugadorQueSale != null) {
      if (!jugadoresOrdenados.contains(jugadorQueSale)) {
        throw ArgumentError('jugadorQueSale no pertenece a esta partida');
      }
      jugadorInicial = jugadorQueSale;
    } else {
      final mula = Ficha(6, 6);
      jugadorInicial = jugadoresOrdenados.firstWhere(
        (j) => j.mano.tieneFicha(mula),
        orElse: () => throw StateError(
          'Ninguna mano tiene la mula 6-6; algo salió mal en el reparto',
        ),
      );
    }

    final equipoMano = equipoAFinal.tieneJugador(jugadorInicial)
        ? equipoAFinal
        : equipoBFinal;

    return Partida._(
      jugadores: jugadoresOrdenados,
      mesa: Mesa(),
      equipoA: equipoAFinal,
      equipoB: equipoBFinal,
      equipoMano: equipoMano,
      asientoInicial: jugadorInicial.asiento,
    );
  }

  /// El jugador cuyo turno es ahora mismo.
  Jugador get jugadorEnTurno =>
      jugadores.firstWhere((j) => j.asiento == _asientoEnTurno);

  /// El resultado de la partida, o `null` si sigue en curso.
  ResultadoPartida? get resultado => _resultado;

  /// ¿La partida ya terminó (dominación o tranca)?
  bool get haTerminado => _resultado != null;

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
  /// Si esta jugada deja a [jugador] sin fichas, la partida termina
  /// inmediatamente por dominación.
  void jugar(Jugador jugador, Ficha ficha, {Extremo? extremo}) {
    if (haTerminado) {
      throw StateError('La partida ya terminó: $_resultado');
    }
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

    if (jugador.mano.estaVacia) {
      _finalizarPorDominacion(jugador);
      return;
    }

    avanzarTurno();
    _verificarTranca();
  }

  /// [jugador] declara "paso". Si en realidad sí tenía jugada legal
  /// disponible, es un "pase en falso": se aplica automáticamente la
  /// penalización de +25 puntos al equipo de [jugador], y NO se
  /// registra en [historialPases] (no dice nada real sobre su mano).
  /// Si fue un pase legítimo, sí se registra — es la base de la
  /// inferencia del nivel Experto.
  ///
  /// Regresa `true` si fue un pase en falso, `false` si fue legítimo.
  bool pasar(Jugador jugador) {
    if (haTerminado) {
      throw StateError('La partida ya terminó: $_resultado');
    }
    _validarTurno(jugador);

    final fueFalso = jugador.mano.tieneJugadaLegal(mesa);
    if (fueFalso) {
      equipoDe(jugador).agregarPuntos(25);
    } else {
      historialPases.add(
        RegistroPase(
          jugador: jugador,
          extremoIzquierdo: mesa.extremoIzquierdo,
          extremoDerecho: mesa.extremoDerecho,
        ),
      );
    }

    avanzarTurno();
    _verificarTranca();
    return fueFalso;
  }

  void _validarTurno(Jugador jugador) {
    if (jugador.asiento != _asientoEnTurno) {
      throw StateError('No es el turno de $jugador');
    }
  }

  /// Cierre por dominación: [jugadorQueCerro] se quedó sin fichas.
  /// Su equipo suma únicamente las pintas del equipo RIVAL
  /// (las del compañero del que cerró no cuentan).
  void _finalizarPorDominacion(Jugador jugadorQueCerro) {
    final equipoGanador = equipoDe(jugadorQueCerro);
    final equipoPerdedor = equipoGanador == equipoA ? equipoB : equipoA;
    final puntos = equipoPerdedor.totalPintasEnMano;

    equipoGanador.agregarPuntos(puntos);

    _resultado = ResultadoPartida(
      tipoCierre: TipoCierre.dominacion,
      equipoGanador: equipoGanador,
      equipoPerdedor: equipoPerdedor,
      puntosGanados: puntos,
    );
  }

  /// Revisa si los 4 jugadores están bloqueados contra el estado actual
  /// de la mesa. Si es así, la partida termina por tranca.
  void _verificarTranca() {
    if (haTerminado || mesa.estaVacia) return;

    final todosBloqueados = jugadores.every(
      (j) => !j.mano.tieneJugadaLegal(mesa),
    );
    if (!todosBloqueados) return;

    final pintasA = equipoA.totalPintasEnMano;
    final pintasB = equipoB.totalPintasEnMano;

    Equipo equipoGanador;
    var desempate = false;

    if (pintasA < pintasB) {
      equipoGanador = equipoA;
    } else if (pintasB < pintasA) {
      equipoGanador = equipoB;
    } else {
      equipoGanador = equipoMano; // empate: gana quien tenía la mano
      desempate = true;
    }

    final equipoPerdedor = equipoGanador == equipoA ? equipoB : equipoA;
    final puntos = equipoPerdedor.totalPintasEnMano;

    equipoGanador.agregarPuntos(puntos);

    _resultado = ResultadoPartida(
      tipoCierre: TipoCierre.tranca,
      equipoGanador: equipoGanador,
      equipoPerdedor: equipoPerdedor,
      puntosGanados: puntos,
      desempatePorMano: desempate,
    );
  }
}
