import 'ficha.dart';
import 'jugador.dart';
import 'mesa.dart';

/// Registro público de una jugada: quién jugó qué ficha y en qué
/// extremo (null si fue la ficha de salida). Se usa para que la IA
/// pueda saber qué palo jugó recientemente su compañero, sin necesitar
/// ver su mano completa — solo lo que ya hizo públicamente.
class RegistroJugada {
  final Jugador jugador;
  final Ficha ficha;
  final Extremo? extremo;

  RegistroJugada({
    required this.jugador,
    required this.ficha,
    required this.extremo,
  });
}
