import 'package:tecs/archetype.dart';
import 'package:tecs/bit_hash.dart';
import 'package:tecs/query.dart';
import 'package:tecs/tecs.dart';
import 'package:tecs/types.dart';

class World {
  //TODO: systems
  //TODO: resources
  //TODO: addComponent removeComponent graph cache ?
  //TODO: faster query method ?

  final _archetypeIndex = <BitHash, Archetype>{};
  final _entityIndex = <EntityID, Record?>{};
  final _componentIndex = <ComponentID, Map<BitHash, int>>{};

  final _componentTypes = <Type, ComponentID>{};

  int _componentCounter = 2;
  int _entityCounter = 0;

  int get archetypeCount => _archetypeIndex.length;
  int get entityCount => _entityIndex.length;
  int get componentTypesCount => _componentTypes.length;

  void clear() {
    _componentTypes.clear();
    _componentIndex.clear();
    _entityIndex.clear();
    _archetypeIndex.clear();
    _componentCounter = 2;
    _entityCounter = 0;
  }

  T? getComponent<T extends Component>(EntityID entityID) {
    final componentID = _componentTypes[T];
    final record = _entityIndex[entityID];
    if (record == null) return null;
    final archetype = record.archetype;
    final archetypes = _componentIndex[componentID];
    final componentRow = archetypes?[archetype.bitHash];
    if (componentRow == null) return null;
    return archetype.components[componentRow][record.entityRow] as T?;
  }

  EntityID createEntity() {
    final entityID = _entityCounter++;
    _entityIndex[entityID] = null;
    return entityID;
  }

  bool deleteEntity(EntityID entityID) {
    if (!isAlive(entityID)) return false;
    final record = _entityIndex[entityID];
    _removeEntityFromArchetype(entityID, record!.archetype, record.entityRow);
    return true;
  }

  bool isAlive(EntityID entityID) => _entityIndex.containsKey(entityID);

  ComponentID _getOrCreateComponentID(Type type) {
    final id = _componentTypes[type];
    if (id != null) return id;
    _componentTypes[type] = _componentCounter;
    _componentCounter *= 2;
    return _componentTypes[type]!;
  }

  Archetype _getOrCreateArchetype(BitHash bitHash) {
    Archetype? archetype = _archetypeIndex[bitHash];
    if (archetype != null) return archetype;
    archetype = Archetype(
      bitHash: bitHash,
      components: [],
    );

    _archetypeIndex[bitHash] = archetype;
    return archetype;
  }

  void _removeEntityFromArchetype(
    EntityID entityID,
    Archetype fromArchetype,
    int entityRow,
  ) {
    bool recordsFixed = false;
    for (final compsOfEntity in fromArchetype.components) {
      if (!recordsFixed) {
        recordsFixed = true;
        final compsAfter = compsOfEntity.sublist(entityRow + 1);
        for (final compToDecrease in compsAfter) {
          if (compToDecrease.entityID != -1) _entityIndex[compToDecrease.entityID]?.entityRow -= 1;
        }
      }
      compsOfEntity.removeAt(entityRow);
    }

    _entityIndex.remove(entityID);
  }

  void _moveEntity(
    EntityID entityID,
    Archetype fromArchetype,
    int entityRow,
    Archetype toArchetype, {
    Component? toAdd,
    ComponentID? toRemove,
  }) {
    bool recordsFixed = false;
    final removedComps = <Component>[];
    for (final compsOfEntity in fromArchetype.components) {
      if (!recordsFixed) {
        recordsFixed = true;
        final compsAfter = compsOfEntity.sublist(entityRow + 1);
        for (final compToDecrease in compsAfter) {
          if (compToDecrease.entityID != -1) _entityIndex[compToDecrease.entityID]?.entityRow -= 1;
        }
      }
      final removed = compsOfEntity.removeAt(entityRow);
      if (toRemove == null || _componentTypes[removed.runtimeType] != toRemove) {
        removedComps.add(removed);
      }
    }
    if (toAdd != null) removedComps.add(toAdd);
    int newEntityRow = -1;
    for (final compToAdd in removedComps) {
      final componentID = _componentTypes[compToAdd.runtimeType]!;
      _componentIndex[componentID] ??= {};
      if (_componentIndex[componentID]![toArchetype.bitHash] == null) {
        _componentIndex[componentID]![toArchetype.bitHash] = toArchetype.components.length;
        toArchetype.components.add([]);
      }

      final componentsList =
          toArchetype.components[_componentIndex[componentID]![toArchetype.bitHash]!];
      if (newEntityRow == -1) newEntityRow = componentsList.length;
      componentsList.add(compToAdd);
    }

    _entityIndex[entityID] = Record(archetype: toArchetype, entityRow: newEntityRow);
  }

