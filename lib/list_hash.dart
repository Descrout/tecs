import 'dart:collection';

import 'package:flutter/foundation.dart';

class ListHash {
  final List<int> _list;
  ListHash([List<int> arr = const <int>[], bool dontSort = false]) : _list = List.from(arr) {
    if (!dontSort) _list.sort();
  }

  UnmodifiableListView<int> get list => UnmodifiableListView(_list);
  int get length => list.length;

  /// Adds an item to list and return the insertion index
  int add(int e) {
    //TODO: binary search insertion
    for (int i = 0; i < _list.length; i++) {
      if (e < _list[i]) {
        _list.insert(i, e);
        return i;
      }
    }

    _list.add(e);
    return _list.length - 1;
  }

  int removeAt(int index) => _list.removeAt(index);
  int removeLast() => _list.removeLast();

  @override
  bool operator ==(covariant ListHash other) {
    if (identical(this, other)) return true;

    return listEquals(other._list, _list);
  }

  @override
  int get hashCode => _list.hashCode;

  ListHash copy() => ListHash(_list, true);
}
