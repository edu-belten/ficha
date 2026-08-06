import 'dart:math';

import '../models/ficha.dart';
import '../models/mesa.dart';
import 'contador_fichas.dart';
import 'contexto_jugada.dart';
import 'decision_ia.dart';
import 'estrategia_ia.dart';
import 'inferencia_jugadores.dart';
import 'memoria_parcial.dart';

/// Un candidato de jugada (ficha + extremo) con su puntaje calculado,
/// usado internamente para comparar opciones cuando hay más de una
/// jugada legal disponible.
class _Candidato {
  final Ficha ficha;
  final Extremo extremo;
  final int puntaje;
  _Candidato(this.ficha, this.extremo, this.puntaje);
}

/// Nivel Medio: juega en pareja de verdad, no solo bien su propia
/// mano. Prioridades, en orden:
///
/// 1. Mula de valor alto disponible → se juega primero (no cargarla).
/// 2. Respetar la mano del compañero: si su última jugada conocida
///    (información pública) coincide con un número que también puedes
///    jugar, se prefiere seguir ese palo.
/// 3. Con memoria parcial (no perfecta, a diferencia de Experto) de
///    los pases más obvios: evita regalarle algo fácil a un rival
///    "recordado", evita perjudicar a un compañero "recordado", y
///    reconoce cuándo un número está agotado (nadie más lo tiene) para
///    aprovechar el bloqueo cuando el equipo va ganando la carrera de
///    fichas ("traer la mano").
/// 4. Rol mano/seguidor: si el equipo salió, prefiere soltar fichas de
///    valor bajo; si es seguidor, prefiere soltar valor alto.
class Medio implements EstrategiaIA {
  final Random _random;
  final MemoriaParcial _memoria;

  Medio({Random? random})
    : _random = random ?? Random(),
      _memoria = MemoriaParcial(random: random);

  @override
  DecisionIA decidir(ContextoJugada contexto) {
    final jugables = contexto.mano.fichasJugables(contexto.mesa);
    if (jugables.isEmpty) {
      throw StateError(
        'Medio.decidir() llamado sin jugadas legales disponibles',
      );
    }

    if (contexto.mesa.estaVacia) {
      return DecisionIA(_elegirSalida(jugables), null);
    }

    // Prioridad 1: mula de valor alto.
    final mulaAlta = _mulaAltaSiHay(jugables);
    if (mulaAlta != null) {
      return DecisionIA(mulaAlta, _elegirExtremo(mulaAlta, contexto.mesa));
    }

    // Prioridad 2: respetar la mano del compañero.
    final respetoCompanero = _respetarCompanero(jugables, contexto);
    if (respetoCompanero != null) {
      return respetoCompanero;
    }

    // Prioridad 3 y 4, combinadas por puntaje: memoria parcial de
    // pases (bloqueo/protección) + rol mano/seguidor como desempate.
    return _elegirPorPuntaje(jugables, contexto);
  }

  Ficha _elegirSalida(List<Ficha> jugables) {
    final mulasAltas = jugables.where((f) => f.esMula && f.valor >= 8).toList();
    if (mulasAltas.isNotEmpty) {
      mulasAltas.sort((a, b) => b.valor.compareTo(a.valor));
      return mulasAltas.first;
    }
    final maxValor = jugables.map((f) => f.valor).reduce(max);
    final candidatas = jugables.where((f) => f.valor == maxValor).toList();
    return candidatas[_random.nextInt(candidatas.length)];
  }

  Ficha? _mulaAltaSiHay(List<Ficha> jugables) {
    final mulasAltas = jugables.where((f) => f.esMula && f.valor >= 8).toList();
    if (mulasAltas.isEmpty) return null;
    mulasAltas.sort((a, b) => b.valor.compareTo(a.valor));
    return mulasAltas.first;
  }

