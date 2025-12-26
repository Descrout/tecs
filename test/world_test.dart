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
  NameComponent({required this.name});
  final String name;
}

class PositionComponent extends Component {
  PositionComponent({required this.x, required this.y});
  final double x;
  final double y;
}

class ColorComponent extends Component {
  ColorComponent({required this.r, required this.g, required this.b});
  final double r;
  final double g;
  final double b;
}

class VelocityComponent extends Component {
  VelocityComponent({required this.dx, required this.dy});
  final double dx;
  final double dy;
}

class HealthComponent extends Component {
  HealthComponent({required this.health});
  final int health;
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

  test('add components in bulk', () {
    final world = World();

    final entity1 = world.createEntity();
    world.addComponent(entity1, PositionComponent(x: 3, y: 4));
    world.addComponents(entity1, components: [
      NameComponent(name: "ent1"),
      ColorComponent(r: 9, g: 12, b: 111),
    ]);
    final pos1 = world.getComponent<PositionComponent>(entity1);
    final color1 = world.getComponent<ColorComponent>(entity1);
    final name1 = world.getComponent<NameComponent>(entity1);
    expect(pos1, isNotNull);
    expect(pos1!.x, 3);

    expect(color1, isNotNull);
    expect(name1, isNotNull);
    expect(name1!.name, "ent1");

    final entity2 = world.createEntity();
    world.addComponents(entity2, components: [
      PositionComponent(x: 7, y: 8),
      ColorComponent(r: 9, g: 12, b: 111),
    ]);

    final pos2 = world.getComponent<PositionComponent>(entity2);
    final color2 = world.getComponent<ColorComponent>(entity2);
    expect(pos2, isNotNull);
    expect(color2, isNotNull);
    expect(color2!.entityID, entity2);

    expect(pos2!.y, 8);

    expect(color2.r + color2.g + color2.b, 132);
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

  test('remove components in bulk', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));

    world.addComponent(entity2, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));
    world.addComponent(entity2, NameComponent(name: "ent2"));

    world.removeComponents(entity2, components: [ColorComponent, NameComponent]);

    final color2Null = world.getComponent<ColorComponent>(entity2);
    expect(color2Null, isNull);

    final name2Null = world.getComponent<NameComponent>(entity2);
    expect(name2Null, isNull);

    final pos2 = world.getComponent<PositionComponent>(entity2);
    expect(pos2!.x, 3);
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

