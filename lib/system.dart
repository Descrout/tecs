import 'package:tecs/world.dart';

abstract class System<T> {
  late final World world;
  late final String tag;
  void update(T args);
}
