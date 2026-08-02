import 'ficha.dart';
import 'mesa.dart';

/// Representa la mano de un jugador: el conjunto de fichas que tiene
/// disponibles para jugar en un momento dado de la partida.
class Mano {
  final List<Ficha> _fichas;

  Mano([List<Ficha>? fichasIniciales])
    : _fichas = List.from(fichasIniciales ?? []);

  /// Fichas actuales en la mano. Solo lectura.
  List<Ficha> get fichas => List.unmodifiable(_fichas);

  /// Cuántas fichas le quedan al jugador.
  int get cantidadFichas => _fichas.length;

  /// ¿La mano está vacía? (relevante para detectar cierre por dominación)
  bool get estaVacia => _fichas.isEmpty;

  /// Suma de puntos (pintas) de todas las fichas en la mano.
  /// Esto es lo que cuenta el equipo rival cuando alguien cierra,
  /// o cada equipo cuando hay tranca.
  int get totalPuntos => _fichas.fold(0, (suma, ficha) => suma + ficha.valor);

  /// Agrega una ficha a la mano (usado al repartir).
  void agregar(Ficha ficha) {
    _fichas.add(ficha);
  }

  /// Quita una ficha de la mano (usado cuando se juega).
  /// Lanza error si la ficha no está en la mano.
  void quitar(Ficha ficha) {
    final removida = _fichas.remove(ficha);
    if (!removida) {
      throw ArgumentError('La ficha $ficha no está en esta mano');
    }
  }

  /// ¿Esta mano tiene la ficha exacta [ficha]?
  bool tieneFicha(Ficha ficha) => _fichas.contains(ficha);

  /// De todas las fichas en la mano, ¿cuáles son jugables
  /// ahora mismo contra el estado actual de [mesa]?
  List<Ficha> fichasJugables(Mesa mesa) {
    if (mesa.estaVacia) {
      return List.unmodifiable(_fichas); // cualquier ficha sirve de salida
    }
    return _fichas.where((f) => mesa.sePuedeJugar(f)).toList();
  }

  /// ¿Existe al menos una jugada legal contra el estado actual de [mesa]?
  /// Se usa para validar si declarar "paso" es legítimo.
  bool tieneJugadaLegal(Mesa mesa) => fichasJugables(mesa).isNotEmpty;
}
