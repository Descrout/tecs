import 'package:tecs/component.dart';
import 'package:tecs/types.dart';
import 'package:tecs/world.dart';

sealed class _Command {
  final EntityID entityID;
  _Command(this.entityID);

  factory _Command.addComponent(EntityID entityID, Component component) = _AddComponent;
  factory _Command.removeComponent(EntityID entityID, Type componentType) = _RemoveComponent;
  factory _Command.addComponents(EntityID entityID, List<Component> components) = _AddComponents;
  factory _Command.removeComponents(EntityID entityID, List<Type> componentTypes) =
      _RemoveComponents;
}

class _AddComponent extends _Command {
  final Component component;
  _AddComponent(super.entity, this.component);
}

class _RemoveComponent extends _Command {
  final Type componentType;
  _RemoveComponent(super.entity, this.componentType);
}

class _AddComponents extends _Command {
  final List<Component> components;
  _AddComponents(super.entity, this.components);
}

class _RemoveComponents extends _Command {
  final List<Type> componentTypes;
  _RemoveComponents(super.entity, this.componentTypes);
}

class CommandBuffer {
  final List<_Command> _commands = [];

  final Set<EntityID> _removedEntities = {};
  int _removeCount = 0;

  final List<List<Component>> _createEntities = [];

  @pragma('vm:prefer-inline')
  void removeEntity(EntityID entityID) {
    if (_removedEntities.add(entityID)) {
      _removeCount++;
    }
  }

  @pragma('vm:prefer-inline')
  void addComponent(EntityID entityID, Component component) {
    if (_removedEntities.contains(entityID)) return;
    _commands.add(_Command.addComponent(entityID, component));
  }

  @pragma('vm:prefer-inline')
  void createEntityWith(List<Component> components) {
    _createEntities.add(components);
  }

  @pragma('vm:prefer-inline')
  void createEntities(List<List<Component>> entities) {
    _createEntities.addAll(entities);
  }

  @pragma('vm:prefer-inline')
  void removeComponent(EntityID entityID, Type componentType) {
    if (_removedEntities.contains(entityID)) return;
    _commands.add(_Command.removeComponent(entityID, componentType));
  }

  @pragma('vm:prefer-inline')
  void addComponents(EntityID entityID, List<Component> components) {
    if (_removedEntities.contains(entityID)) return;
    _commands.add(_Command.addComponents(entityID, components));
  }

  @pragma('vm:prefer-inline')
  void removeComponents(EntityID entityID, List<Type> componentTypes) {
    if (_removedEntities.contains(entityID)) return;
    _commands.add(_Command.removeComponents(entityID, componentTypes));
  }

  void apply(World world) {
    if (isEmpty) return;

    for (final components in _createEntities) {
      world.instant.createEntityWith(components);
    }

    for (final cmd in _commands) {
      if (_removeCount > 0 && _removedEntities.contains(cmd.entityID)) continue;
      switch (cmd) {
        case _AddComponent(component: final component):
          world.instant.addComponent(cmd.entityID, component);
          break;
        case _RemoveComponent(componentType: final componentType):
          world.instant.removeComponentByType(cmd.entityID, componentType);
          break;
        case _AddComponents(components: final components):
          world.instant.addComponents(cmd.entityID, components);
          break;
        case _RemoveComponents(componentTypes: final componentTypes):
          world.instant.removeComponents(cmd.entityID, components: componentTypes);
          break;
      }
    }

    if (_removeCount != 0) {
      world.instant.removeEntities(_removedEntities);
    }

    clear();
  }

  @pragma('vm:prefer-inline')
  void clear() {
    _commands.clear();
    _removedEntities.clear();
    _removeCount = 0;
    _createEntities.clear();
  }

  bool get isEmpty => length == 0;
  int get length => _commands.length + _removeCount + _createEntities.length;
}
