import 'dart:collection';

class ListHash {
  final Set<int> _set;
  ListHash([Iterable<int> arr = const <int>[]]) : _set = arr.toSet();

  UnmodifiableSetView<int> get set => UnmodifiableSetView(_set);

  int get length => _set.length;

  void add(int e) {
    _set.add(e);
  }

  bool remove(int id) => _set.remove(id);

  bool contains(ListHash other) {
    return _set.containsAll(other._set);
  }

  ListHash copy() => ListHash(_set.toList());

  @override
  bool operator ==(covariant ListHash other) => hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAllUnordered(_set);

  @override
  String toString() => 'ListHash($_set)';
}
