import 'package:flutter_test/flutter_test.dart';
import 'package:tecs/list_hash.dart';

void main() {
  test('init sort working', () {
    final x = ListHash(<int>[2, 1, 3]);

    for (int i = 0; i < x.length; i++) {
      expect(x.list[i], i + 1);
    }
  });

  test('equality check', () {
    final x = ListHash(<int>[2, 1, 3]);
    final y = ListHash(<int>[1, 3, 2]);
    expect(x, y);

    final a = ListHash(<int>[0]);
    final b = ListHash(<int>[0], true);
    expect(a, b);
  });

  test('add and remove', () {
    final x = ListHash(<int>[2, 1, 3, 4]);
    final y = ListHash(<int>[1, 3, 2]);
    expect(x, isNot(y));

    x.removeLast();
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
    expect(y.containIndices(x), [1, 2, 3]);
    expect(x.contains(y), false);
    expect(x.containIndices(y), []);
    expect(y.contains(z), true);
    expect(y.containIndices(z), [1, 2, 4, 6]);
    expect(z.contains(w), false);
    expect(z.containIndices(w), []);
    expect(w.contains(z), false);
    expect(w.containIndices(z), []);
  });
}
