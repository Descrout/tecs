# TECS

Simple archetype based ECS written in dart.  
Made for learning purposes so keep that in mind before using it.  
Any improvements or suggestions are welcome.

## World
```dart
import 'package:tecs/tecs.dart';

// Create a World
final world = World();

// Reset and Clear the World
world.clear();
```
## Entities
```dart
// Create Entities
final entity1 = world.createEntity();
final entity2 = world.createEntity();

// Remove Entities
world.removeEntity(entity1); // returns true
world.removeEntity(entity2); // returns true
world.removeEntity(entity1); // returns false, entity1 is not alive
```
```dart
// Check Entity Status
final entity1Status = world.isAlive(entity1);
if(entity1Status) {
  print("entity1 is alive");
} else {
  print("entity1 is dead");
}
```
```dart
// Create entities in bulk
final entityIDs = world.createEntities([
	[NameComponent(name: "Entity1"), PositionComponent(x:  10.0, y:  20.0)],
	[NameComponent(name: "Entity2"), PositionComponent(x:  30.0, y:  40.0)],
	[NameComponent(name: "Entity3"), PositionComponent(x:  50.0, y:  60.0)],
]);
print(entityIDs.length); // 3
```
## Components
```dart
class PositionComponent extends Component {
  PositionComponent({
    required this.x,
    required this.y,
  });

  double x;
  double y;
}
```
```dart
class VelocityComponent extends Component {
  VelocityComponent({
    required this.x,
    required this.y,
  });

  double x;
  double y;
}
```
```dart
// Add a component to an entity
world.addComponent(entity1, PositionComponent(x: 150, y: 150));
world.addComponent(entity1, VelocityComponent(x: -800, y: 400));

// Add components to an entity in bulk
world.addComponents(entity1, components: [
  PositionComponent(x: 150, y: 150),
  VelocityComponent(x: -800, y: 400),
]);
```
```dart
// Get component of an entity (returns null if the entity does not have the component)
final position = world.getComponent<PositionComponent>(entity1);
final velocity = world.getComponent<VelocityComponent>(entity1);
```
```dart
// Remove a component
world.removeComponent<PositionComponent>(entity1);
world.removeComponent<VelocityComponent>(entity1);

// Remove components in bulk
world.removeComponents(entity1, components: [
  PositionComponent,
  VelocityComponent,
]);
```
## Queries
#### Simple query (one-off usage)
```dart
final queryResult = world.query([PositionComponent, VelocityComponent]);

for (final row in queryResult) {
    final position = row.get<PositionComponent>();
    final velocity = row.get<VelocityComponent>();

    position.x += velocity.x;
    position.y += velocity.y;
}
```
#### Optimized query with cached parameters (recommended for systems)
```dart
// Create query parameters once and cache them.
// This should be done during system initialization.
final params = QueryParams([
  PositionComponent,
  VelocityComponent,
]);

for (int i = 0; i < 1000; i++) { // e.g. inside an update() loop
  final queryResult = world.queryWithParams(params);

  for (final row in queryResult) {
    final position = row.get<PositionComponent>();
    final velocity = row.get<VelocityComponent>();

    position.x += velocity.x;
    position.y += velocity.y;
  }
}
```
## Resources
```dart
class GameTime {
    double seconds = 0;
}

// Add Resource
world.addResource(GameTime());

// Get Resource and Manipulate
final gameTime = world.getResource<GameTime>();
gameTime.seconds += 1;

// If you add same resource, it will replace the old one
world.addResource(GameTime()); // replace the old GameTime

// You can give tags to add the same resource type without replacing
world.addResource(GameTime(), tag: "menu");
final gameTime = world.getResource<GameTime>();
final gameTimeMenu = world.getResource<GameTime>(tag: "menu");

// Remove resource
world.removeResource<GameTime>(); // returns GameTime if the resource exists, null otherwise
world.removeResource<GameTime>(tag: "menu");
```
## Systems
```dart
// extending with System<T> you can change the type of argument the update function will take.
class MoveSystem extends System<double> {
  @override
  void update(double deltaTime) {
    // has access to the world
    final queryResult = world.query([PositionComponent, VelocityComponent]);

    for (final row in queryResult) {
        final position = row.get<PositionComponent>();
        final velocity = row.get<VelocityComponent>();

        position.x += velocity.x * deltaTime;
        position.y += velocity.y * deltaTime;
    }
  }
}
```
```dart
// You can also override the init function and cache the params beforehand
class MoveSystem extends System<double> {
  final params = QueryParams([PositionComponent, VelocityComponent]);
  late final Inputs inputs;

  // Will be called once. (When this system is added to the world)
  @override
  void init() {
    inputs = world.getResource<Inputs>()!;
  }

  @override
  void update(double deltaTime) {
    final queryResult = world.queryWithParams(params);

    for (final row in queryResult) {
        final position = row.get<PositionComponent>();
        final velocity = row.get<VelocityComponent>();

        position.x += velocity.x * deltaTime;
        position.y += velocity.y * deltaTime;

        // use inputs.mouse.X etc
    }
  }
}
```
```dart
// Add a system
world.addSystem(MoveSystem());
```

```dart
// Update all systems sequantially (add order matters)

// A game loop that provides 'double deltaTime'
world.update(deltaTime);
// A game loop that provides 'double deltaTime'
```
## System Tags
```dart
// You can give tags to your systems to update differently and pass different arguments.
// You can use the new records capability dart3 provides to accept multiple arguments
class RenderSystem extends System<({Canvas canvas, Size size})> {
  @override
  void update(args) {
    final queryResult = world.query([RectComponent, ColorComponent]);

    for (final row in queryResult) {
        final rect = row.get<RectComponent>();
        final color = row.get<ColorComponent>();

        final paint = Paint()
            ..color = color.value
            ..style = PaintingStyle.fill;

        args.canvas.drawRect(rect.value, paint);
    }
  }
}
```
```dart
// Add the system with tag
world.addSystem(MoveSystem()); // default
world.addSystem(CollisionSystem()); // default

world.addSystem(RenderSystem(), tag: "render");
world.addSystem(RenderCollidersDebug(), tag: "render");
```
```dart
// A game loop that provides 'double deltaTime'
world.update(deltaTime); // MoveSystem and CollisionSystem will run
// A game loop that provides 'double deltaTime'

// A render loop that provides canvas and size
world.update(canvas, size, tag: "render"); // RenderSystem and RenderCollidersDebug will run
// A render loop that provides canvas and size
```