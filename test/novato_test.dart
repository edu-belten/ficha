import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/mano.dart';
import 'package:ficha_app/models/mesa.dart';
import 'package:ficha_app/ia/contexto_jugada.dart';
import 'package:ficha_app/ia/novato.dart';

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
  group('Novato', () {
    test('lanza error si no hay jugadas legales', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(0, 1));
      final mano = Mano([Ficha(3, 4)]); // no calza con 0 ni 1

      final novato = Novato(random: Random(1));
      expect(() => novato.decidir(_contexto(mano, mesa)), throwsStateError);
    });

    test(
      'con mesa vacía, elige una ficha de la mano y no requiere extremo',
      () {
        final mesa = Mesa();
        final mano = Mano([Ficha(2, 3), Ficha(5, 5)]);

        final novato = Novato(random: Random(1));
        final decision = novato.decidir(_contexto(mano, mesa));

        expect(mano.tieneFicha(decision.ficha), isTrue);
        expect(decision.extremo, isNull);
      },
    );

    test('siempre elige una ficha realmente jugable contra la mesa', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      final mano = Mano([Ficha(5, 6), Ficha(1, 2), Ficha(3, 3)]);

      final novato = Novato(random: Random(42));
      final decision = novato.decidir(_contexto(mano, mesa));

      expect(
        decision.ficha.calza(mesa.extremoIzquierdo!) ||
            decision.ficha.calza(mesa.extremoDerecho!),
        isTrue,
      );
      expect(decision.extremo, isNotNull);
    });

    test('el extremo elegido siempre calza de verdad con la ficha', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      final mano = Mano([Ficha(5, 6)]); // solo calza con el 5

      final novato = Novato(random: Random(7));
      final decision = novato.decidir(_contexto(mano, mesa));

      final valorExtremo = decision.extremo == Extremo.izquierdo
          ? mesa.extremoIzquierdo!
          : mesa.extremoDerecho!;
      expect(decision.ficha.calza(valorExtremo), isTrue);
    });

    test(
      'con muchas repeticiones, prefiere fichas de valor alto más seguido que las de valor bajo',
      () {
        final mesa = Mesa();
        final mano = Mano([Ficha(0, 0), Ficha(6, 6)]); // valor 0 vs valor 12
        final novato = Novato(random: Random(99));

        var vecesAlta = 0;
        var vecesBaja = 0;
        for (var i = 0; i < 500; i++) {
          final decision = novato.decidir(_contexto(mano, mesa));
          if (decision.ficha == Ficha(6, 6)) {
            vecesAlta++;
          } else {
            vecesBaja++;
          }
        }

        expect(vecesAlta, greaterThan(vecesBaja));
      },
    );
  });
}
