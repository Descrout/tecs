import 'package:tecs/tecs.dart';
import 'package:test/test.dart';

class FooSystem extends System<double> {
  @override
  void update(double deltaTime) {
    final foo = world.getResource<Foo>()!;
    foo.bar += 1;
    final a = deltaTime * foo.bar;
    print(a.toString());
  }
}

class BarSystem extends System<({int number, String message})> {
  @override
  void update(args) {
    final foo = world.getResource<Foo>()!;
    foo.bar += 2;

    for (int i = 0; i < args.number; i++) {
      print(args.message);
    }
  }
}

class Foo {
  int bar = 0;
}

class FooGeneric<T> {
  FooGeneric({required this.val});
  final T val;
}

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
    expect(color2!.entityID, entity2);

    expect(pos1.y, 4);
    expect(pos2!.y, 8);

    expect(color2.r + color2.g + color2.b, 132);

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

  test('delete entity', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();
    final entity3 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));

    world.addComponent(entity2, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));

    world.addComponent(entity3, PositionComponent(x: 3, y: 4));
    world.addComponent(entity3, ColorComponent(r: 3, g: 4, b: 100));

    expect(world.archetypeCount, 2);
    expect(world.entityCount, 3);

    expect(world.isAlive(entity2), true);
    expect(world.removeEntity(entity2), true);

    expect(world.entityCount, 2);

    expect(world.isAlive(entity2), false);
    expect(world.removeEntity(entity2), false);
  });

  test('query raw', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();
    final entity3 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));
    world.addComponent(entity1, NameComponent(name: "ent1"));

    world.addComponent(entity2, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));

    world.addComponent(entity3, ColorComponent(r: 3, g: 4, b: 100));
    world.addComponent(entity3, PositionComponent(x: 3, y: 4));

    final queryResult1 = world.queryRaw([ColorComponent, PositionComponent]);
    expect(queryResult1.length, 2);
    for (final components in queryResult1) {
      expect(components.length, 2);
      expect(components[0].runtimeType, ColorComponent);
      expect(components[1].runtimeType, PositionComponent);
      expect((components[0] as ColorComponent).b, 100);
    }

    final queryResult2 = world.queryRaw([PositionComponent]);
    expect(queryResult2.length, 3);
    for (final components in queryResult2) {
      expect(components.length, 1);
      expect(components[0].runtimeType, PositionComponent);
    }

    final queryResult3 = world.queryRaw([NameComponent]);
    expect(queryResult3.length, 1);
    for (final components in queryResult3) {
      expect(components.length, 1);
      expect(components[0].runtimeType, NameComponent);
      expect((components[0] as NameComponent).name, "ent1");
      expect(components[0].entityID, entity1);
    }
  });

  test('query user friendly', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));
    world.addComponent(entity1, NameComponent(name: "ent1"));

    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));
    world.addComponent(entity2, PositionComponent(x: 3, y: 4));

    final queryResult1 = world.query([ColorComponent, PositionComponent]);
    for (final row in queryResult1.rows) {
      expect(row.get<PositionComponent>().x, 3);
      expect(row.get<ColorComponent>().b, 100);
    }

    final queryResult2 = world.query([NameComponent]);
    for (final row in queryResult2.rows) {
      expect(row.get<NameComponent>().name, "ent1");
      expect(row.entity, entity1);
    }
  });

  test('resources', () {
    final world = World();
    world.addResource(Foo());

    expect(world.getResource<Foo>(), isNotNull);
    expect(world.getResource<Foo>().runtimeType, Foo);
    expect(world.getResource<Foo>()!.bar, 0);

    final foo = world.getResource<Foo>();
    foo!.bar = 12;

    expect(world.getResource<Foo>()!.bar, 12);

    world.addResource(Foo());
    expect(world.getResource<Foo>()!.bar, 0);

    final foo2 = world.getResource<Foo>();
    foo2!.bar = 15;

    world.addResource(Foo(), tag: "hello");
    expect(world.getResource<Foo>()!.bar, 15);
    expect(world.getResource<Foo>(tag: "hello")!.bar, 0);

    world.addResource(FooGeneric(val: "yoo"));
    world.addResource(FooGeneric(val: 3.14159));

    expect(world.getResource<FooGeneric<String>>(), isNotNull);
    expect(world.getResource<FooGeneric<String>>().runtimeType, FooGeneric<String>);
    expect(world.getResource<FooGeneric<String>>()!.val, "yoo");

    expect(world.getResource<FooGeneric<double>>(), isNotNull);
    expect(world.getResource<FooGeneric<double>>().runtimeType, FooGeneric<double>);
    expect(world.getResource<FooGeneric<double>>()!.val, 3.14159);
  });

  test('systems', () {
    final world = World();

    final foo = Foo();

    world.addResource(foo);
    world.addSystem(FooSystem());
    world.addSystem(BarSystem(), tag: "bar");

    world.update(0.016);
    world.update(0.016);
    world.update(0.016);
    world.update(0.016);

    world.update((number: 3, message: "Hello World"), tag: "bar");

    expect(foo.bar, 6);
  });
}
