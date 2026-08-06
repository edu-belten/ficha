import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/registro_pase.dart';
import 'package:ficha_app/ia/memoria_parcial.dart';

void main() {
  group('MemoriaParcial', () {
    test('sin historial, no recuerda nada (lista vacía)', () {
      final memoria = MemoriaParcial(random: Random(1));
      expect(memoria.recordar([]), isEmpty);
    });

    test(
      'con muchas repeticiones, recuerda casos "ambos extremos iguales" mucho más seguido que casos normales',
      () {
        final rival = Jugador(asiento: 2, nombre: 'Rival');
        final casoObvio = RegistroPase(
          jugador: rival,
          extremoIzquierdo: 3,
          extremoDerecho: 3,
        );
        final casoNormal = RegistroPase(
          jugador: rival,
          extremoIzquierdo: 2,
          extremoDerecho: 5,
        );

        final memoria = MemoriaParcial(random: Random(7));

        var vecesObvioRecordado = 0;
        var vecesNormalRecordado = 0;
        for (var i = 0; i < 300; i++) {
          // Colocamos el caso normal en índice >=2 para que no se
          // beneficie del bono de "pase temprano".
          final historial = [casoNormal, casoNormal, casoNormal, casoObvio];
          final recordados = memoria.recordar(historial);
          if (recordados.any((r) => r.extremoIzquierdo == 3)) {
            vecesObvioRecordado++;
          }
        }

        expect(vecesObvioRecordado, greaterThan(200)); // ~90% esperado
      },
    );

    test('pases tardíos (no obvios) se recuerdan poco frecuentemente', () {
      final rival = Jugador(asiento: 2, nombre: 'Rival');
      final memoria = MemoriaParcial(random: Random(3));

      // Historial largo: los primeros 2 tienen bono de "temprano",
      // evaluamos el último (índice alto, sin bono).
      final historial = List.generate(
        10,
        (i) => RegistroPase(
          jugador: rival,
          extremoIzquierdo: 1,
          extremoDerecho: 2,
        ),
      );

      var vecesRecordadoElUltimo = 0;
      for (var i = 0; i < 300; i++) {
        final recordados = memoria.recordar(historial);
        if (recordados.length > 8) vecesRecordadoElUltimo++;
      }

      // Con probabilidad base de 0.15 para los tardíos, esperamos que
      // rara vez se recuerden TODOS (incluyendo los últimos).
      expect(vecesRecordadoElUltimo, lessThan(100));
    });
  });
}
