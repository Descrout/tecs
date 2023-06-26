import 'package:flutter_test/flutter_test.dart';
import 'package:tecs/component.dart';
import 'package:tecs/world.dart';

class PositionComponent extends Component {
  PositionComponent({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;
}

class ColorComponent extends Component {
  ColorComponent({
    required this.r,
    required this.g,
    required this.b,
  });

  final double r;
  final double g;
  final double b;
}

void main() {
  test('creating entity must match with entityID', () {
    final world = World();

    final entities = List.generate(5, (_) => world.createEntity());

    for (int i = 0; i < entities.length; i++) {
      expect(i, entities[i]);
    }
  });

  test('registering component should populate component ids, recurring type should not affect', () {
    final world = World();
    world.registerComponent<PositionComponent>();
    world.registerComponent<PositionComponent>();
    world.registerComponent<ColorComponent>();

    expect(world.componentCounter, 2);
    expect(world.componentCounter, world.componentTypes.length);
  });

  test('adding component', () {
    final world = World();

    world.registerComponent<PositionComponent>();
    world.registerComponent<ColorComponent>();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();
    final entity3 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));

    world.addComponent(entity2, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));

    world.addComponent(entity3, ColorComponent(r: 3, g: 4, b: 100));

    final pos1 = world.getComponent<PositionComponent>(entity1);
    final color1 = world.getComponent<ColorComponent>(entity1);
    expect(pos1, isNotNull);
    expect(color1, isNull);
    expect(pos1!.x, 3);

    final pos2 = world.getComponent<PositionComponent>(entity2);
    final color2 = world.getComponent<ColorComponent>(entity2);
    expect(pos2, isNotNull);
    expect(color2, isNotNull);

    expect(pos1.y, 4);
    expect(pos1.y, pos2!.y);

    expect(color2!.r + color2.g + color2.b, 107);

    //TODO: test => archetypeIndex, entityIndex, componentIndex
    //TODO: do removeComponent
    //TODO: do removeEntity
  });
}
