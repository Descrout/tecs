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

  test('empty set operations', () {
    final empty1 = SetHash();
    final empty2 = SetHash([]);

    expect(empty1, empty2);
    expect(empty1.isEmpty, true);
    expect(empty1.hashCode, empty2.hashCode);

    empty1.add(5);
    expect(empty1.isEmpty, false);
    expect(empty1, isNot(empty2));
  });

  test('hash code caching - same hash after multiple calls', () {
    final x = SetHash([1, 2, 3]);
    final hash1 = x.hashCode;
    final hash2 = x.hashCode;
    final hash3 = x.hashCode;

    expect(hash1, hash2);
    expect(hash2, hash3);
  });

  test('hash code invalidation after modification', () {
    final x = SetHash([1, 2, 3]);
    final originalHash = x.hashCode;

    x.add(4);
    expect(x.hashCode, isNot(originalHash));

    final afterAddHash = x.hashCode;
    x.remove(4);
    expect(x.hashCode, originalHash);
    expect(x.hashCode, isNot(afterAddHash));
  });

  test('hash code not invalidated when no change occurs', () {
    final x = SetHash([1, 2, 3]);
    final originalHash = x.hashCode;

    x.add(2);
    expect(x.hashCode, originalHash);

    x.remove(999);
    expect(x.hashCode, originalHash);
  });

  test('removeAll returns correct boolean', () {
    final x = SetHash([1, 2, 3, 4]);

    expect(x.removeAll([2, 3, 999]), true);
    expect(x.set, {1, 4});

    expect(x.removeAll([999, 888]), false);
    expect(x.set, {1, 4});

    expect(x.removeAll([1, 4]), true);
    expect(x.isEmpty, true);
  });

  test('remove returns correct boolean', () {
    final x = SetHash([1, 2, 3]);

    expect(x.remove(2), true);
    expect(x.remove(2), false);
    expect(x.remove(999), false);
  });

  test('addAll with empty iterable', () {
    final x = SetHash([1, 2, 3]);
    final originalHash = x.hashCode;

    x.addAll([]);
    expect(x.set, {1, 2, 3});
    expect(x.hashCode, originalHash);
  });

  test('addAll with duplicates', () {
    final x = SetHash([1, 2]);
    final originalHash = x.hashCode;

    x.addAll([1, 2, 1, 2]);
    expect(x.set, {1, 2});
    expect(x.hashCode, originalHash);

    x.addAll([2, 3, 1, 4]);
    expect(x.set, {1, 2, 3, 4});
    expect(x.hashCode, isNot(originalHash));
  });

  test('equality operator edge cases', () {
    final x = SetHash([1, 2, 3]);

    expect(x == x, true);

    final empty1 = SetHash();
    final empty2 = SetHash();
    expect(empty1, empty2);

    final small = SetHash([1]);
    final large = SetHash([1, 2, 3, 4, 5]);
    expect(small, isNot(large));
  });

  test('contains with empty sets', () {
    final x = SetHash([1, 2, 3]);
    final empty = SetHash();

    expect(x.contains(empty), true);

    expect(empty.contains(empty), true);
    expect(empty.contains(x), false);
  });

  test('contains with identical sets', () {
    final x = SetHash([1, 2, 3]);
    final y = SetHash([1, 2, 3]);

    expect(x.contains(y), true);
    expect(y.contains(x), true);
  });

  test('copy independence', () {
    final x = SetHash([1, 2, 3]);
    final y = x.copy();

    expect(x, y);

    x.add(4);
    expect(x, isNot(y));
    expect(y.set, {1, 2, 3});

    y.remove(1);
    expect(x.set, {1, 2, 3, 4});
    expect(y.set, {2, 3});
  });

  test('set getter is unmodifiable', () {
    final x = SetHash([1, 2, 3]);
    final view = x.set;

    expect(() => (view as Set<int>).add(4), throwsUnsupportedError);
  });

  test('large set performance', () {
    final large = SetHash(List.generate(10000, (i) => i));

    final hash1 = large.hashCode;
    final hash2 = large.hashCode;
    final hash3 = large.hashCode;

    expect(hash1, hash2);
    expect(hash2, hash3);
  });

  test('hash collision scenario', () {
    final x = SetHash([1, 2, 3]);
    final y = SetHash([4, 5, 6]);

    if (x.hashCode == y.hashCode) {
      expect(x, isNot(y));
    }
  });

  test('single element operations', () {
    final x = SetHash([42]);

    expect(x.isEmpty, false);
    expect(x.hashCode, isNot(0));

    x.remove(42);
    expect(x.isEmpty, true);

    x.add(42);
    expect(x.isEmpty, false);
  });
}
