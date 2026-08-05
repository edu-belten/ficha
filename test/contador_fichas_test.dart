import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/mano.dart';
import 'package:ficha_app/models/mesa.dart';
import 'package:ficha_app/ia/contador_fichas.dart';

void main() {
  group('ContadorFichas', () {
    test('cuenta fichas visibles combinando mesa y mano propia', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      mesa.jugar(Ficha(3, 3), Extremo.izquierdo);

      final mano = Mano([Ficha(3, 6)]);
      final contador = ContadorFichas(mano, mesa);

      // Fichas con el número 3 visibles: 3-5, 3-3 (mesa) y 3-6 (mano) = 3.
      expect(contador.fichasVisiblesDe(3), 3);
    });

    test('estaAgotado es false si no se han visto las 7 fichas del número', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      final mano = Mano([Ficha(0, 0)]);
      final contador = ContadorFichas(mano, mesa);

      expect(contador.estaAgotado(3), isFalse);
    });

    test(
      'estaAgotado es true cuando las 7 fichas de un número son visibles',
      () {
        final mesa = Mesa();
        mesa.colocarFichaSalida(Ficha(0, 3));
        mesa.jugar(Ficha(1, 3), Extremo.derecho);
        // Mesa ahora tiene: 0-3, 1-3 (2 fichas con el número 3).

        final mano = Mano([
          Ficha(2, 3),
          Ficha(3, 3),
          Ficha(3, 4),
          Ficha(3, 5),
          Ficha(3, 6),
        ]); // 5 fichas más con el número 3.

        final contador = ContadorFichas(mano, mesa);

        // Total: 2 (mesa) + 5 (mano) = 7 → todas las fichas del 3 son visibles.
        expect(contador.fichasVisiblesDe(3), 7);
        expect(contador.estaAgotado(3), isTrue);
      },
    );

    test('un número sin ninguna ficha vista tiene 0 fichas visibles', () {
      final mesa = Mesa();
      final mano = Mano([Ficha(0, 0)]);
      final contador = ContadorFichas(mano, mesa);

      expect(contador.fichasVisiblesDe(6), 0);
      expect(contador.estaAgotado(6), isFalse);
    });
  });
}
