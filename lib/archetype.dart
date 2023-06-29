import 'package:tecs/bit_hash.dart';
import 'package:tecs/component.dart';

class Record {
  Record({
    required this.archetype,
    required this.entityRow,
  });
  final Archetype archetype;
  int entityRow;

  @override
  String toString() => 'Record(entityRow: $entityRow, archetype: $archetype)';
}

class Archetype {
  Archetype({
    required this.bitHash,
    required this.components,
  });

  final BitHash bitHash;

  /// component -> entity
  final List<List<Component>> components;

  bool get isEmpty => components[0].isEmpty;
  int get componentCount => components.length;
  int get entityCount => components[0].length;

  @override
  String toString() => 'Archetype(id: ${bitHash.value}, components: $components)';
}
