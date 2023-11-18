import 'package:tecs/archetype.dart';
import 'package:tecs/set_hash.dart';
import 'package:tecs/tecs.dart';

class World {
  final _archetypeIndex = <SetHash, Archetype>{};
  final _entityIndex = <EntityID, Record?>{};
  final _componentIndex = <ComponentID, Map<SetHash, int>>{};

  final _componentTypes = <Type, ComponentID>{};

  final _resources = <String, dynamic>{};

  final _systems = <String, List<System>>{};

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
    _resources.clear();
    _systems.clear();
    _componentCounter = 2;
    _entityCounter = 0;
  }

  T? getComponent<T extends Component>(EntityID entityID) {
    final componentID = _componentTypes[T];
    final record = _entityIndex[entityID];
    if (record == null) return null;
    final archetype = record.archetype;
    final archetypes = _componentIndex[componentID];
    final componentRow = archetypes?[archetype.setHash];
    if (componentRow == null) return null;
    return archetype.components[componentRow][record.entityRow] as T?;
  }

  void addSystem(System system, {String tag = ""}) {
    system.world = this;
    system.tag = tag;
    _systems[tag] ??= <System>[];
    _systems[tag]!.add(system);
  }

  void update<T>(T args, {String tag = ""}) {
    final systems = _systems[tag];
    if (systems == null) return;
    for (final system in systems) {
      system.update(args);
    }
  }

  T addResource<T>(T resource, {String tag = ""}) {
    return _resources[T.toString() + tag] = resource;
  }

  T? getResource<T>({String tag = ""}) {
    return _resources[T.toString() + tag] as T?;
  }

  T? removeResource<T>({String tag = ""}) {
    return _resources.remove(T.toString() + tag) as T?;
  }

  EntityID createEntity() {
    final entityID = _entityCounter++;
    _entityIndex[entityID] = null;
    return entityID;
  }

  bool removeEntity(EntityID entityID) {
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

  Archetype _getOrCreateArchetype(SetHash setHash) {
    Archetype? archetype = _archetypeIndex[setHash];
    if (archetype != null) return archetype;
    archetype = Archetype(
      setHash: setHash,
      components: [],
    );

    _archetypeIndex[setHash] = archetype;
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
    List<Component> toAdd = const [],
    Set<ComponentID> toRemove = const {},
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
      if (!toRemove.contains(_componentTypes[removed.runtimeType])) {
        removedComps.add(removed);
      }
    }
    removedComps.addAll(toAdd);
    int newEntityRow = -1;
    for (final compToAdd in removedComps) {
      final componentID = _componentTypes[compToAdd.runtimeType]!;
      _componentIndex[componentID] ??= {};
      if (_componentIndex[componentID]![toArchetype.setHash] == null) {
        _componentIndex[componentID]![toArchetype.setHash] = toArchetype.components.length;
        toArchetype.components.add([]);
      }

      final componentsList =
          toArchetype.components[_componentIndex[componentID]![toArchetype.setHash]!];
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
      final bitHash = SetHash({componentID});
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
      final bitHash = oldArchetype.setHash.copy();
      bitHash.add(componentID);
      final archetype = _getOrCreateArchetype(bitHash);
      _moveEntity(
        entityID,
        oldArchetype,
        record.entityRow,
        archetype,
        toAdd: [component],
      );
    }
  }

  void addComponents(EntityID entityID, {required List<Component> components}) {
    final componentIDs = <ComponentID>[];

    for (final component in components) {
      component.entityID = entityID;
      final componentID = _getOrCreateComponentID(component.runtimeType);
      componentIDs.add(componentID);
      _componentIndex[componentID] ??= {};
    }

    final record = _entityIndex.remove(entityID);
    if (record == null) {
      final bitHash = SetHash(componentIDs);
      final archetype = _getOrCreateArchetype(bitHash);

      for (int i = 0; i < components.length; i++) {
        final componentID = componentIDs.elementAt(i);
        final component = components[i];

        if (_componentIndex[componentID]![bitHash] == null) {
          _componentIndex[componentID]![bitHash] = archetype.components.length;
          archetype.components.add([]);
        }
        final componentsList = archetype.components[_componentIndex[componentID]![bitHash]!];
        componentsList.add(component);
      }

      _entityIndex[entityID] = Record(
        archetype: archetype,
        entityRow: archetype.components[0].length - 1,
      );
    } else {
      final oldArchetype = record.archetype;
      final bitHash = oldArchetype.setHash.copy()..addAll(componentIDs);
      final archetype = _getOrCreateArchetype(bitHash);
      _moveEntity(
        entityID,
        oldArchetype,
        record.entityRow,
        archetype,
        toAdd: components,
      );
    }
  }

  void removeComponent<T extends Component>(EntityID entityID) {
    final record = _entityIndex[entityID];
    if (record == null) return;

    final componentID = _getOrCreateComponentID(T);
    final oldArchetype = record.archetype;
    final setHash = oldArchetype.setHash.copy();
    if (!setHash.remove(componentID)) return;

    if (setHash.isEmpty) {
      _removeEntityFromArchetype(entityID, oldArchetype, record.entityRow);
    } else {
      final archetype = _getOrCreateArchetype(setHash);
      _moveEntity(
        entityID,
        oldArchetype,
        record.entityRow,
        archetype,
        toRemove: {componentID},
      );
    }
  }

  void removeComponents(EntityID entityID, {required List<Type> components}) {
    final record = _entityIndex[entityID];
    if (record == null) return;

    final componentIDs = components.map((e) => _getOrCreateComponentID(e)).toSet();
    final oldArchetype = record.archetype;
    final setHash = oldArchetype.setHash.copy();
    if (!setHash.removeAll(componentIDs)) return;
    if (setHash.isEmpty) {
      _removeEntityFromArchetype(entityID, oldArchetype, record.entityRow);
    } else {
      final archetype = _getOrCreateArchetype(setHash);
      _moveEntity(
        entityID,
        oldArchetype,
        record.entityRow,
        archetype,
        toRemove: componentIDs,
      );
    }
  }

  Iterable<List<Component>> queryRaw(Iterable<Type> types) {
    final ids = types.map((e) => _getOrCreateComponentID(e));
    final bitHash = SetHash(ids);
    final queryRows = <List<Component>>[];
    for (final kv in _archetypeIndex.entries) {
      if (kv.value.isEmpty) continue;
      if (kv.key.contains(bitHash)) {
        for (int i = 0; i < kv.value.entityCount; i++) {
          final componentsOfEntity = <Component>[];
          for (final componentID in ids) {
            componentsOfEntity
                .add(kv.value.components[_componentIndex[componentID]![kv.value.setHash]!][i]);
          }
          queryRows.add(componentsOfEntity);
        }
      }
    }
    return queryRows;
  }

  Query query(Iterable<Type> types) => Query(rows: queryRaw(types).map((e) => QueryRow(e)));
}
