import 'package:flutter_test/flutter_test.dart';
import 'package:tecs/bit_hash.dart';

void main() {
  test('equality check', () {
    final x = BitHash.fromIterable(<int>[4, 2, 16]);
    final y = BitHash.fromIterable(<int>[2, 16, 4]);
    expect(x, y);

    final a = BitHash.fromIterable(<int>[0]);
    final b = BitHash.fromIterable(<int>[0]);
    expect(a, b);

    final k = BitHash.fromIterable(<int>[0, 2, 4]);
    final m = BitHash.fromIterable(<int>[0, 2, 8]);
    expect(k, isNot(m));
  });

  test('add and remove', () {
    final x = BitHash.fromIterable(<int>[2, 16, 8, 4]);
    final y = BitHash.fromIterable(<int>[16, 8, 2]);
    expect(x, isNot(y));

    x.remove(4);
    expect(x, y);

    y.add(32);
    expect(x, isNot(y));

    x.add(32);
    expect(x, y);
  });

  test('copy must be equal to itself', () {
    final x = BitHash.fromIterable(<int>[4, 2, 8]);
    final y = x.copy();
    expect(x, y);
  });

  test('containIndices', () {
    final x = BitHash.fromIterable(<int>[8, 4, 16]);
    final y = BitHash.fromIterable(<int>[2, 4, 16, 8, 32, 128, 64]);
    final z = BitHash.fromIterable(<int>[4, 128, 32, 8]);
    final w = BitHash.fromIterable(<int>[4, 32, 64, 8]);

    expect(y.contains(x), true);
    expect(x.contains(y), false);
    expect(y.contains(z), true);
    expect(z.contains(w), false);
    expect(w.contains(z), false);
  });
}
