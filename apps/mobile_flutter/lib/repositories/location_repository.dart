import 'package:hive/hive.dart';
import '../models/location.dart';

class LocationRepository {
  final Box<Location> _box;

  LocationRepository(this._box);

  List<Location> getAll() {
    return _box.values.toList();
  }

  Future<void> add(Location location) async {
    await _box.put(location.id, location);
  }

  Future<void> update(Location location) async {
    await _box.put(location.id, location);
  }

  Future<void> delete(Location location) async {
    await _box.delete(location.id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> close() async {
    await _box.close();
  }
}
