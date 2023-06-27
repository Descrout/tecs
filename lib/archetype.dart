import 'package:tecs/component.dart';
import 'package:tecs/list_hash.dart';
import 'package:tecs/types.dart';

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
    required this.id,
    required this.listHash,
    required this.components,
  });

  final ArchetypeID id;
  final ListHash listHash;

  /// component -> entity
  final List<List<Component>> components;

  @override
  String toString() => 'Archetype(id: $id, listHash: $listHash, components: $components)';
}
