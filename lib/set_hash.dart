import 'dart:collection';

class SetHash {
  final Set<int> _set;
  SetHash([Iterable<int> arr = const <int>[]]) : _set = arr.toSet();

  UnmodifiableSetView<int> get set => UnmodifiableSetView(_set);

  void add(int e) => _set.add(e);

  void addAll(Iterable<int> arr) => _set.addAll(arr);

  bool removeAll(Iterable<int> arr) {
    bool removedAny = false;
    for (final e in arr) {
      removedAny = remove(e) || removedAny;
    }
    return removedAny;
  }

  bool remove(int id) => _set.remove(id);

  bool contains(SetHash other) => _set.containsAll(other._set);

  bool get isEmpty => _set.isEmpty;

  SetHash copy() => SetHash(_set);

  @override
  bool operator ==(covariant SetHash other) => hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAllUnordered(_set);
}
