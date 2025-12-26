import 'package:tecs/component.dart';
import 'package:tecs/set_hash.dart';
import 'package:tecs/types.dart';
import 'package:tecs/world.dart';

class QueryRow {
  final Map<Type, Component> _components;
  QueryRow(List<Component> components)
      : _components = {for (final e in components) e.runtimeType: e},
        entity = components.first.entityID;

  final EntityID entity;

  T get<T extends Component>() => _components[T]! as T;
}

class QueryParams {
  final List<Type> types;

  SetHash? _setHash;
  List<int>? _componentIDs;
  int _resolvedWorldVersion = -1;

  SetHash get hash => _setHash!;
  List<int> get componentIDs => _componentIDs!;

  QueryParams(this.types);

  bool activate(World world) {
    if (_resolvedWorldVersion == world.version && _setHash != null) {
      return true;
    }

    final ids = <int>[];
    for (final t in types) {
      final id = world.getComponentID(t);
      if (id == null) {
        _setHash = null;
        _componentIDs = null;
        return false;
      }
      ids.add(id);
    }

    _componentIDs = ids;
    _setHash = SetHash(ids);
    _resolvedWorldVersion = world.version;
    return true;
  }
}
