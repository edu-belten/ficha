import 'ficha.dart';

/// Los dos extremos abiertos de la mesa, donde se puede jugar.
enum Extremo { izquierdo, derecho }

/// Representa el estado de la mesa: la fila de fichas jugadas
/// y los dos extremos abiertos donde se puede jugar en este momento.
class Mesa {
  final List<Ficha> _historial = [];

  int? _extremoIzquierdo;
  int? _extremoDerecho;

  /// ¿La mesa no tiene ninguna ficha todavía?
  bool get estaVacia => _historial.isEmpty;

  /// Historial completo de fichas jugadas, en orden. Solo lectura.
  List<Ficha> get historial => List.unmodifiable(_historial);

  /// El número expuesto en el extremo izquierdo (null si la mesa está vacía).
  int? get extremoIzquierdo => _extremoIzquierdo;

  /// El número expuesto en el extremo derecho (null si la mesa está vacía).
  int? get extremoDerecho => _extremoDerecho;

  /// Suma de puntos (pintas) de todas las fichas jugadas hasta ahora.
  int get totalPintasJugadas =>
      _historial.fold(0, (suma, ficha) => suma + ficha.valor);

  /// Coloca la ficha de salida (la primera de la partida).
  /// No requiere calzar con nada, porque la mesa está vacía.
  void colocarFichaSalida(Ficha ficha) {
    if (!estaVacia) {
      throw StateError(
        'La mesa ya tiene fichas; usa jugar() en vez de colocarFichaSalida()',
      );
    }
    _historial.add(ficha);
    _extremoIzquierdo = ficha.a;
    _extremoDerecho = ficha.b;
  }

  /// Coloca [ficha] contra el [extremo] indicado.
  /// Lanza error si la mesa está vacía o si la ficha no calza ahí.
  void jugar(Ficha ficha, Extremo extremo) {
    if (estaVacia) {
      throw StateError('La mesa está vacía; usa colocarFichaSalida() primero');
    }

    final valorExtremo = extremo == Extremo.izquierdo
        ? _extremoIzquierdo!
        : _extremoDerecho!;

    if (!ficha.calza(valorExtremo)) {
      throw ArgumentError(
        'La ficha $ficha no calza con el extremo $valorExtremo',
      );
    }

    final nuevoExtremo = ficha.extremoOpuesto(valorExtremo);
    _historial.add(ficha);

    if (extremo == Extremo.izquierdo) {
      _extremoIzquierdo = nuevoExtremo;
    } else {
      _extremoDerecho = nuevoExtremo;
    }
  }

  /// ¿Esta ficha se puede jugar en algún extremo de la mesa ahora mismo?
  bool sePuedeJugar(Ficha ficha) {
    if (estaVacia) return true; // cualquier ficha sirve de salida
    return ficha.calza(_extremoIzquierdo!) || ficha.calza(_extremoDerecho!);
  }
}