  /// Busca la última jugada conocida del compañero (información
  /// pública) y, si alguna ficha jugable comparte número con ella,
  /// la prefiere — simulando "seguir el palo de tu pareja" en vez de
  /// ir por tu cuenta.
  DecisionIA? _respetarCompanero(
    List<Ficha> jugables,
    ContextoJugada contexto,
  ) {
    Ficha? ultimaDelCompanero;
    for (final registro in contexto.historialJugadas.reversed) {
      if (registro.jugador == contexto.companero) {
        ultimaDelCompanero = registro.ficha;
        break;
      }
    }
    if (ultimaDelCompanero == null) return null;

    final numerosCompanero = {ultimaDelCompanero.a, ultimaDelCompanero.b};
    final candidatas = jugables
        .where(
          (f) =>
              numerosCompanero.contains(f.a) || numerosCompanero.contains(f.b),
        )
        .toList();
    if (candidatas.isEmpty) return null;

    // Entre las que respetan al compañero, rompe empate con el rol
    // mano/seguidor (bajo si el equipo salió, alto si es seguidor).
    candidatas.sort(
      (a, b) => contexto.esEquipoMano
          ? a.valor.compareTo(b.valor)
          : b.valor.compareTo(a.valor),
    );
    final ficha = candidatas.first;
    return DecisionIA(ficha, _elegirExtremo(ficha, contexto.mesa));
  }

  DecisionIA _elegirPorPuntaje(List<Ficha> jugables, ContextoJugada contexto) {
    final recordados = _memoria.recordar(contexto.historialPases);
    final descartados = InferenciaJugadores.numerosDescartados(recordados);

    final rivalesDescartados = <int>{};
    descartados.forEach((jugador, numeros) {
      if (jugador != contexto.jugador && jugador != contexto.companero) {
        rivalesDescartados.addAll(numeros);
      }
    });
    final companeroDescartados = descartados[contexto.companero] ?? <int>{};

    final contador = ContadorFichas(contexto.mano, contexto.mesa);

    final izq = contexto.mesa.extremoIzquierdo;
    final der = contexto.mesa.extremoDerecho;

    final candidatos = <_Candidato>[];
    for (final ficha in jugables) {
      final extremos = <Extremo>[];
      if (izq != null && ficha.calza(izq)) extremos.add(Extremo.izquierdo);
      if (der != null && ficha.calza(der)) extremos.add(Extremo.derecho);

      for (final extremo in extremos) {
        final valorExtremo = extremo == Extremo.izquierdo ? izq! : der!;
        final nuevoNumero = ficha.extremoOpuesto(valorExtremo);

        var puntaje = 0;
        if (rivalesDescartados.contains(nuevoNumero)) puntaje += 20;
        if (companeroDescartados.contains(nuevoNumero)) puntaje -= 10;

        // "Traer la mano": si el número queda agotado (nadie más lo
        // tiene, ni rival ni compañero), el bloqueo generalizado
        // favorece al equipo cuando alguno de los dos va adelante en
        // la carrera de fichas — no perjudica de forma selectiva a tu
        // propio compañero más que a los rivales.
        if (contador.estaAgotado(nuevoNumero)) puntaje += 15;

        // Rol mano/seguidor como desempate fino: equipo con la mano
        // prefiere soltar bajo, seguidor prefiere soltar alto.
        puntaje += contexto.esEquipoMano ? -ficha.valor : ficha.valor;

        candidatos.add(_Candidato(ficha, extremo, puntaje));
      }
    }

    candidatos.sort((a, b) => b.puntaje.compareTo(a.puntaje));
    final mejorPuntaje = candidatos.first.puntaje;
    final empatados = candidatos
        .where((c) => c.puntaje == mejorPuntaje)
        .toList();
    final elegido = empatados[_random.nextInt(empatados.length)];

    return DecisionIA(elegido.ficha, elegido.extremo);
  }

  Extremo _elegirExtremo(Ficha ficha, Mesa mesa) {
    final extremosPosibles = <Extremo>[];
    final izq = mesa.extremoIzquierdo;
    final der = mesa.extremoDerecho;
    if (izq != null && ficha.calza(izq)) {
      extremosPosibles.add(Extremo.izquierdo);
    }
    if (der != null && ficha.calza(der)) {
      extremosPosibles.add(Extremo.derecho);
    }
    return extremosPosibles[_random.nextInt(extremosPosibles.length)];
  }
}
