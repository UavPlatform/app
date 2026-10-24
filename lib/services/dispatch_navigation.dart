import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

// REQ-PILOT-EXEC-006: ground travel to saved Amap (GCJ-02) waybill points.
class DispatchNavigation {
  DispatchNavigation({Future<bool> Function(Uri)? launch})
    : _launch =
          launch ??
          ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));
  final Future<bool> Function(Uri) _launch;
  Future<bool> open(Map<String, dynamic> fields, String side) async {
    if (side != 'start' && side != 'end') return false;
    final rawLat = fields['$side.lat'];
    final rawLng = fields['$side.lng'];
    final lat = rawLat is String ? double.tryParse(rawLat) : null;
    final lng = rawLng is String ? double.tryParse(rawLng) : null;
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return false;
    }
    final label = side == 'start' ? '运单起点' : '运单终点';
    // No phone, contact, order ID or credentials go to the external map.
    final uri = Uri.https('uri.amap.com', '/navigation', {
      'from': '',
      'to': '$lng,$lat,$label',
      'mode': 'car',
      'src': 'feiyitong',
      'callnative': '1',
    });
    try {
      return await _launch(uri);
    } catch (_) {
      return false;
    }
  }
}

final dispatchNavigationProvider = Provider((ref) => DispatchNavigation());
