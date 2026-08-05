import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/mano.dart';
import 'package:ficha_app/models/mesa.dart';
import 'package:ficha_app/ia/contexto_jugada.dart';
import 'package:ficha_app/ia/medio.dart';

ContextoJugada _contexto(Mano mano, Mesa mesa) {
  final jugador = Jugador(asiento: 1, nombre: 'Yo', manoInicial: mano);
  final companero = Jugador(asiento: 3, nombre: 'Compa');
  return ContextoJugada(
    jugador: jugador,
    companero: companero,
    mano: mano,
    mesa: mesa,
    historialPases: [],
  );
}

void main() {
  group('Medio', () {
    test('lanza error si no hay jugadas legales', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(0, 1));
      final mano = Mano([Ficha(3, 4)]);
      final medio = Medio(random: Random(1));
      expect(() => medio.decidir(_contexto(mano, mesa)), throwsStateError);
    });

    test('prioriza jugar una mula alta si está disponible', () {
      final mesa = Mesa();
      final mano = Mano([Ficha(6, 6), Ficha(2, 3)]);
      final medio = Medio(random: Random(1));

      final decision = medio.decidir(_contexto(mano, mesa));
      expect(decision.ficha, equals(Ficha(6, 6)));
    });

    test('sin mula alta disponible, elige la ficha jugable de mayor valor', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(2, 5));
      final mano = Mano([Ficha(5, 6), Ficha(2, 2)]); // valor 11 vs valor 4
      final medio = Medio(random: Random(1));

      final decision = medio.decidir(_contexto(mano, mesa));
      expect(decision.ficha, equals(Ficha(5, 6)));
    });

    test('el extremo elegido siempre calza de verdad con la ficha', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      final mano = Mano([Ficha(3, 3)]); // solo calza en el extremo 3
      final medio = Medio(random: Random(3));

      final decision = medio.decidir(_contexto(mano, mesa));
      final valorExtremo = decision.extremo == Extremo.izquierdo
          ? mesa.extremoIzquierdo!
          : mesa.extremoDerecho!;
      expect(decision.ficha.calza(valorExtremo), isTrue);
    });

    test('entre dos mulas altas jugables, prefiere la de mayor valor', () {
      final mesa = Mesa();
      final mano = Mano([Ficha(4, 4), Ficha(6, 6)]);
      final medio = Medio(random: Random(1));

      final decision = medio.decidir(_contexto(mano, mesa));
      expect(decision.ficha, equals(Ficha(6, 6)));
    });
  });
}
