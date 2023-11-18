import 'package:tecs/component.dart';
import 'package:tecs/set_hash.dart';

class Record {
  Record({
    required this.archetype,
    required this.entityRow,
  });
  final Archetype archetype;
  int entityRow;
}

class Archetype {
  Archetype({
    required this.setHash,
    required this.components,
  });

  final SetHash setHash;

  // [componentIndex][entityIndex]
  final List<List<Component>> components;

  bool get isEmpty => components[0].isEmpty;
  int get componentCount => components.length;
  int get entityCount => components[0].length;
}
