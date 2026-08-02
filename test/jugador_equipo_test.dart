import 'package:flutter_test/flutter_test.dart';
import 'package:ficha_app/models/ficha.dart';
import 'package:ficha_app/models/jugador.dart';
import 'package:ficha_app/models/equipo.dart';

void main() {
  group('Jugador', () {
    test('se crea con asiento y nombre válidos', () {
      final j = Jugador(asiento: 1, nombre: 'Eduardo');
      expect(j.asiento, 1);
      expect(j.nombre, 'Eduardo');
      expect(j.mano.estaVacia, isTrue);
    });

    test('lanza error si el asiento no está entre 1 y 4', () {
      expect(() => Jugador(asiento: 0, nombre: 'X'), throwsArgumentError);
      expect(() => Jugador(asiento: 5, nombre: 'X'), throwsArgumentError);
    });
  });

  group('Equipo', () {
    late Jugador j1;
    late Jugador j3;
    late Equipo equipo13;

    setUp(() {
      j1 = Jugador(asiento: 1, nombre: 'Eduardo');
      j3 = Jugador(asiento: 3, nombre: 'Compañero');
      equipo13 = Equipo(jugadorA: j1, jugadorB: j3, nombre: 'Equipo 1-3');
    });

    test('tieneJugador identifica correctamente a sus miembros', () {
      final ajeno = Jugador(asiento: 2, nombre: 'Rival');
      expect(equipo13.tieneJugador(j1), isTrue);
      expect(equipo13.tieneJugador(j3), isTrue);
      expect(equipo13.tieneJugador(ajeno), isFalse);
    });

    test('companeroDe regresa al compañero correcto', () {
      expect(equipo13.companeroDe(j1), equals(j3));
      expect(equipo13.companeroDe(j3), equals(j1));
    });

    test('companeroDe lanza error si el jugador no es del equipo', () {
      final ajeno = Jugador(asiento: 2, nombre: 'Rival');
      expect(() => equipo13.companeroDe(ajeno), throwsArgumentError);
    });

    test('totalPintasEnMano suma las manos de ambos jugadores', () {
      j1.mano.agregar(Ficha(3, 5)); // 8
      j3.mano.agregar(Ficha(6, 6)); // 12
      expect(equipo13.totalPintasEnMano, 20);
    });

    test('agregarPuntos y resetearMarcador funcionan correctamente', () {
      equipo13.agregarPuntos(30);
      expect(equipo13.marcadorAcumulado, 30);
      equipo13.agregarPuntos(20);
      expect(equipo13.marcadorAcumulado, 50);
      equipo13.resetearMarcador();
      expect(equipo13.marcadorAcumulado, 0);
    });
  });
}
