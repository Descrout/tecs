import 'package:flutter_test/flutter_test.dart';
import 'package:tecs/component.dart';
import 'package:tecs/world.dart';

class NameComponent extends Component {
  NameComponent({
    required this.name,
  });

  final String name;
}

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

  test('archetypes must merge instead of adding new', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, PositionComponent(x: 3, y: 4));

    expect(world.archetypeCount, 1);
  });

  test('adding component', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();
    final entity3 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));

    world.addComponent(entity2, PositionComponent(x: 7, y: 8));
    world.addComponent(entity2, ColorComponent(r: 9, g: 12, b: 111));

    world.addComponent(entity3, ColorComponent(r: 5, g: 6, b: 120));

    final pos1 = world.getComponent<PositionComponent>(entity1);
    final color1Null = world.getComponent<ColorComponent>(entity1);
    expect(pos1, isNotNull);
    expect(color1Null, isNull);
    expect(pos1!.x, 3);

    final pos2 = world.getComponent<PositionComponent>(entity2);
    final color2 = world.getComponent<ColorComponent>(entity2);
    expect(pos2, isNotNull);
    expect(color2, isNotNull);

    expect(pos1.y, 4);
    expect(pos2!.y, 8);

    expect(color2!.r + color2.g + color2.b, 132);

    world.addComponent(entity1, ColorComponent(r: 65, g: 32, b: 49));
    world.addComponent(entity2, NameComponent(name: "ent2"));
    world.addComponent(entity1, NameComponent(name: "ent1"));

    expect(color2.r + color2.g + color2.b, 132);

    final color1 = world.getComponent<ColorComponent>(entity1);
    expect(color1, isNotNull);
    expect(color1!.r + color1.g + color1.b, 146);
  });

  test('removing component', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));

    world.addComponent(entity2, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));

    final color2 = world.getComponent<ColorComponent>(entity2);
    expect(color2, isNotNull);
    expect(color2!.b, 100);

    world.removeComponent<ColorComponent>(entity2);

    final color2Null = world.getComponent<ColorComponent>(entity2);
    expect(color2Null, isNull);

    world.removeComponent<PositionComponent>(entity1);
    world.addComponent(entity1, NameComponent(name: "ent1"));

    final pos1Null = world.getComponent<PositionComponent>(entity1);
    expect(pos1Null, isNull);

    final name1 = world.getComponent<NameComponent>(entity1);
    expect(name1, isNotNull);
    expect(name1!.name, "ent1");
  });
}
