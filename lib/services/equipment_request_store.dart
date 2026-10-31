import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 按服务器/账号/机型保留同一次申请的 requestKey，避免丢响应后重复提交。
class EquipmentRequestStore {
  EquipmentRequestStore(this.prefs);
  final SharedPreferences prefs;
  String _key(String scope, String subject) => 'equipment.borrow.$scope.$subject';
  String? saved(String scope, String subject) =>
      prefs.getString(_key(scope, subject));
  Future<String> requestKey(String scope, String subject) async {
    final key = _key(scope, subject);
    final previous = prefs.getString(key);
    if (previous != null && previous.isNotEmpty) return previous;
    final value = const Uuid().v4();
    if (!await prefs.setString(key, value)) throw StateError('申请标识保存失败，请重试');
    return value;
  }

  Future<void> clear(String scope, String subject, String expected) async {
    if (saved(scope, subject) != expected) return;
    if (!await prefs.remove(_key(scope, subject))) {
      throw StateError('申请标识清理失败，请重试');
    }
  }
}
