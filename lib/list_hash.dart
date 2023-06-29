import 'dart:collection';

import 'package:flutter/foundation.dart';

class ListHash {
  final List<int> _list;
  ListHash([Iterable<int> arr = const <int>[], bool dontSort = false]) : _list = List.from(arr) {
    if (!dontSort) _list.sort();
  }

  UnmodifiableListView<int> get list => UnmodifiableListView(_list);
  int get length => _list.length;

  void sort() => _list.sort();

  /// Adds an item to list and return the insertion index
  int add(int e) {
    //TODO: binary search insertion (now O(n))
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

  //TODO: binary search remove (now O(n))
  bool remove(int id) => _list.remove(id);

  int removeLast() => _list.removeLast();

  List<int> containIndices(ListHash other) {
    final otherList = other.list;
    final contains = <int>[];
    if (_list.length < otherList.length) return contains;
    int skipOffset = 0;
    for (int i = 0; i < _list.length; i++) {
      final otherIdx = i - skipOffset;
      if (otherIdx > otherList.length - 1) break;
      if (_list[i] == otherList[otherIdx]) {
        contains.add(i);
      } else if (_list[i] > otherList[otherIdx]) {
        if (contains.isNotEmpty) return [];
      } else {
        skipOffset++;
      }
    }
    return other.length != contains.length ? [] : contains;
  }

  bool contains(ListHash other) {
    final otherList = other.list;
    if (_list.length < otherList.length) return false;
    int containedLength = 0;
    int skipOffset = 0;
    for (int i = 0; i < _list.length; i++) {
      final otherIdx = i - skipOffset;
      if (otherIdx > otherList.length - 1) break;
      if (_list[i] < otherList[otherIdx]) {
        skipOffset++;
      } else if (_list[i] > otherList[otherIdx]) {
        if (containedLength != 0) return false;
      } else {
        containedLength++;
      }
    }
    return other.length == containedLength;
  }

  @override
  bool operator ==(covariant ListHash other) {
    if (identical(this, other)) return true;

    return listEquals(other._list, _list);
  }

  @override
  int get hashCode => Object.hashAll(_list);

  ListHash copy() => ListHash(_list, true);

  @override
  String toString() => 'ListHash($_list)';
}
