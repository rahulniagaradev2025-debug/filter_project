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
      final cleaned = raw.trim();
      if (cleaned.isEmpty) {
        return {'type': 'unknown', 'raw': raw, 'error': 'Empty Payload'};
      }

      if (cleaned.startsWith('{')) {
        return _parseJsonPayload(cleaned, raw);
      }

      if (!cleaned.startsWith('\$:')) {
        return {'type': 'unknown', 'raw': cleaned, 'error': 'Invalid Header'};
      }

      final content = cleaned.substring(2);
      final parts = content.split(':');
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

  static Map<String, dynamic> _parseJsonPayload(String cleaned, String raw) {
    final normalized = _normalizeLooseJson(cleaned);
    final payload = _decodeJsonMap(normalized) ?? _decodeKeyValuePairs(normalized);

    if (payload == null || payload.isEmpty) {
      return {
        'type': 'unknown',
        'raw': raw,
        'error': 'Could not parse JSON payload',
      };
    }

    if (payload.containsKey('ACKID')) {
      return {
        'type': 'settings_ack',
        'payloadId': _parseInt(payload['MID']),
        'ack_id': payload['ACKID']?.toString().replaceAll('\\', '').replaceAll('"', ''),
        'message': payload['MESSAGE']?.toString() ?? '',
        'boot': payload['BOOT']?.toString() ?? '0',
        'details': payload,
        'raw': raw,
      };
    }

    if (payload.containsKey('FILCNT') || payload.containsKey('FILMETHOD')) {
      return _parseSettingsJson(payload, raw);
    }

    if (payload.containsKey('L_STATUS') || payload['MID']?.toString() == '31') {
      return _parseLiveJson(payload, raw);
    }

    return {
      'type': 'json',
      'details': payload,
      'raw': raw,
    };
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

  static Map<String, dynamic> _parseSettingsJson(
    Map<String, dynamic> payload,
    String raw,
  ) {
    final filters = <String>[];
    for (var i = 1; i <= 8; i++) {
      final value = payload['FILON$i']?.toString();
      if (value != null && value.isNotEmpty) {
        filters.add(value);
      }
    }

    return {
      'type': 'settings',
      'payloadId': _parseInt(payload['MID']),
      'ack': payload['ACK']?.toString(),
      'message': payload['MESSAGE']?.toString() ?? '',
      'config': payload['CONFIG']?.toString() ?? '0',
      'method': _getMethodName(payload['FILMETHOD']?.toString() ?? '0'),
      'count': payload['FILCNT']?.toString() ?? '0',
      'filters': filters,
      'details': payload,
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

  static Map<String, dynamic> _parseLiveJson(
    Map<String, dynamic> payload,
    String raw,
  ) {
    final activeFilters = _parseActiveFilters(payload['L_FILTER']?.toString() ?? '');
    final currentFilter = activeFilters.isNotEmpty
        ? 'Filter #${activeFilters.first}'
        : 'N/A';
    final remainingTime = _extractRelevantLiveTime(payload, activeFilters);

    return {
      'type': 'live',
      'payloadId': _parseInt(payload['MID']),
      'mode': _getMethodName(payload['L_MODE']?.toString() ?? '0'),
      'status': _getLiveStatusName(payload['L_STATUS']?.toString() ?? '0'),
      'current_filter': currentFilter,
      'active_filters': activeFilters,
      'time': remainingTime,
      'details': payload,
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

  static Map<String, dynamic>? _decodeJsonMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic>? _decodeKeyValuePairs(String raw) {
    final matches = RegExp(r'"([^"]+)"\s*:\s*"([^"]*)"').allMatches(raw);
    if (matches.isEmpty) {
      return null;
    }

    final result = <String, dynamic>{};
    for (final match in matches) {
      result[match.group(1)!] = match.group(2)!;
    }
    return result;
  }

  static String _normalizeLooseJson(String raw) {
    return raw.replaceAll(
      RegExp(r'\\(?="\s*[,}])'),
      '',
    );
  }

  static int _parseInt(dynamic value, {int fallback = -1}) {
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<int> _parseActiveFilters(String csv) {
    final flags = csv.split(',').map((value) => int.tryParse(value.trim()) ?? 0).toList();
    final active = <int>[];
    for (var i = 0; i < flags.length; i++) {
      if (flags[i] == 1) {
        active.add(i + 1);
      }
    }
    return active;
  }

  static String _extractRelevantLiveTime(
    Map<String, dynamic> payload,
    List<int> activeFilters,
  ) {
    if (activeFilters.isNotEmpty) {
      final value = payload['L_FILTERON${activeFilters.first}']?.toString() ?? '';
      return _extractRemainingTime(value);
    }

    return _extractRemainingTime(
      payload['L_FILTEROFF']?.toString() ?? '00:00:00/00:00:00',
    );
  }

  static String _extractRemainingTime(String value) {
    final parts = value.split('/');
    if (parts.length == 2) {
      return parts.last.trim();
    }
    return value.isEmpty ? '00:00:00' : value;
  }

  static String _getMethodName(String val) {
    switch (val) {
      case '1': return 'Differential Pressure';
      case '2': return 'Both (Time & DP)';
      default: return 'Time Based';
    }
  }

  static String _getLiveStatusName(String val) {
    switch (val) {
      case '1':
        return 'ON';
      case '2':
        return 'WAIT';
      default:
        return 'OFF';
    }
  }
}
