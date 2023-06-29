class BitHash {
  int _value;

  BitHash([int value = 0]) : _value = value;

  factory BitHash.fromIterable([Iterable<int> arr = const <int>[]]) =>
      BitHash(arr.fold(0, (previousValue, element) => previousValue | element));

  int get value => _value;

  void add(int e) => _value |= e;

  bool remove(int e) {
    if (_value & e != e) return false;
    _value ^= e;
    return true;
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

/*
//TODO: change componentID going by * 2
//TODO: create a archetypeCounter and increase in _getOrCreateArchetype
//TODO: add id to archetype class
//TODO: change _componentIndex to <ComponentID, Map<ArchetypeID, int>>
import 'dart:collection';

class SetHash {
  final Set<int> _set;
  SetHash([Iterable<int> arr = const <int>[]]) : _set = arr.toSet();

  UnmodifiableSetView<int> get set => UnmodifiableSetView(_set);

  void add(int e) => _set.add(e);

  bool remove(int id) => _set.remove(id);

  bool contains(SetHash other) {
    return _set.containsAll(other._set);
  }

  SetHash copy() => SetHash(_set.toList());

  @override
  bool operator ==(covariant SetHash other) => hashCode == other.hashCode;

  @override
  int get hashCode => Object.hashAllUnordered(_set);

  @override
  String toString() => 'SetHash($_set)';
}
*/