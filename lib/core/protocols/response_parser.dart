import 'dart:convert';
import '../../features/filters/domain/entities/filter_entity.dart';
import '../../features/filters/data/models/filter_config_model.dart';

class ResponseParser {
  /// Parses the hardware response (JSON or Colon-separated) into a structured Map.
  static Map<String, dynamic>? parse(String response) {
    final cleanResponse = response.trim();
    if (cleanResponse.isEmpty) return null;

    // 1. Handle JSON Payloads
    if (cleanResponse.startsWith('{')) {
      try {
        final Map<String, dynamic> json = jsonDecode(cleanResponse);
        final mid = json['MID']?.toString();

        if (mid == '1' || mid == '4') {
          // Settings Configured or Settings Acknowledgement
          if (json.containsKey('FILCNT')) {
            return {
              'type': 'CONFIG_UPDATE',
              'payloadId': int.tryParse(mid!) ?? 1,
              'config': _parseJsonConfig(json),
            };
          } else if (json.containsKey('MESSAGE')) {
            return {
              'type': 'ACK',
              'payloadId': int.tryParse(mid!) ?? 1,
              'message': json['MESSAGE'],
            };
          }
        } else if (mid == '31' || mid == '5') {
          // Live Status Update
          return {
            'type': 'LIVE_STATUS',
            'payloadId': int.tryParse(mid!) ?? 5,
            'data': json,
          };
        }
      } catch (e) {
        return null;
      }
    }

    // 2. Handle Colon Protocol ($:Len:ID:Data...)
    if (cleanResponse.startsWith('\$')) {
      final parts = cleanResponse.split(':');
      if (parts.length < 4) return null;

      final payloadId = int.tryParse(parts[2]);
      if (payloadId != null && payloadId >= 1 && payloadId <= 4) {
        return {
          'type': 'CONFIG_UPDATE',
          'payloadId': payloadId,
          'config': _parseColonConfig(parts),
        };
      }
    }

    return null;
  }

  static FilterConfigModel _parseJsonConfig(Map<String, dynamic> json) {
    FilterEntity parseTime(String? timeStr) {
      if (timeStr == null || !timeStr.contains(':')) {
        return const FilterEntity(hour: 0, minute: 0, second: 0);
      }
      final parts = timeStr.split(':');
      return FilterEntity(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
        second: int.tryParse(parts[2]) ?? 0,
      );
    }

    final filters = <FilterEntity>[];
    for (int i = 1; i <= 8; i++) {
      filters.add(parseTime(json['FILON$i']?.toString()));
    }

    return FilterConfigModel(
      method: json['FILMETHOD'] == '1' ? 'DP' : (json['FILMETHOD'] == '2' ? 'Both' : 'Time'),
      filterCount: int.tryParse(json['FILCNT']?.toString() ?? '0') ?? 0,
      filters: filters,
      offTime: parseTime(json['FILOFF']?.toString()),
      initialDelay: parseTime(json['FILINIT']?.toString()),
      delayBetween: parseTime(json['FILDELAY']?.toString()),
      dpScanTime: parseTime(json['DPSCAN']?.toString()),
      afterFilterDpScanTime: parseTime(json['FILAFTER']?.toString()),
      dpDifferenceValue: double.tryParse(json['DPVALUE']?.toString() ?? '0') ?? 0,
    );
  }

  static FilterConfigModel _parseColonConfig(List<String> parts) {
    int getInt(int index) => (index < parts.length) ? (int.tryParse(parts[index]) ?? 0) : 0;

    FilterEntity parseFilter(int startIndex) {
      return FilterEntity(
        hour: getInt(startIndex),
        minute: getInt(startIndex + 1),
        second: getInt(startIndex + 2),
      );
    }

    return FilterConfigModel(
      method: parts[3] == '1' ? 'DP' : (parts[3] == '2' ? 'Both' : 'Time'),
      filterCount: getInt(4),
      filters: [parseFilter(5), parseFilter(8), parseFilter(11), parseFilter(14)],
      offTime: parseFilter(17),
      initialDelay: parseFilter(20),
      delayBetween: parseFilter(23),
      dpScanTime: parseFilter(26),
      afterFilterDpScanTime: parseFilter(29),
      dpDifferenceValue: (parts.length > 32) ? (double.tryParse(parts[32]) ?? 0) : 0,
    );
  }
}
