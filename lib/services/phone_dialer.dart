import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneDialer {
  PhoneDialer({Future<bool> Function(Uri)? launch})
    : _launch = launch ?? launchUrl;
  final Future<bool> Function(Uri) _launch;
  Future<bool> dial(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalized)) return false;
    try {
      return await _launch(Uri(scheme: 'tel', path: normalized));
    } catch (_) {
      return false;
    }
  }
}

final phoneDialerProvider = Provider((ref) => PhoneDialer());
