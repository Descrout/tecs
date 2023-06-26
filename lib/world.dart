import 'dart:collection';

import 'package:tecs/archetype.dart';
import 'package:tecs/list_hash.dart';
import 'package:tecs/tecs.dart';
import 'package:tecs/types.dart';

class World {
  final _archetypeIndex = <ListHash, Archetype>{};
  final _entityIndex = <EntityID, Record>{};
  final _componentIndex = <ComponentID, Map<ArchetypeID, int>>{};

  final _componentTypes = <Type, ComponentID>{};

  int _componentCounter = 0;
  int _entityCounter = 0;
  int _archetypeCounter = 0;

  int get componentCounter => _componentCounter;

  UnmodifiableMapView<Type, ComponentID> get componentTypes => UnmodifiableMapView(_componentTypes);

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

  EntityID createEntity() => _entityCounter++;

  void registerComponent<T extends Component>() {
    if (!_componentTypes.containsKey(T)) {
      _componentTypes[T] = _componentCounter++;
    }
  }

  Archetype _getOrCreateArcheType(ListHash listHash) {
    Archetype? archetype = _archetypeIndex[listHash];
    if (archetype != null) return archetype;
    final archetypeID = _archetypeCounter++;
    archetype = Archetype(
      id: archetypeID,
      type: listHash,
      components: [],
    );

    _archetypeIndex[archetype.type] = archetype;
    return archetype;
  }

  void _moveEntityAndAdd(
    Archetype fromArchetype,
    int entityRow,
    Archetype toArchetype,
    Component component,
    EntityID entityID,
  ) {
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
      removedComps.add(compsOfEntity.removeAt(entityRow));
    }
    removedComps.add(component);
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

  void addComponent(EntityID entityID, Component component) {
    component.entityID = entityID;
    final componentID = _componentTypes[component.runtimeType]!;
    _componentIndex[componentID] ??= {};

    final record = _entityIndex.remove(entityID);
    if (record == null) {
      final listHash = ListHash([componentID], true);
      final archetype = _getOrCreateArcheType(listHash);
      if (_componentIndex[componentID]![archetype.id] == null) {
        _componentIndex[componentID]![archetype.id] = archetype.components.length;
        archetype.components.add([]);
      }

      final componentsList = archetype.components[_componentIndex[componentID]![archetype.id]!];
      _entityIndex[entityID] = Record(archetype: archetype, entityRow: componentsList.length);
      componentsList.add(component);
    } else {
      final oldArchetype = record.archetype;
      final listHash = oldArchetype.type.copy();
      listHash.add(componentID);
      final archetype = _getOrCreateArcheType(listHash);
      _moveEntityAndAdd(
        oldArchetype,
        record.entityRow,
        archetype,
        component,
        entityID,
      );
    }
  }
}