  test('query raw - flat buffer format', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();
    final entity3 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 1, y: 2));
    world.addComponent(entity1, NameComponent(name: "ent1"));

    world.addComponent(entity2, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, ColorComponent(r: 10, g: 20, b: 100));

    world.addComponent(entity3, ColorComponent(r: 30, g: 40, b: 200));
    world.addComponent(entity3, PositionComponent(x: 5, y: 6));

    final params = QueryParams([ColorComponent, PositionComponent]);
    final queryResult = world.queryRaw(params);

    // 2 entities * 2 components = 4 components total
    expect(queryResult.length, 4);

    // First entity's components
    expect(queryResult[0].runtimeType, ColorComponent);
    expect(queryResult[1].runtimeType, PositionComponent);
    expect((queryResult[0] as ColorComponent).b, 100);
    expect((queryResult[1] as PositionComponent).x, 3);

    // Second entity's components
    expect(queryResult[2].runtimeType, ColorComponent);
    expect(queryResult[3].runtimeType, PositionComponent);
    expect((queryResult[2] as ColorComponent).b, 200);
    expect((queryResult[3] as PositionComponent).x, 5);
  });

  test('query user friendly', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));
    world.addComponent(entity1, NameComponent(name: "ent1"));

    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));
    world.addComponent(entity2, PositionComponent(x: 3, y: 4));

    final resultRows1 = world.query([ColorComponent, PositionComponent]);
    for (final row in resultRows1) {
      expect(row.get<PositionComponent>().x, 3);
      expect(row.get<ColorComponent>().b, 100);
    }

    final resultRows2 = world.queryWithParams(QueryParams([NameComponent]));
    for (final row in resultRows2) {
      expect(row.get<NameComponent>().name, "ent1");
      expect(row.entity, entity1);
    }
  });

  test('query count', () {
    final world = World();

    final entity1 = world.createEntity();
    final entity2 = world.createEntity();
    final entity3 = world.createEntity();

    world.addComponent(entity1, PositionComponent(x: 3, y: 4));

    world.addComponent(entity2, PositionComponent(x: 3, y: 4));
    world.addComponent(entity2, ColorComponent(r: 3, g: 4, b: 100));

    world.addComponent(entity3, PositionComponent(x: 3, y: 4));
    world.addComponent(entity3, ColorComponent(r: 3, g: 4, b: 100));

    expect(world.queryCount([NameComponent]), 0);
    expect(world.queryCountWithParams(QueryParams([PositionComponent])), 3);
    expect(world.queryCountWithParams(QueryParams([ColorComponent])), 2);
    expect(world.queryCount([PositionComponent, ColorComponent]), 2);

    world.removeEntity(entity2);

    expect(world.queryCount([PositionComponent]), 2);
    expect(world.queryCount([ColorComponent]), 1);
    expect(world.queryCount([PositionComponent, ColorComponent]), 1);
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

  test('create entities in bulk', () {
    final world = World();

    final bulkComponents = [
      [PositionComponent(x: 10.0, y: 20.0), ColorComponent(r: 255, g: 0, b: 0)],
      [PositionComponent(x: 30.0, y: 40.0)],
      [PositionComponent(x: 50.0, y: 60.0), ColorComponent(r: 0, g: 0, b: 255)],
    ];

    final entityIDs = world.createEntities(bulkComponents);

    expect(entityIDs.length, 3, reason: "Should create 3 entities");
    expect(world.entityCount, 3, reason: "World should have 3 entities");

    for (int i = 0; i < entityIDs.length; i++) {
      final entityID = entityIDs[i];

      final position = world.getComponent<PositionComponent>(entityID);
      expect(position, isNotNull, reason: "Entity $entityID should have a PositionComponent");
      expect(position!.x, (bulkComponents[i][0] as PositionComponent).x,
          reason: "PositionComponent.x should match input");
      expect(position.y, (bulkComponents[i][0] as PositionComponent).y,
          reason: "PositionComponent.y should match input");

      final color = world.getComponent<ColorComponent>(entityID);
      if (i == 1) {
        expect(color, isNull, reason: "Entity $entityID should not have a ColorComponent");
      } else {
        expect(color, isNotNull, reason: "Entity $entityID should have a ColorComponent");
        expect(color!.r, (bulkComponents[i][1] as ColorComponent).r,
            reason: "ColorComponent.r should match input");
        expect(color.g, (bulkComponents[i][1] as ColorComponent).g,
            reason: "ColorComponent.g should match input");
        expect(color.b, (bulkComponents[i][1] as ColorComponent).b,
            reason: "ColorComponent.b should match input");
      }
    }

    world.addComponent(entityIDs[1], ColorComponent(r: 0, g: 255, b: 0));
    final color = world.getComponent<ColorComponent>(entityIDs[1]);
    expect(color, isNotNull);
    expect(color!.r, 0);
    expect(color.g, 255);
  });

  test('query params must cache archetypes correctly', () {
    final world = World();
    final params = QueryParams([PositionComponent]);

    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));

    final result1 = world.queryWithParams(params);
    expect(result1.length, 1);

    final e2 = world.createEntity();
    world.addComponent(e2, PositionComponent(x: 3, y: 4));
    world.addComponent(e2, ColorComponent(r: 1, g: 2, b: 3));

    final result2 = world.queryWithParams(params);
    expect(result2.length, 2);
  });

  test('query params cache should persist across multiple calls', () {
    final world = World();
    final params = QueryParams([PositionComponent]);

    for (int i = 0; i < 5; i++) {
      final e = world.createEntity();
      world.addComponent(e, PositionComponent(x: i.toDouble(), y: i.toDouble()));
    }

    final result1 = world.queryWithParams(params);
    expect(result1.length, 5);

    final result2 = world.queryWithParams(params);
    expect(result2.length, 5);

    world.removeEntity(2);
    final result3 = world.queryWithParams(params);
    expect(result3.length, 4);
  });

  test('query params must re-resolve after clearEntities', () {
    final world = World();
    final params = QueryParams([PositionComponent]);

    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));

    expect(world.queryWithParams(params).length, 1);

    world.clearEntities();

    final e2 = world.createEntity();
    world.addComponent(e2, PositionComponent(x: 5, y: 6));

    final result = world.queryWithParams(params);
    expect(result.length, 1);
    expect(result.first.entity, e2);
  });

  test('query params should activate when missing component is added later', () {
    final world = World();
    final params = QueryParams([PositionComponent, ColorComponent]);

    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));

    expect(world.queryWithParams(params), isEmpty);

    world.addComponent(e1, ColorComponent(r: 1, g: 2, b: 3));

    final result = world.queryWithParams(params);
    expect(result.length, 1);
    expect(result.first.get<ColorComponent>().b, 3);
  });

  test('query params cache invalidation on new archetype creation', () {
    final world = World();
    final params = QueryParams([PositionComponent]);

    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));

    final oldArchetypeCount = world.archetypeCount;
    expect(world.queryWithParams(params).length, 1);

    final e2 = world.createEntity();
    world.addComponent(e2, PositionComponent(x: 3, y: 4));
    world.addComponent(e2, ColorComponent(r: 1, g: 2, b: 3));

    expect(world.archetypeCount, oldArchetypeCount + 1);

    final result = world.queryWithParams(params);
    expect(result.length, 2);
  });

  test('multiple query params should maintain independent caches', () {
    final world = World();
    final params1 = QueryParams([PositionComponent]);
    final params2 = QueryParams([ColorComponent]);
    final params3 = QueryParams([PositionComponent, ColorComponent]);

    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));

    final e2 = world.createEntity();
    world.addComponent(e2, ColorComponent(r: 1, g: 2, b: 3));

    final e3 = world.createEntity();
    world.addComponent(e3, PositionComponent(x: 4, y: 5));
    world.addComponent(e3, ColorComponent(r: 4, g: 5, b: 6));

    expect(world.queryWithParams(params1).length, 2); // e1, e3
    expect(world.queryWithParams(params2).length, 2); // e2, e3
    expect(world.queryWithParams(params3).length, 1); // e3
  });

  test('query row should provide correct components via type indices', () {
    final world = World();

    final e = world.createEntity();
    world.addComponent(e, PositionComponent(x: 10, y: 20));
    world.addComponent(e, VelocityComponent(dx: 1, dy: 2));
    world.addComponent(e, ColorComponent(r: 255, g: 128, b: 64));

    final rows1 = world.query([PositionComponent, VelocityComponent, ColorComponent]);
    final row1 = rows1.first;
    expect(row1.get<PositionComponent>().x, 10);
    expect(row1.get<VelocityComponent>().dx, 1);
    expect(row1.get<ColorComponent>().r, 255);

    final rows2 = world.query([ColorComponent, PositionComponent, VelocityComponent]);
    final row2 = rows2.first;
    expect(row2.get<ColorComponent>().r, 255);
    expect(row2.get<PositionComponent>().x, 10);
    expect(row2.get<VelocityComponent>().dx, 1);
  });

  test('query row entity ID must be correct', () {
    final world = World();

    final entities = List.generate(10, (i) {
      final e = world.createEntity();
      world.addComponent(e, PositionComponent(x: i.toDouble(), y: i.toDouble()));
      return e;
    });

    final rows = world.query([PositionComponent]);
    expect(rows.length, 10);

    for (int i = 0; i < rows.length; i++) {
      expect(rows[i].entity, entities[i]);
      expect(rows[i].get<PositionComponent>().entityID, entities[i]);
    }
  });

  test('query row buffer should handle multiple component types correctly', () {
    final world = World();

    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));
    world.addComponent(e1, VelocityComponent(dx: 0.1, dy: 0.2));
    world.addComponent(e1, HealthComponent(health: 100));

    final e2 = world.createEntity();
    world.addComponent(e2, PositionComponent(x: 3, y: 4));
    world.addComponent(e2, VelocityComponent(dx: 0.3, dy: 0.4));
    world.addComponent(e2, HealthComponent(health: 50));

    final rows = world.query([PositionComponent, VelocityComponent, HealthComponent]);
    expect(rows.length, 2);

    // First entity
    expect(rows[0].entity, e1);
    expect(rows[0].get<PositionComponent>().x, 1);
    expect(rows[0].get<VelocityComponent>().dx, 0.1);
    expect(rows[0].get<HealthComponent>().health, 100);

    // Second entity
    expect(rows[1].entity, e2);
    expect(rows[1].get<PositionComponent>().x, 3);
    expect(rows[1].get<VelocityComponent>().dx, 0.3);
    expect(rows[1].get<HealthComponent>().health, 50);
  });

  test('query params reuse should be deterministic', () {
    final world = World();
    final params = QueryParams([PositionComponent]);

    for (int i = 0; i < 10; i++) {
      final e = world.createEntity();
      world.addComponent(e, PositionComponent(x: i.toDouble(), y: i.toDouble()));
    }

    final r1 = world.queryWithParams(params);
    final r2 = world.queryWithParams(params);

    expect(r1.length, r2.length);

    for (int i = 0; i < r1.length; i++) {
      expect(r1[i].entity, r2[i].entity);
      expect(r1[i].get<PositionComponent>().x, r2[i].get<PositionComponent>().x);
    }
  });

  test('entity row indices must remain valid after removals', () {
    final world = World();

    final e1 = world.createEntity();
    final e2 = world.createEntity();
    final e3 = world.createEntity();

    world.addComponent(e1, PositionComponent(x: 1, y: 1));
    world.addComponent(e2, PositionComponent(x: 2, y: 2));
    world.addComponent(e3, PositionComponent(x: 3, y: 3));

    world.removeEntity(e2);

    final p1 = world.getComponent<PositionComponent>(e1);
    final p3 = world.getComponent<PositionComponent>(e3);

    expect(p1!.x, 1);
    expect(p3!.x, 3);
  });

  test('remove then re-add component should not corrupt archetypes', () {
    final world = World();

    final e = world.createEntity();
    world.addComponent(e, PositionComponent(x: 1, y: 2));
    world.addComponent(e, ColorComponent(r: 1, g: 1, b: 1));

    world.removeComponent<ColorComponent>(e);
    expect(world.getComponent<ColorComponent>(e), isNull);

    world.addComponent(e, ColorComponent(r: 5, g: 6, b: 7));

    final row = world.query([PositionComponent, ColorComponent]).single;
    expect(row.get<ColorComponent>().b, 7);
  });

  test('component entityID must always match owner entity', () {
    final world = World();

    final e = world.createEntity();
    world.addComponent(e, PositionComponent(x: 1, y: 1));
    world.addComponent(e, ColorComponent(r: 1, g: 1, b: 1));

    final rows = world.query([PositionComponent, ColorComponent]);
    for (final row in rows) {
      expect(row.get<PositionComponent>().entityID, row.entity);
      expect(row.get<ColorComponent>().entityID, row.entity);
    }
  });

  test('empty query should return empty list', () {
    final world = World();

    final e = world.createEntity();
    world.addComponent(e, PositionComponent(x: 1, y: 2));

    final result = world.query([ColorComponent]);
    expect(result, isEmpty);
  });

  test('query with non-existent component type should return empty', () {
    final world = World();

    final e = world.createEntity();
    world.addComponent(e, PositionComponent(x: 1, y: 2));

    final result = world.query([NameComponent, ColorComponent]);
    expect(result, isEmpty);
  });

  test('large scale query performance with cache', () {
    final world = World();
    final params = QueryParams([PositionComponent, VelocityComponent]);

    for (int i = 0; i < 1000; i++) {
      final e = world.createEntity();
      world.addComponent(e, PositionComponent(x: i.toDouble(), y: i.toDouble()));
      world.addComponent(e, VelocityComponent(dx: 0.1, dy: 0.2));
    }

    final stopwatch1 = Stopwatch()..start();
    final result1 = world.queryWithParams(params);
    stopwatch1.stop();

    expect(result1.length, 1000);

    final stopwatch2 = Stopwatch()..start();
    final result2 = world.queryWithParams(params);
    stopwatch2.stop();
    expect(result2.length, 1000);

    print('First query (with caching): ${stopwatch1.elapsedMicroseconds}μs');
    print('Second query (from cache): ${stopwatch2.elapsedMicroseconds}μs');
  });

  test('archetype count changes should invalidate query cache', () {
    final world = World();
    final params = QueryParams([PositionComponent]);
    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));
    final archetypeCount1 = world.archetypeCount;

    final result1 = world.queryWithParams(params);
    expect(result1.length, 1);

    final e2 = world.createEntity();
    world.addComponents(e2, components: [
      PositionComponent(x: 3, y: 4),
      ColorComponent(r: 1, g: 2, b: 3),
      VelocityComponent(dx: 0.5, dy: 0.6),
    ]);

    expect(world.archetypeCount, greaterThan(archetypeCount1));

    final result2 = world.queryWithParams(params);
    expect(result2.length, 2);
  });
  test('query should work correctly with single component type', () {
    final world = World();
    for (int i = 0; i < 5; i++) {
      final e = world.createEntity();
      world.addComponent(e, PositionComponent(x: i.toDouble(), y: i.toDouble()));
    }

    final rows = world.query([PositionComponent]);
    expect(rows.length, 5);

    for (int i = 0; i < rows.length; i++) {
      expect(rows[i].get<PositionComponent>().x, i.toDouble());
    }
  });
  test('query raw should return flat buffer in correct order', () {
    final world = World();
    final e1 = world.createEntity();
    world.addComponent(e1, PositionComponent(x: 1, y: 2));
    world.addComponent(e1, ColorComponent(r: 10, g: 20, b: 30));

    final e2 = world.createEntity();
    world.addComponent(e2, PositionComponent(x: 3, y: 4));
    world.addComponent(e2, ColorComponent(r: 40, g: 50, b: 60));

    final params = QueryParams([PositionComponent, ColorComponent]);
    final buffer = world.queryRaw(params);

    expect(buffer.length, 4);
    expect((buffer[0] as PositionComponent).x, 1);
    expect((buffer[1] as ColorComponent).r, 10);
    expect((buffer[2] as PositionComponent).x, 3);
    expect((buffer[3] as ColorComponent).r, 40);
  });
  test('component order in query should not affect results', () {
    final world = World();
    final e = world.createEntity();
    world.addComponent(e, PositionComponent(x: 1, y: 2));
    world.addComponent(e, ColorComponent(r: 3, g: 4, b: 5));
    world.addComponent(e, VelocityComponent(dx: 6, dy: 7));

    final rows1 = world.query([PositionComponent, ColorComponent, VelocityComponent]);
    final rows2 = world.query([VelocityComponent, PositionComponent, ColorComponent]);
    final rows3 = world.query([ColorComponent, VelocityComponent, PositionComponent]);

    expect(rows1.length, 1);
    expect(rows2.length, 1);
    expect(rows3.length, 1);

    expect(rows1.first.get<PositionComponent>().x, 1);
    expect(rows2.first.get<PositionComponent>().x, 1);
    expect(rows3.first.get<PositionComponent>().x, 1);

    expect(rows1.first.get<ColorComponent>().r, 3);
    expect(rows2.first.get<ColorComponent>().r, 3);
    expect(rows3.first.get<ColorComponent>().r, 3);
  });
}
