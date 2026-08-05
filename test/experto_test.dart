import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/mano.dart';
import 'package:ficha_app/models/mesa.dart';
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

    test(
      'sin historial de pases, se comporta como Medio (prefiere mayor valor)',
      () {
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
        );

        final experto = Experto(random: Random(1));
        final decision = experto.decidir(contexto);
        expect(decision.ficha, equals(Ficha(5, 6)));
      },
    );

    test(
      'prioriza dejar expuesto un número que un rival ya descartó (pasó)',
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

        // El rival pasó cuando un extremo mostraba 6 → sabemos que no tiene 6.
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

        // Jugar 2-6 deja expuesto el 6 (el rival no lo tiene, lo "ahoga").
        // Jugar 2-4 deja expuesto el 4 (sin info). Debe preferir 2-6.
        expect(decision.ficha, equals(Ficha(2, 6)));
      },
    );

    test(
      'evita, entre opciones sin ventaja ofensiva, dejar expuesto un número que el compañero ya descartó',
      () {
        final mesa = Mesa();
        mesa.colocarFichaSalida(Ficha(1, 2)); // extremos: 1 (izq), 2 (der)

        final jugador = Jugador(
          asiento: 1,
          nombre: 'Yo',
          manoInicial: Mano([Ficha(1, 4), Ficha(1, 5)]),
        );
        final companero = Jugador(asiento: 3, nombre: 'Compa');

        // El compañero pasó cuando un extremo mostraba 4 → no tiene 4.
        final historial = [
          RegistroPase(
            jugador: companero,
            extremoIzquierdo: 4,
            extremoDerecho: null,
          ),
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

        // Ficha(1,4) deja expuesto el 4 (penalizado). Ficha(1,5) deja
        // expuesto el 5 (neutral, y de mayor valor). Debe preferir 1-5.
        expect(decision.ficha, equals(Ficha(1, 5)));
      },
    );
  });
}
