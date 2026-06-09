# TECS

[![pub.dev](https://img.shields.io/pub/v/tecs)](https://pub.dev/packages/tecs)
[![GitHub](https://img.shields.io/badge/github-Descrout/tecs-8da0cb)](https://github.com/Descrout/tecs)

An archetype-based Entity Component System (ECS) written in Dart.


📖 **[Documentation](https://tremble-ecs.netlify.app/)**

```dart
class MoveSystem extends System<double> {
  final params = QueryParams([PositionComponent, VelocityComponent]);

  @override
  void update(double deltaTime) {
    world.queryEach(params, (row) {
      final position = row.get<PositionComponent>();
      final velocity = row.get<VelocityComponent>();

      position.x += velocity.x * deltaTime;
      position.y += velocity.y * deltaTime;
    });
  }
}
```

---

### 🚀 Made with TECS

**[LunaPulse](https://descrout.itch.io/lunapulse)** — A space shmup built with TECS + [Tremble](https://pub.dev/packages/tremble).