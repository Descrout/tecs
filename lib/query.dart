import 'package:tecs/component.dart';
import 'package:tecs/set_hash.dart';
import 'package:tecs/types.dart';
import 'package:tecs/world.dart';

class QueryRow {
  final EntityID entity;
  final Map<Type, int> _typeIndices;
  final List<Component> _componentsBuffer;
  final int _offset;

  QueryRow(this._componentsBuffer, this._offset, this._typeIndices)
      : entity = _componentsBuffer[_offset].entityID;

  @pragma('vm:prefer-inline')
  T get<T extends Component>() {
    return _componentsBuffer[_offset + _typeIndices[T]!] as T;
  }
}

class QueryParams {
  final List<Type> types;
  final Map<Type, int> typeIndices;
  SetHash? _setHash;
  List<int>? _componentIDs;
  int _resolvedWorldVersion = -1;

  // TODO: Bring these back after thinking about commandBuffer
  //int _resolvedArchetypeCount = -1;
  //List<Archetype>? _cachedArchetypes;

  SetHash get hash => _setHash!;
  List<int> get componentIDs => _componentIDs!;
  //List<Archetype> get cachedArchetypes => _cachedArchetypes!;

  QueryParams(this.types) : typeIndices = {for (int i = 0; i < types.length; i++) types[i]: i};

  bool get isActivated => _setHash != null;

  bool activate(World world) {
    if (_resolvedWorldVersion == world.version &&
        // _resolvedArchetypeCount == world.archetypeCount &&
        _setHash != null) {
      return true;
    }

    _componentIDs ??= List<int>.filled(types.length, 0);
    for (int i = 0; i < types.length; i++) {
      final id = world.getComponentID(types[i]);
      if (id == null) {
        _setHash = null;
        _resolvedWorldVersion = -1;
        //_cachedArchetypes = null;
        //_resolvedArchetypeCount = -1;
        return false;
      }
      _componentIDs![i] = id;
    }

    _setHash = SetHash(_componentIDs!);

    //_cachedArchetypes = world.findMatchingArchetypes(_setHash!);
    //_resolvedArchetypeCount = world.archetypeCount;

    _resolvedWorldVersion = world.version;
    return true;
  }
}
