import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Retain the same attempt across a lost response or process restart, scoped by server/account/drone.
class EquipmentRequestStore {
  EquipmentRequestStore(this.prefs);
  final SharedPreferences prefs;
  String _key(String scope, String drone) => 'equipment.borrow.$scope.$drone';
  String? saved(String scope, String drone) =>
      prefs.getString(_key(scope, drone));
  Future<String> requestKey(String scope, String drone) async {
    final key = _key(scope, drone);
    final previous = prefs.getString(key);
    if (previous != null && previous.isNotEmpty) return previous;
    final value = const Uuid().v4();
    if (!await prefs.setString(key, value)) throw StateError('借用标识保存失败，请重试');
    return value;
  }

  Future<void> clear(String scope, String drone, String expected) async {
    if (saved(scope, drone) != expected) return;
    if (!await prefs.remove(_key(scope, drone))) {
      throw StateError('借用标识清理失败，请重试');
    }
  }
}
