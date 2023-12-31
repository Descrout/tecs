import 'package:tecs/component.dart';
import 'package:tecs/types.dart';

class QueryRow {
  final Map<Type, Component> _components;
  QueryRow(List<Component> components)
      : _components = {for (final e in components) e.runtimeType: e},
        entity = components.first.entityID;

  final EntityID entity;

  T get<T extends Component>() => _components[T]! as T;
}

class Query {
  Query({required this.rows});

  final Iterable<QueryRow> rows;
}
