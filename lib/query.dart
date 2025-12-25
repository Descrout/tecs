import 'package:tecs/component.dart';
import 'package:tecs/set_hash.dart';
import 'package:tecs/types.dart';

class QueryRow {
  final Map<Type, Component> _components;
  QueryRow(List<Component> components)
      : _components = {for (final e in components) e.runtimeType: e},
        entity = components.first.entityID;

  final EntityID entity;

  T get<T extends Component>() => _components[T]! as T;
}

class QueryParams {
  final List<Type> _components;

  SetHash? _hash;
  final List<int> _ids = [];

  QueryParams(
    this._components,
  );

  SetHash get hash => _hash!;
  List<int> get ids => _ids;

  bool get isActivated => _hash != null;

  bool activate(Map<Type, int> types) {
    if (isActivated) return true;

    for (final t in _components) {
      final id = types[t];
      if (id == null) {
        _ids.clear();
        return false;
      }
      _ids.add(id);
    }

    _hash = SetHash(_ids);

    return true;
  }
}
