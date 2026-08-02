import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/mano.dart';
import 'package:ficha_app/models/mesa.dart';

void main() {
  group('Mano', () {
    test('empieza vacía si no se le dan fichas iniciales', () {
      final mano = Mano();
      expect(mano.estaVacia, isTrue);
      expect(mano.cantidadFichas, 0);
    });

    test('se puede crear con fichas iniciales (repartir)', () {
      final mano = Mano([Ficha(0, 0), Ficha(3, 5), Ficha(6, 6)]);
      expect(mano.cantidadFichas, 3);
    });

    test('agregar añade una ficha', () {
      final mano = Mano();
      mano.agregar(Ficha(2, 4));
      expect(mano.cantidadFichas, 1);
      expect(mano.tieneFicha(Ficha(4, 2)), isTrue); // orden canónico
    });

    test('quitar remueve la ficha correcta', () {
      final mano = Mano([Ficha(3, 5), Ficha(6, 6)]);
      mano.quitar(Ficha(5, 3)); // mismo orden canónico que 3-5
      expect(mano.cantidadFichas, 1);
      expect(mano.tieneFicha(Ficha(3, 5)), isFalse);
      expect(mano.tieneFicha(Ficha(6, 6)), isTrue);
    });

    test('quitar lanza error si la ficha no está en la mano', () {
      final mano = Mano([Ficha(3, 5)]);
      expect(() => mano.quitar(Ficha(1, 2)), throwsArgumentError);
    });

    test('totalPuntos suma correctamente', () {
      final mano = Mano([Ficha(3, 5), Ficha(0, 0), Ficha(6, 6)]);
      expect(mano.totalPuntos, 8 + 0 + 12);
    });

    test('fichasJugables regresa todo si la mesa está vacía', () {
      final mesa = Mesa();
      final mano = Mano([Ficha(3, 5), Ficha(6, 6)]);
      expect(mano.fichasJugables(mesa).length, 2);
    });

    test('fichasJugables filtra correctamente según la mesa', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      final mano = Mano([Ficha(5, 6), Ficha(1, 2), Ficha(3, 3)]);
      final jugables = mano.fichasJugables(mesa);
      expect(jugables.length, 2); // 5-6 calza con 5, 3-3 calza con 3
      expect(jugables.contains(Ficha(1, 2)), isFalse);
    });

    test('tieneJugadaLegal detecta correctamente', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));

      final manoConJugada = Mano([Ficha(5, 6)]);
      expect(manoConJugada.tieneJugadaLegal(mesa), isTrue);

      final manoSinJugada = Mano([Ficha(1, 2)]);
      expect(manoSinJugada.tieneJugadaLegal(mesa), isFalse);
    });
  });
}
