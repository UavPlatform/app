import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String? getUserId(Map<String, dynamic> claims) {
    final v = claims['userId'];
    if (v == null) return null;
    return v.toString();
  }

  static String? getUserName(Map<String, dynamic> claims) {
    return claims['username']?.toString();
  }

  static int getRole(Map<String, dynamic> claims) {
    return (claims['role'] as num?)?.toInt() ?? 0;
  }
}
