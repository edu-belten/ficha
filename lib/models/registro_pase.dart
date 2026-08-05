import 'jugador.dart';

/// Registro público de un pase legítimo: quién pasó y qué extremos
/// estaban expuestos en la mesa en ese momento. Los pases en falso NO
/// se registran aquí — no dicen nada real sobre la mano del jugador
/// (sí tenía jugada, solo no la declaró).
class RegistroPase {
  final Jugador jugador;
  final int? extremoIzquierdo;
  final int? extremoDerecho;

  RegistroPase({
    required this.jugador,
    required this.extremoIzquierdo,
    required this.extremoDerecho,
  });
}
