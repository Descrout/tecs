import 'dart:collection';

class SetHash {
  final Set<int> _set;
  int? _cachedHashCode;

  SetHash([Iterable<int> arr = const <int>[]]) : _set = arr.toSet();

  UnmodifiableSetView<int> get set => UnmodifiableSetView(_set);

  void add(int e) {
    if (_set.add(e)) {
      _cachedHashCode = null;
    }
  }

  void addAll(Iterable<int> arr) {
    final oldLength = _set.length;
    _set.addAll(arr);
    if (_set.length != oldLength) {
      _cachedHashCode = null;
    }
  }

  bool removeAll(Iterable<int> arr) {
    final oldLength = _set.length;
    _set.removeAll(arr);
    final removedAny = _set.length != oldLength;
    if (removedAny) {
      _cachedHashCode = null;
    }
    return removedAny;
  }

  bool remove(int id) {
    final removed = _set.remove(id);
    if (removed) {
      _cachedHashCode = null;
    }
    return removed;
  }

  bool contains(SetHash other) => _set.containsAll(other._set);

  bool get isEmpty => _set.isEmpty;

  SetHash copy() => SetHash(_set);

  @override
  bool operator ==(covariant SetHash other) {
    if (identical(this, other)) return true;
    if (_set.length != other._set.length) return false;
    if (hashCode != other.hashCode) return false;
    return _set.containsAll(other._set);
  }

  @override
  int get hashCode {
    if (_cachedHashCode != null) return _cachedHashCode!;
    _cachedHashCode = Object.hashAllUnordered(_set);
    return _cachedHashCode!;
  }
}
