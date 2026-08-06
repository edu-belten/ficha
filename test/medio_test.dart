import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/mano.dart';
import 'package:ficha_app/models/mesa.dart';
import 'package:ficha_app/models/registro_jugada.dart';
import 'package:ficha_app/ia/contexto_jugada.dart';
import 'package:ficha_app/ia/medio.dart';

ContextoJugada _contexto(
  Mano mano,
  Mesa mesa, {
  Jugador? companero,
  List<RegistroJugada> historialJugadas = const [],
  bool esEquipoMano = false,
  int fichasCompanero = 7,
}) {
  final jugador = Jugador(asiento: 1, nombre: 'Yo', manoInicial: mano);
  return ContextoJugada(
    jugador: jugador,
    companero: companero ?? Jugador(asiento: 3, nombre: 'Compa'),
    mano: mano,
    mesa: mesa,
    historialPases: const [],
    historialJugadas: historialJugadas,
    esEquipoMano: esEquipoMano,
    fichasCompanero: fichasCompanero,
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

    test('respeta la mano del compañero cuando puede seguir su palo', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(2, 4));
      mesa.jugar(Ficha(4, 5), Extremo.derecho); // extremos: 2, 5

      final companero = Jugador(asiento: 3, nombre: 'Compa');
      // El compañero jugó 4-5 (números 4 y 5).
      final historial = [
        RegistroJugada(
          jugador: companero,
          ficha: Ficha(4, 5),
          extremo: Extremo.derecho,
        ),
      ];

      // Mano: 2-6 calza en 2 pero NO respeta al compañero (no tiene 4 ni 5).
      // 5-6 calza en 5 y SÍ respeta al compañero (tiene el 5).
      final mano = Mano([Ficha(2, 6), Ficha(5, 6)]);

      final medio = Medio(random: Random(1));
      final decision = medio.decidir(
        _contexto(
          mano,
          mesa,
          companero: companero,
          historialJugadas: historial,
        ),
      );

      expect(decision.ficha, equals(Ficha(5, 6)));
    });

    test(
      'sin mula alta ni jugada del compañero que respetar, con equipo mano prefiere valor bajo',
      () {
        final mesa = Mesa();
        mesa.colocarFichaSalida(Ficha(2, 5));
        final mano = Mano([Ficha(5, 6), Ficha(2, 2)]); // valor 11 vs valor 4

        final medio = Medio(random: Random(1));
        final decision = medio.decidir(
          _contexto(mano, mesa, esEquipoMano: true),
        );

        // Con la mano, se prefiere soltar BAJO -> Ficha(2,2) valor 4.
        expect(decision.ficha, equals(Ficha(2, 2)));
      },
    );

    test(
      'sin mula alta ni jugada del compañero que respetar, siendo seguidor prefiere valor alto',
      () {
        final mesa = Mesa();
        mesa.colocarFichaSalida(Ficha(2, 5));
        final mano = Mano([Ficha(5, 6), Ficha(2, 2)]);

        final medio = Medio(random: Random(1));
        final decision = medio.decidir(
          _contexto(mano, mesa, esEquipoMano: false),
        );

        // Siendo seguidor, se prefiere soltar ALTO -> Ficha(5,6) valor 11.
        expect(decision.ficha, equals(Ficha(5, 6)));
      },
    );

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
