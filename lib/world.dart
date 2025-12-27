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

  int _componentCounter = 0;
  int _entityCounter = 0;
  int _version = 0;

  int get version => _version;
  int get archetypeCount => _archetypeIndex.length;
  int get entityCount => _entityIndex.length;
  int get componentTypesCount => _componentTypes.length;

  final CommandBuffer commands = CommandBuffer();

  void flushCommands() => commands.flush(this);

  void clearEntities() {
    commands.clear();
    _componentTypes.clear();
    _componentIndex.clear();
    _entityIndex.clear();
    _archetypeIndex.clear();
    _componentCounter = 0;
    _entityCounter = 0;
    _version++;
  }

  void clearResources() => _resources.clear();
  void clearSystems() => _systems.clear();

  void clear() {
    clearSystems();
    clearEntities();
    clearResources();
  }

  ComponentID? componentID<T extends Component>() {
    return _componentTypes[T];
  }

  ComponentID? getComponentID(Type type) {
    return _componentTypes[type];
  }

  int componentColumn(ComponentID id, SetHash hash) {
    return _componentIndex[id]![hash]!;
  }

  List<Archetype> findMatchingArchetypes(SetHash hash) {
    final result = <Archetype>[];
    for (final archetype in _archetypeIndex.values) {
      if (!archetype.isEmpty && archetype.setHash.contains(hash)) {
        result.add(archetype);
      }
    }
    return result;
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
    system.init();
  }

  void update<T>(T args, {String tag = ""}) {
    final systems = _systems[tag];
    if (systems == null) return;
    for (final system in systems) {
      system.update(args);
    }
  }

  T addResource<T>(T resource, {String tag = ""}) {
    return _resources["$T|$tag"] = resource;
  }

  T? getResource<T>({String tag = ""}) {
    return _resources["$T|$tag"] as T?;
  }

  T? removeResource<T>({String tag = ""}) {
    return _resources.remove("$T|$tag") as T?;
  }

  EntityID createEntity() {
    final entityID = _entityCounter++;
    _entityIndex[entityID] = null;
    return entityID;
  }

  bool removeEntity(EntityID entityID) {
    if (!isAlive(entityID)) return false;
    final record = _entityIndex[entityID];
    if (record == null) {
      _entityIndex.remove(entityID);
      return true;
    }
    _removeEntityFromArchetype(entityID, record.archetype, record.entityRow);
    return true;
  }

  @pragma('vm:prefer-inline')
  bool isAlive(EntityID entityID) => _entityIndex.containsKey(entityID);

  ComponentID _getOrCreateComponentID(Type type) {
    final id = _componentTypes[type];
    if (id != null) return id;
    _componentTypes[type] = _componentCounter;
    _componentCounter++;
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

  void removeEntities(Iterable<EntityID> entities) {
    final Map<Archetype, List<int>> rows = {};

    for (final e in entities) {
      final record = _entityIndex.remove(e);
      if (record == null) continue;
      rows.putIfAbsent(record.archetype, () => []).add(record.entityRow);
    }

    for (final entry in rows.entries) {
      final archetype = entry.key;
      final rowsToRemove = entry.value..sort((a, b) => b.compareTo(a));

      for (final row in rowsToRemove) {
        for (final column in archetype.components) {
          column.removeAt(row);
        }
      }

      for (int i = 0; i < archetype.components[0].length; i++) {
        final eid = archetype.components[0][i].entityID;
        if (eid != -1) {
          _entityIndex[eid]!.entityRow = i;
        }
      }
    }
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

  void addComponent(EntityID entityID, Component component) {
    component.entityID = entityID;
    final componentID = _getOrCreateComponentID(component.runtimeType);

    final record = _entityIndex.remove(entityID);

    if (record == null) {
      _componentIndex[componentID] ??= {};

      final hash = SetHash({componentID});
      final archetype = _getOrCreateArchetype(hash);

      final indexMap = _componentIndex[componentID]!;
      final columnIndex = indexMap[hash];

      if (columnIndex == null) {
        indexMap[hash] = archetype.components.length;
        archetype.components.add([component]);
        _entityIndex[entityID] = Record(
          archetype: archetype,
          entityRow: 0,
        );
      } else {
        final componentsList = archetype.components[columnIndex];
        _entityIndex[entityID] = Record(
          archetype: archetype,
          entityRow: componentsList.length,
        );
        componentsList.add(component);
      }
    } else {
      _componentIndex[componentID] ??= {};

      final oldArchetype = record.archetype;
      final hash = oldArchetype.setHash.copy();
      hash.add(componentID);
      final archetype = _getOrCreateArchetype(hash);

      _moveEntity(
        entityID,
        oldArchetype,
        record.entityRow,
        archetype,
        toAdd: [component],
      );
    }
  }

  void addComponents(EntityID entityID, List<Component> components) {
    final componentIDs = <ComponentID>{};

    for (final component in components) {
      component.entityID = entityID;
      final id = _getOrCreateComponentID(component.runtimeType);
      componentIDs.add(id);
      _componentIndex[id] ??= {};
    }

    final record = _entityIndex.remove(entityID);

    if (record == null) {
      final hash = SetHash(componentIDs);
      final archetype = _getOrCreateArchetype(hash);

      for (final component in components) {
        final id = _componentTypes[component.runtimeType]!;
        final indexMap = _componentIndex[id]!;

        if (indexMap[hash] == null) {
          indexMap[hash] = archetype.components.length;
          archetype.components.add([]);
        }

        archetype.components[indexMap[hash]!].add(component);
      }

      _entityIndex[entityID] = Record(
        archetype: archetype,
        entityRow: archetype.components[0].length - 1,
      );
    } else {
      final oldArchetype = record.archetype;
      final hash = oldArchetype.setHash.copy()..addAll(componentIDs);
      final archetype = _getOrCreateArchetype(hash);

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
    removeComponentByType(entityID, T);
  }

  void removeComponentByType(EntityID entityID, Type t) {
    final record = _entityIndex[entityID];
    if (record == null) return;

    final componentID = _componentTypes[t];
    if (componentID == null) return;
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

    final componentIDs = <ComponentID>{};

    for (final type in components) {
      final id = _componentTypes[type];
      if (id != null) {
        componentIDs.add(id);
      }
    }

    if (componentIDs.isEmpty) return;

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

  int createEntityWith(List<Component> components) {
    final entityID = createEntity();
    final componentIDs = <ComponentID>[];

    for (final component in components) {
      component.entityID = entityID;
      final id = _getOrCreateComponentID(component.runtimeType);
      componentIDs.add(id);
      _componentIndex[id] ??= {};
    }

    final hash = SetHash(componentIDs);
    final archetype = _getOrCreateArchetype(hash);

    for (int i = 0; i < components.length; i++) {
      final componentID = componentIDs[i];
      final component = components[i];

      final indexMap = _componentIndex[componentID]!;
      final col = indexMap[hash] ??= archetype.components.length;
      if (col == archetype.components.length) {
        archetype.components.add([]);
      }
      archetype.components[col].add(component);
    }

    _entityIndex[entityID] = Record(
      archetype: archetype,
      entityRow: archetype.components[0].length - 1,
    );

    return entityID;
  }

  List<EntityID> createEntities(List<List<Component>> entitiesComponents) {
    final newEntities = <EntityID>[];

    for (final components in entitiesComponents) {
      newEntities.add(createEntityWith(components));
    }

    return newEntities;
  }

  void queryEach(
    QueryParams params,
    void Function(QueryRowView row) fn,
  ) {
    if (!params.activate(this)) return;

    final componentIDs = params.componentIDs;
    final typeIndices = params.typeIndices;
    final columns = List<int>.filled(componentIDs.length, 0);

    final row = QueryRowView();

    for (final archetype in _archetypeIndex.values) {
      if (archetype.isEmpty || !archetype.setHash.contains(params.hash)) {
        continue;
      }

      for (int c = 0; c < componentIDs.length; c++) {
        columns[c] = _componentIndex[componentIDs[c]]![archetype.setHash]!;
      }

      for (int i = 0; i < archetype.entityCount; i++) {
        row.bind(archetype, columns, i, typeIndices);
        fn(row);
      }
    }
  }

  void queryEachPairs(
    QueryParams aParams,
    QueryParams bParams,
    void Function(QueryRowView a, QueryRowView b) fn,
  ) {
    if (!aParams.activate(this) || !bParams.activate(this)) return;

    final aColumns = List<int>.filled(aParams.componentIDs.length, 0);
    final bColumns = List<int>.filled(bParams.componentIDs.length, 0);

    final aRow = QueryRowView();
    final bRow = QueryRowView();

    final archetypes = _archetypeIndex.values.toList(growable: false);

    for (final aArch in archetypes) {
      if (aArch.isEmpty || !aArch.setHash.contains(aParams.hash)) continue;

      for (int c = 0; c < aParams.componentIDs.length; c++) {
        aColumns[c] = _componentIndex[aParams.componentIDs[c]]![aArch.setHash]!;
      }

      for (final bArch in archetypes) {
        if (bArch.isEmpty || !bArch.setHash.contains(bParams.hash)) continue;

        for (int c = 0; c < bParams.componentIDs.length; c++) {
          bColumns[c] = _componentIndex[bParams.componentIDs[c]]![bArch.setHash]!;
        }

        for (int ai = 0; ai < aArch.entityCount; ai++) {
          aRow.bind(aArch, aColumns, ai, aParams.typeIndices);

          for (int bi = 0; bi < bArch.entityCount; bi++) {
            bRow.bind(bArch, bColumns, bi, bParams.typeIndices);

            if (aRow.entity == bRow.entity) continue;

            fn(aRow, bRow);
          }
        }
      }
    }
  }

  void queryEachPairsSelf(
    QueryParams params,
    void Function(QueryRowView a, QueryRowView b) fn,
  ) {
    if (!params.activate(this)) return;

    final columns = List<int>.filled(params.componentIDs.length, 0);
    final rowA = QueryRowView();
    final rowB = QueryRowView();

    final archetypes = _archetypeIndex.values.toList(growable: false);

    for (final arch in archetypes) {
      if (arch.isEmpty || !arch.setHash.contains(params.hash)) continue;

      for (int c = 0; c < params.componentIDs.length; c++) {
        columns[c] = _componentIndex[params.componentIDs[c]]![arch.setHash]!;
      }

      final count = arch.entityCount;

      for (int i = 0; i < count; i++) {
        rowA.bind(arch, columns, i, params.typeIndices);

        for (int j = i + 1; j < count; j++) {
          rowB.bind(arch, columns, j, params.typeIndices);
          fn(rowA, rowB);
        }
      }
    }
  }

  List<Component> queryRaw(QueryParams params) {
    final queryRows = <Component>[];
    if (!params.activate(this)) return queryRows;

    final columns = List<int>.filled(params.componentIDs.length, 0);

    for (final archetype in _archetypeIndex.values) {
      if (!archetype.setHash.contains(params.hash)) continue;
      for (int c = 0; c < params.componentIDs.length; c++) {
        columns[c] = _componentIndex[params.componentIDs[c]]![archetype.setHash]!;
      }

      for (int i = 0; i < archetype.entityCount; i++) {
        for (int c = 0; c < columns.length; c++) {
          queryRows.add(archetype.components[columns[c]][i]);
        }
      }
    }
    return queryRows;
  }

  int queryCount(List<Type> types) => queryCountWithParams(QueryParams(types));
  int queryCountWithParams(QueryParams params) {
    if (!params.activate(this)) return 0;
    int queryCount = 0;
    for (final kv in _archetypeIndex.entries) {
      if (kv.value.isEmpty || !kv.key.contains(params.hash)) continue;
      queryCount += kv.value.entityCount;
    }
    return queryCount;
  }

  List<QueryRow> query(List<Type> types) => queryWithParams(QueryParams(types));
  List<QueryRow> queryWithParams(QueryParams params) {
    final result = <QueryRow>[];
    final queryResults = queryRaw(params);
    if (queryResults.isEmpty) return result;
    final len = params.componentIDs.length;
    if (len == 0) return result;
    final rowCount = queryResults.length ~/ len;
    for (int i = 0; i < rowCount; i++) {
      result.add(QueryRow(queryResults, i * len, params.typeIndices));
    }
    return result;
  }
}
