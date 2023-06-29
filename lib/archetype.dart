import 'package:tecs/component.dart';
import 'package:tecs/list_hash.dart';

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
    required this.listHash,
    required this.components,
  });

  final ListHash listHash;

  /// component -> entity
  final List<List<Component>> components;

  bool get isEmpty => components[0].isEmpty;
  int get componentCount => components.length;
  int get entityCount => components[0].length;

  @override
  String toString() => 'Archetype(id: ${listHash.value}, components: $components)';
}
