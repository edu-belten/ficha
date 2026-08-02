/// Representa una ficha de dominó.
/// Los dos números se almacenan siempre en orden canónico (a <= b),
/// para que 3-5 y 5-3 se traten como la misma ficha sin ambigüedad.
class Ficha {
  final int a;
  final int b;

  Ficha(int x, int y)
      : a = x <= y ? x : y,
        b = x <= y ? y : x {
    assert(x >= 0 && x <= 6, 'Los valores de una ficha deben estar entre 0 y 6');
    assert(y >= 0 && y <= 6, 'Los valores de una ficha deben estar entre 0 y 6');
  }

  /// Es "mula" (doble) si sus dos extremos son iguales.
  bool get esMula => a == b;

  /// Puntos que vale la ficha (suma de sus dos extremos).
  int get valor => a + b;

  /// ¿Esta ficha se puede jugar contra el número expuesto [extremo]?
  bool calza(int extremo) => a == extremo || b == extremo;

  /// Dado el extremo contra el que se jugó esta ficha, regresa
  /// el número que queda expuesto del otro lado tras colocarla.
  int extremoOpuesto(int extremo) {
    if (a == extremo) return b;
    if (b == extremo) return a;
    throw ArgumentError(
        'La ficha $this no calza con el extremo $extremo');
  }

  @override
  bool operator ==(Object other) =>
      other is Ficha && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => '$a-$b';
}