  void addComponent<T extends Component>(EntityID entityID, T component) {
    component.entityID = entityID;
    final componentID = _getOrCreateComponentID(T);
    _componentIndex[componentID] ??= {};

    final record = _entityIndex.remove(entityID);
    if (record == null) {
      final bitHash = BitHash(componentID);
      final archetype = _getOrCreateArchetype(bitHash);
      if (_componentIndex[componentID]![bitHash] == null) {
        _componentIndex[componentID]![bitHash] = archetype.components.length;
        archetype.components.add([]);
      }

      final componentsList = archetype.components[_componentIndex[componentID]![bitHash]!];
      _entityIndex[entityID] = Record(archetype: archetype, entityRow: componentsList.length);
      componentsList.add(component);
    } else {
      final oldArchetype = record.archetype;
      final bitHash = oldArchetype.bitHash.copy();
      bitHash.add(componentID);
      final archetype = _getOrCreateArchetype(bitHash);
      _moveEntity(
        entityID,
        oldArchetype,
        record.entityRow,
        archetype,
        toAdd: component,
      );
    }
  }

  void removeComponent<T extends Component>(EntityID entityID) {
    final record = _entityIndex[entityID];
    if (record == null) return;

    final componentID = _getOrCreateComponentID(T);
    final oldArchetype = record.archetype;
    final bitHash = oldArchetype.bitHash.copy();
    if (!bitHash.remove(componentID)) return;

    if (bitHash.value == 0) {
      _removeEntityFromArchetype(entityID, oldArchetype, record.entityRow);
    } else {
      final archetype = _getOrCreateArchetype(bitHash);
      _moveEntity(
        entityID,
        oldArchetype,
        record.entityRow,
        archetype,
        toRemove: componentID,
      );
    }
  }

  Iterable<List<Component>> queryRaw(Iterable<Type> types) {
    final ids = types.map((e) => _getOrCreateComponentID(e));
    final bitHash = BitHash.fromIterable(ids);
    final queryRows = <List<Component>>[];
    for (final kv in _archetypeIndex.entries) {
      if (kv.value.isEmpty) continue;
      if (kv.key.contains(bitHash)) {
        for (int i = 0; i < kv.value.entityCount; i++) {
          final componentsOfEntity = <Component>[];
          for (final componentID in ids) {
            componentsOfEntity
                .add(kv.value.components[_componentIndex[componentID]![kv.value.bitHash]!][i]);
          }
          queryRows.add(componentsOfEntity);
        }
      }
    }
    return queryRows;
  }

  Query query(Iterable<Type> types) => Query(rows: queryRaw(types).map((e) => QueryRow(e)));

  // Iterable<List<Component>> queryRawSorted(Iterable<Type> types) {
  //   final unsortedbitHash = bitHash(types.map((e) => _getOrCreateComponentID(e)), true);
  //   final bitHash = _getOrCreatebitHash(unsortedbitHash);
  //   final queryRows = <List<Component>>[];
  //   for (final kv in _archetypeIndex.entries) {
  //     if (kv.value.isEmpty) continue;
  //     final indices = kv.key.containIndices(bitHash);
  //     if (indices.isNotEmpty) {
  //       for (int i = 0; i < kv.value.entityCount; i++) {
  //         final componentsOfEntity = <Component>[];
  //         for (final componentIdx in indices) {
  //           componentsOfEntity.add(kv.value.components[componentIdx][i]);
  //         }
  //         queryRows.add(componentsOfEntity);
  //       }
  //     }
  //   }
  //   return queryRows;
  // }
}
