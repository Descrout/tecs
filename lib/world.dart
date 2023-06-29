import 'package:tecs/archetype.dart';
import 'package:tecs/list_hash.dart';
import 'package:tecs/tecs.dart';
import 'package:tecs/types.dart';

class World {
  //TODO: more user friendly query
  //TODO: systems
  //TODO: resources
  //TODO: addComponent removeComponent graph cache ?
  //TODO: listhash to binary operation or set ?
  //TODO: faster query method ?

  final _archetypeIndex = <ListHash, Archetype>{};
  final _entityIndex = <EntityID, Record?>{};
  final _componentIndex = <ComponentID, Map<ArchetypeID, int>>{};

  final _componentTypes = <Type, ComponentID>{};

  final _listHashSortCache = <ListHash, ListHash>{};

  int _componentCounter = 0;
  int _entityCounter = 0;
  int _archetypeCounter = 0;

  int get archetypeCount => _archetypeIndex.length;
  int get entityCount => _entityIndex.length;
  int get componentTypesCount => _componentTypes.length;

  void clear() {
    _componentTypes.clear();
    _componentIndex.clear();
    _entityIndex.clear();
    _archetypeIndex.clear();
    _componentCounter = 0;
    _entityCounter = 0;
    _archetypeCounter = 0;
  }

  T? getComponent<T extends Component>(EntityID entityID) {
    final componentID = _componentTypes[T];
    final record = _entityIndex[entityID];
    if (record == null) return null;
    final archetype = record.archetype;
    final archetypes = _componentIndex[componentID];
    final componentRow = archetypes?[archetype.id];
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

  ListHash _getOrCreateListHash(ListHash unsorted) {
    final sorted = _listHashSortCache[unsorted];
    if (sorted != null) return sorted;
    return unsorted.copy()..sort();
  }

  ComponentID _getOrCreateComponentID(Type type) {
    final id = _componentTypes[type];
    if (id != null) return id;
    _componentTypes[type] = _componentCounter++;
    return _componentCounter - 1;
  }

  Archetype _getOrCreateArchetype(ListHash listHash) {
    Archetype? archetype = _archetypeIndex[listHash];
    if (archetype != null) return archetype;
    final archetypeID = _archetypeCounter++;
    archetype = Archetype(
      id: archetypeID,
      listHash: listHash,
      components: [],
    );

    _archetypeIndex[listHash] = archetype;
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
      if (_componentIndex[componentID]![toArchetype.id] == null) {
        _componentIndex[componentID]![toArchetype.id] = toArchetype.components.length;
        toArchetype.components.add([]);
      }

      final componentsList = toArchetype.components[_componentIndex[componentID]![toArchetype.id]!];
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
      final listHash = ListHash([componentID], true);
      final archetype = _getOrCreateArchetype(listHash);
      if (_componentIndex[componentID]![archetype.id] == null) {
        _componentIndex[componentID]![archetype.id] = archetype.components.length;
        archetype.components.add([]);
      }

      final componentsList = archetype.components[_componentIndex[componentID]![archetype.id]!];
      _entityIndex[entityID] = Record(archetype: archetype, entityRow: componentsList.length);
      componentsList.add(component);
    } else {
      final oldArchetype = record.archetype;
      final listHash = oldArchetype.listHash.copy();
      listHash.add(componentID);
      final archetype = _getOrCreateArchetype(listHash);
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
    final listHash = oldArchetype.listHash.copy();
    if (!listHash.remove(componentID)) return;

    if (listHash.length == 0) {
      _removeEntityFromArchetype(entityID, oldArchetype, record.entityRow);
    } else {
      final archetype = _getOrCreateArchetype(listHash);
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
    final unsortedListHash = ListHash(types.map((e) => _getOrCreateComponentID(e)), true);
    final listHash = _getOrCreateListHash(unsortedListHash);
    final queryRows = <List<Component>>[];
    for (final kv in _archetypeIndex.entries) {
      if (kv.value.isEmpty) continue;
      if (kv.key.contains(listHash)) {
        for (int i = 0; i < kv.value.entityCount; i++) {
          final componentsOfEntity = <Component>[];
          for (final componentID in unsortedListHash.list) {
            componentsOfEntity
                .add(kv.value.components[_componentIndex[componentID]![kv.value.id]!][i]);
          }
          queryRows.add(componentsOfEntity);
        }
      }
    }
    return queryRows;
  }

  // Iterable<List<Component>> queryRawSorted(Iterable<Type> types) {
  //   final unsortedListHash = ListHash(types.map((e) => _getOrCreateComponentID(e)), true);
  //   final listHash = _getOrCreateListHash(unsortedListHash);
  //   final queryRows = <List<Component>>[];
  //   for (final kv in _archetypeIndex.entries) {
  //     if (kv.value.isEmpty) continue;
  //     final indices = kv.key.containIndices(listHash);
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
