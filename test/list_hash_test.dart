import 'package:flutter_test/flutter_test.dart';
import 'package:tecs/list_hash.dart';

void main() {
  test('init sort working', () {
    final x = ListHash(<int>[2, 1, 3]);

    for (int i = 0; i < x.length; i++) {
      expect(x.list[i], i + 1);
    }
  });

  test('equality check should work', () {
    final x = ListHash(<int>[2, 1, 3]);
    final y = ListHash(<int>[1, 3, 2]);
    expect(x == y, true);
  });

  test('add and remove should work', () {
    final x = ListHash(<int>[2, 1, 3, 4]);
    final y = ListHash(<int>[1, 3, 2]);
    expect(x == y, false);

    x.removeLast();
    expect(x == y, true);

    y.add(5);
    expect(x == y, false);

    x.add(5);
    expect(x == y, true);
  });
}
