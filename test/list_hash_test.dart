import 'package:flutter_test/flutter_test.dart';
import 'package:tecs/list_hash.dart';

void main() {
  test('equality check', () {
    final x = ListHash(<int>[2, 1, 3]);
    final y = ListHash(<int>[1, 3, 2]);
    expect(x, y);

    final a = ListHash(<int>[0]);
    final b = ListHash(<int>[0]);
    expect(a, b);

    final k = ListHash(<int>[0, 1, 2]);
    final m = ListHash(<int>[0, 1, 3]);
    expect(k, isNot(m));
  });

  test('add and remove', () {
    final x = ListHash(<int>[2, 1, 3, 4]);
    final y = ListHash(<int>[1, 3, 2]);
    expect(x, isNot(y));

    x.remove(4);
    expect(x, y);

    y.add(5);
    expect(x, isNot(y));

    x.add(5);
    expect(x, y);
  });

  test('copy must be equal to itself', () {
    final x = ListHash(<int>[2, 1, 3]);
    final y = x.copy();
    expect(x, y);
  });

  test('containIndices', () {
    final x = ListHash(<int>[2, 1, 3]);
    final y = ListHash(<int>[0, 1, 3, 2, 4, 6, 5]);
    final z = ListHash(<int>[1, 6, 4, 2]);
    final w = ListHash(<int>[1, 4, 5, 2]);

    expect(y.contains(x), true);
    expect(x.contains(y), false);
    expect(y.contains(z), true);
    expect(z.contains(w), false);
    expect(w.contains(z), false);
  });
}
