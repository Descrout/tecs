import 'package:tecs/component.dart';
import 'package:tecs/types.dart';
import 'package:tecs/world.dart';

sealed class _Command {
  final EntityID entity;
  _Command(this.entity);

  factory _Command.addComponent(EntityID entity, Component c) = _AddComponent;
  factory _Command.removeComponent(EntityID entity, Type t) = _RemoveComponent;
  factory _Command.addComponents(EntityID entity, List<Component> c) = _AddComponents;
  factory _Command.removeComponents(EntityID entity, List<Type> c) = _RemoveComponents;
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
  void removeEntity(EntityID e) {
    if (_removedEntities.add(e)) {
      _removeCount++;
    }
  }

  @pragma('vm:prefer-inline')
  void addComponent(EntityID e, Component c) {
    if (_removedEntities.contains(e)) return;
    _commands.add(_Command.addComponent(e, c));
  }

  @pragma('vm:prefer-inline')
  void createEntityWith(List<Component> c) {
    _createEntities.add(c);
  }

  @pragma('vm:prefer-inline')
  void removeComponent(EntityID e, Type type) {
    if (_removedEntities.contains(e)) return;
    _commands.add(_Command.removeComponent(e, type));
  }

  @pragma('vm:prefer-inline')
  void addComponents(EntityID e, List<Component> c) {
    if (_removedEntities.contains(e)) return;
    _commands.add(_Command.addComponents(e, c));
  }

  @pragma('vm:prefer-inline')
  void removeComponents(EntityID e, List<Type> c) {
    if (_removedEntities.contains(e)) return;
    _commands.add(_Command.removeComponents(e, c));
  }

  void flush(World world) {
    if (isEmpty) return;

    for (final components in _createEntities) {
      world.createEntityWith(components);
    }

    for (final cmd in _commands) {
      if (_removeCount > 0 && _removedEntities.contains(cmd.entity)) continue;
      switch (cmd) {
        case _AddComponent(component: final component):
          world.addComponent(cmd.entity, component);
          break;
        case _RemoveComponent(componentType: final componentType):
          world.removeComponentByType(cmd.entity, componentType);
          break;
        case _AddComponents(components: final components):
          world.addComponents(cmd.entity, components);
          break;
        case _RemoveComponents(componentTypes: final componentTypes):
          world.removeComponents(cmd.entity, components: componentTypes);
          break;
      }
    }

    if (_removeCount != 0) {
      world.removeEntities(_removedEntities);
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
