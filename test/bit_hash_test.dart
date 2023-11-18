import 'package:tecs/set_hash.dart';
import 'package:test/test.dart';

void main() {
  test('equality check', () {
    final x = SetHash(<int>[4, 2, 16]);
    final y = SetHash(<int>[2, 16, 4]);
    expect(x, y);

    final a = SetHash(<int>[0]);
    final b = SetHash(<int>[0]);
    expect(a, b);

    final k = SetHash(<int>[0, 2, 4]);
    final m = SetHash(<int>[0, 2, 8]);
    expect(k, isNot(m));
  });

  test('add and remove', () {
    final x = SetHash(<int>[2, 16, 8, 4]);
    final y = SetHash(<int>[16, 8, 2]);
    expect(x, isNot(y));

    x.remove(4);
    expect(x, y);

    y.add(32);
    expect(x, isNot(y));

    x.add(32);
    expect(x, y);
  });

  test('addAll and removeAll', () {
    final x = SetHash(<int>[2, 16, 8, 4, 32]);
    final y = SetHash(<int>[16, 8, 2]);
    expect(x, isNot(y));

    x.removeAll([4, 32]);
    expect(x, y);

    y.addAll([32, 4]);
    expect(x, isNot(y));

    x.add(32);
    x.addAll([4]);
    expect(x, y);
  });

  test('copy must be equal to itself', () {
    final x = SetHash(<int>[4, 2, 8]);
    final y = x.copy();
    expect(x, y);
  });

  test('containIndices', () {
    final x = SetHash(<int>[8, 4, 16]);
    final y = SetHash(<int>[2, 4, 16, 8, 32, 128, 64]);
    final z = SetHash(<int>[4, 128, 32, 8]);
    final w = SetHash(<int>[4, 32, 64, 8]);

    expect(y.contains(x), true);
    expect(x.contains(y), false);
    expect(y.contains(z), true);
    expect(z.contains(w), false);
    expect(w.contains(z), false);
  });
}
