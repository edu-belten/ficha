import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/mano.dart';
import 'package:ficha_app/models/mesa.dart';
import 'package:ficha_app/models/registro_jugada.dart';
import 'package:ficha_app/models/registro_pase.dart';
import 'package:ficha_app/ia/contexto_jugada.dart';
import 'package:ficha_app/ia/experto.dart';

void main() {
  group('Experto', () {
    test('lanza error si no hay jugadas legales', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(0, 1));
      final jugador = Jugador(
        asiento: 1,
        nombre: 'Yo',
        manoInicial: Mano([Ficha(3, 4)]),
      );
      final companero = Jugador(asiento: 3, nombre: 'Compa');
      final contexto = ContextoJugada(
        jugador: jugador,
        companero: companero,
        mano: jugador.mano,
        mesa: mesa,
        historialPases: [],
      );

      final experto = Experto(random: Random(1));
      expect(() => experto.decidir(contexto), throwsStateError);
    });

    test('sin señales, con equipo seguidor prefiere el valor más alto', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(2, 5));
      final jugador = Jugador(
        asiento: 1,
        nombre: 'Yo',
        manoInicial: Mano([Ficha(5, 6), Ficha(2, 2)]),
      );
      final companero = Jugador(asiento: 3, nombre: 'Compa');
      final contexto = ContextoJugada(
        jugador: jugador,
        companero: companero,
        mano: jugador.mano,
        mesa: mesa,
        historialPases: [],
        esEquipoMano: false, // seguidor -> prefiere valor alto
      );

      final experto = Experto(random: Random(1));
      final decision = experto.decidir(contexto);
      expect(decision.ficha, equals(Ficha(5, 6)));
    });

    test('sin señales, con equipo mano prefiere el valor más bajo', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(2, 5));
      final jugador = Jugador(
        asiento: 1,
        nombre: 'Yo',
        manoInicial: Mano([Ficha(5, 6), Ficha(2, 2)]),
      );
      final companero = Jugador(asiento: 3, nombre: 'Compa');
      final contexto = ContextoJugada(
        jugador: jugador,
        companero: companero,
        mano: jugador.mano,
        mesa: mesa,
        historialPases: [],
        esEquipoMano: true, // tiene la mano -> prefiere valor bajo
      );

      final experto = Experto(random: Random(1));
      final decision = experto.decidir(contexto);
      expect(decision.ficha, equals(Ficha(2, 2)));
    });

    test(
      'prioriza dejar expuesto un número que un rival descartó (certeza)',
      () {
        final mesa = Mesa();
        mesa.colocarFichaSalida(Ficha(2, 3)); // extremos: 2 (izq), 3 (der)

        final jugador = Jugador(
          asiento: 1,
          nombre: 'Yo',
          manoInicial: Mano([Ficha(2, 4), Ficha(2, 6)]),
        );
        final companero = Jugador(asiento: 3, nombre: 'Compa');
        final rival = Jugador(asiento: 2, nombre: 'Rival');

        final historial = [
          RegistroPase(jugador: rival, extremoIzquierdo: 1, extremoDerecho: 6),
        ];

        final contexto = ContextoJugada(
          jugador: jugador,
          companero: companero,
          mano: jugador.mano,
          mesa: mesa,
          historialPases: historial,
        );

        final experto = Experto(random: Random(1));
        final decision = experto.decidir(contexto);

        expect(decision.ficha, equals(Ficha(2, 6)));
      },
    );

    test(
      'evita dejar expuesto un número reforzado en un rival (aunque no sea certeza)',
      () {
        final mesa = Mesa();
        mesa.colocarFichaSalida(Ficha(1, 2)); // extremos: 1 (izq), 2 (der)

        final jugador = Jugador(
          asiento: 1,
          nombre: 'Yo',
          manoInicial: Mano([Ficha(1, 4), Ficha(1, 5)]),
        );
        final companero = Jugador(asiento: 3, nombre: 'Compa');
        final rival = Jugador(asiento: 2, nombre: 'Rival');

        // El rival jugó el número 4 dos veces -> reforzado.
        final historialJugadas = [
          RegistroJugada(jugador: rival, ficha: Ficha(4, 6), extremo: null),
          RegistroJugada(
            jugador: rival,
            ficha: Ficha(4, 0),
            extremo: Extremo.izquierdo,
          ),
        ];

        final contexto = ContextoJugada(
          jugador: jugador,
          companero: companero,
          mano: jugador.mano,
          mesa: mesa,
          historialPases: [],
          historialJugadas: historialJugadas,
        );

        final experto = Experto(random: Random(1));
        final decision = experto.decidir(contexto);

        // Ficha(1,4) deja expuesto el 4 (reforzado en el rival, penalizado).
        // Ficha(1,5) deja expuesto el 5 (neutral). Debe preferir 1-5,
        // aunque 1-4 valga más (5 vs 6) — la señal de reforzado pesa más.
        expect(decision.ficha, equals(Ficha(1, 5)));
      },
    );

    test('favorece exponer un número reforzado en el compañero', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(1, 2));

      final jugador = Jugador(
        asiento: 1,
        nombre: 'Yo',
        manoInicial: Mano([Ficha(1, 4), Ficha(1, 5)]),
      );
      final companero = Jugador(asiento: 3, nombre: 'Compa');

      // El compañero jugó el número 4 dos veces -> reforzado.
      final historialJugadas = [
        RegistroJugada(jugador: companero, ficha: Ficha(4, 6), extremo: null),
        RegistroJugada(
          jugador: companero,
          ficha: Ficha(4, 0),
          extremo: Extremo.izquierdo,
        ),
      ];

      final contexto = ContextoJugada(
        jugador: jugador,
        companero: companero,
        mano: jugador.mano,
        mesa: mesa,
        historialPases: [],
        historialJugadas: historialJugadas,
      );

      final experto = Experto(random: Random(1));
      final decision = experto.decidir(contexto);

      // Ficha(1,4) deja expuesto el 4 (reforzado en compañero, favorecido).
      expect(decision.ficha, equals(Ficha(1, 4)));
    });
  });
}
