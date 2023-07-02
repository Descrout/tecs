class BitHash {
  int _value;

  BitHash([int value = 0]) : _value = value;

  factory BitHash.fromIterable([Iterable<int> arr = const <int>[]]) =>
      BitHash(arr.fold(0, (previousValue, element) => previousValue | element));

  int get value => _value;

  void add(int e) => _value |= e;

  void addAll(Iterable<int> arr) =>
      _value = arr.fold(_value, (previousValue, element) => previousValue | element);

  bool remove(int e) {
    if (_value & e != e) return false;
    _value ^= e;
    return true;
  }

  bool removeAll(Iterable<int> arr) {
    bool removedAny = false;
    for (final e in arr) {
      removedAny = remove(e) || removedAny;
    }
    return removedAny;
  }

  bool contains(BitHash other) => _value & other.value == other.value;

  BitHash copy() => BitHash(_value);

  @override
  bool operator ==(covariant BitHash other) => hashCode == other.hashCode;

  @override
  int get hashCode => _value;

  @override
  String toString() => 'BitHash($_value)';
}
