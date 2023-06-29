class ListHash {
  int _value;

  ListHash([int value = 0]) : _value = value;

  factory ListHash.fromIterable([Iterable<int> arr = const <int>[]]) =>
      ListHash(arr.fold(0, (previousValue, element) => previousValue | element));

  int get value => _value;

  void add(int e) {
    _value |= e;
  }

  bool remove(int e) {
    if (_value & e != e) return false;
    _value ^= e;
    return true;
  }

  bool contains(ListHash other) {
    return _value & other.value == other.value;
  }

  ListHash copy() => ListHash(_value);

  @override
  bool operator ==(covariant ListHash other) => hashCode == other.hashCode;

  @override
  int get hashCode => _value;

  @override
  String toString() => 'ListHash($_value)';
}
