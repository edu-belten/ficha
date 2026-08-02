import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/mesa.dart';

void main() {
  group('Mesa', () {
    test('empieza vacía', () {
      final mesa = Mesa();
      expect(mesa.estaVacia, isTrue);
      expect(mesa.extremoIzquierdo, isNull);
      expect(mesa.extremoDerecho, isNull);
    });

    test('colocarFichaSalida establece ambos extremos', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      expect(mesa.estaVacia, isFalse);
      expect(mesa.extremoIzquierdo, 3);
      expect(mesa.extremoDerecho, 5);
    });

    test('jugar() actualiza el extremo correcto', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      mesa.jugar(Ficha(5, 6), Extremo.derecho);
      expect(mesa.extremoDerecho, 6);
      expect(mesa.extremoIzquierdo, 3); // no debe cambiar
    });

    test('jugar() lanza error si la ficha no calza', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      expect(
        () => mesa.jugar(Ficha(1, 2), Extremo.izquierdo),
        throwsArgumentError,
      );
    });

    test('totalPintasJugadas suma correctamente', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5)); // 8 puntos
      mesa.jugar(Ficha(5, 6), Extremo.derecho); // 11 puntos
      expect(mesa.totalPintasJugadas, 19);
    });

    test('sePuedeJugar detecta jugadas posibles e imposibles', () {
      final mesa = Mesa();
      mesa.colocarFichaSalida(Ficha(3, 5));
      expect(mesa.sePuedeJugar(Ficha(5, 6)), isTrue);
      expect(mesa.sePuedeJugar(Ficha(1, 2)), isFalse);
    });
  });
}
