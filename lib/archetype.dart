import 'package:tecs/component.dart';
import 'package:tecs/list_hash.dart';
import 'package:tecs/types.dart';

class Record {
  Record({
    required this.archetype,
    required this.entityRow,
  });
  Archetype archetype;
  int entityRow;
}

class Archetype {
  Archetype({
    required this.id,
    required this.type,
    required this.components,
  });

  final ArchetypeID id;
  final ListHash type;

  /// component -> entity
  final List<List<Component>> components;
}
