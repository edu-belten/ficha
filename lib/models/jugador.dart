import 'mano.dart';

/// Representa a un jugador en la mesa: su asiento, nombre y su mano actual.
class Jugador {
  final int asiento; // 1, 2, 3 o 4
  final String nombre;
  final Mano mano;

  Jugador({required this.asiento, required this.nombre, Mano? manoInicial})
    : mano = manoInicial ?? Mano() {
    if (asiento < 1 || asiento > 4) {
      throw ArgumentError('El asiento debe ser 1, 2, 3 o 4');
    }
  }

  @override
  String toString() => '$nombre (asiento $asiento)';
}
