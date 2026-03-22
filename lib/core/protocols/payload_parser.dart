import 'dart:convert';

class PayloadParser {
  /// Entry point for parsing byte arrays from BLE notifications
  static Map<String, dynamic> parse(List<int> data) {
    // Standard hardware sends ASCII/UTF8 strings
    String rawString = utf8.decode(data, allowMalformed: true);
    return parseRaw(rawString);
  }

  /// The actual parsing logic for strings like $:MsgLength:PayloadId:Data...:Crc:\r
  static Map<String, dynamic> parseRaw(String raw) {
    try {
      // 1. Clean the string: Remove whitespace and the carriage return byte (13)
      String cleaned = raw.trim();
      
      // 2. Protocol Validation: Must start with $:
      if (!cleaned.startsWith('\$:')) {
        return {'type': 'unknown', 'raw': cleaned, 'error': 'Invalid Header'};
      }

      // 3. Remove start ($:) and end terminator (trailing colon and \r)
      // We look for parts between $: and the last :
      String content = cleaned.substring(2);
      if (content.endsWith('\r')) {
        content = content.substring(0, content.length - 1);
      }
      
      List<String> parts = content.split(':');
      
      // Basic structure check: [MsgLength, PayloadId, ...Data..., CRC]
      if (parts.length < 3) {
        return {'type': 'unknown', 'raw': cleaned, 'error': 'Insufficient Fields'};
      }

      int payloadId = int.tryParse(parts[1]) ?? -1;

      switch (payloadId) {
        case 1:
        case 2:
        case 3:
        case 4: // Hardware Settings response
          return _parseSettings(payloadId, parts, cleaned);
        case 5: // Live status update response
          return _parseLiveStatus(parts, cleaned);
        default:
          return {'type': 'other', 'payloadId': payloadId, 'raw': cleaned};
      }
    } catch (e) {
      return {'type': 'error', 'message': e.toString(), 'raw': raw};
    }
  }

  /// Parses settings data (ID 1-4)
  static Map<String, dynamic> _parseSettings(int id, List<String> parts, String raw) {
    final filterTimes = <String>[];
    final dataEndIndex = parts.length - 1;
    for (var i = 4; i + 2 < dataEndIndex; i += 3) {
      final h = parts[i].padLeft(2, '0');
      final m = parts[i + 1].padLeft(2, '0');
      final s = parts[i + 2].padLeft(2, '0');
      filterTimes.add('$h:$m:$s');
    }

    return {
      'type': 'settings',
      'payloadId': id,
      'set': id,
      'method': _getMethodName(parts.length > 2 ? parts[2] : '0'),
      'count': parts.length > 3 ? parts[3] : '0',
      'filters': filterTimes,
      'raw': raw,
    };
  }

  /// Parses live status data (ID 5)
  /// Expected: $:Len:5:FilterNum:Status:H:M:S:Crc:\r
  static Map<String, dynamic> _parseLiveStatus(List<String> parts, String raw) {
    return {
      'type': 'live',
      'current_filter': parts.length > 2 ? 'Filter #${parts[2]}' : 'N/A',
      'status': parts.length > 3 ? (parts[3] == '1' ? 'ON' : 'OFF') : 'OFF',
      'time': _formatTime(parts),
      'raw': raw,
    };
  }

  static String _formatTime(List<String> parts) {
    if (parts.length >= 7) {
      String h = parts[4].padLeft(2, '0');
      String m = parts[5].padLeft(2, '0');
      String s = parts[6].padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '00:00:00';
  }

  static String _getMethodName(String val) {
    switch (val) {
      case '1': return 'Differential Pressure';
      case '2': return 'Both (Time & DP)';
      default: return 'Time Based';
    }
  }
}
