import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/filters/data/models/filter_config_model.dart';
import '../../features/filters/domain/entities/filter_entity.dart';

class PayloadBuilder {
  /// Builds the string-based payloads for settings.
  /// Payload Id = 1, 2, 3 (For Set 1, 2, 3)
  /// Set 1: Filters 1-4
  /// Set 2: Filters 5-8
  /// Set 3: Common Parameters
  /// Format: $:MsgLength:PayloadId:FilterMethod:FilterCount:F1H:F1M:F1S:F2H:F2M:F2S:F3H:F3M:F3S:F4H:F4M:F4S:Crc:\r
  static List<List<int>> buildConfigPayloads(FilterConfigModel config) {
    // ID 1: Filters 1-4
    final set1 = _assemblePayload(1, [
      _methodToCode(config.method),
      config.filterCount.toString(),
      ..._timeToParts(config.filters.length > 0 ? config.filters[0] : const FilterEntity(hour: 0, minute: 0, second: 0)),
      ..._timeToParts(config.filters.length > 1 ? config.filters[1] : const FilterEntity(hour: 0, minute: 0, second: 0)),
      ..._timeToParts(config.filters.length > 2 ? config.filters[2] : const FilterEntity(hour: 0, minute: 0, second: 0)),
      ..._timeToParts(config.filters.length > 3 ? config.filters[3] : const FilterEntity(hour: 0, minute: 0, second: 0)),
    ]);

    // ID 2: Filters 5-8
    final set2 = _assemblePayload(2, [
      _methodToCode(config.method),
      config.filterCount.toString(),
      ..._timeToParts(config.filters.length > 4 ? config.filters[4] : const FilterEntity(hour: 0, minute: 0, second: 0)),
      ..._timeToParts(config.filters.length > 5 ? config.filters[5] : const FilterEntity(hour: 0, minute: 0, second: 0)),
      ..._timeToParts(config.filters.length > 6 ? config.filters[6] : const FilterEntity(hour: 0, minute: 0, second: 0)),
      ..._timeToParts(config.filters.length > 7 ? config.filters[7] : const FilterEntity(hour: 0, minute: 0, second: 0)),
    ]);

    // ID 3: Common Parameters (OffTime, InitialDelay, DelayBetween, DpScanTime)
    final set3 = _assemblePayload(3, [
      _methodToCode(config.method),
      config.filterCount.toString(),
      ..._timeToParts(config.offTime),
      ..._timeToParts(config.initialDelay),
      ..._timeToParts(config.delayBetween),
      ..._timeToParts(config.dpScanTime),
    ]);

    return [set1, set2, set3];
  }

  /// Request View Settings (ID 4)
  /// Result: $:5:4:59:\r
  static List<int> buildViewSettingsRequest() => _assemblePayload(4, []);

  /// Request Live Status (ID 5)
  /// Result: $:5:5:60:\r
  static List<int> buildLiveRequest() => _assemblePayload(5, []);

  static List<int> buildStartCommand() => _assemblePayload(6, ['0']);
  static List<int> buildStopCommand() => _assemblePayload(7, ['0']);

  /// Assembles segments into the final byte array.
  /// Format: $:Len:ID:Data:CRC:\r
  static List<int> _assemblePayload(int payloadId, List<String> dataParts) {
    List<String> allParts = [payloadId.toString(), ...dataParts];

    // msgLength is the segment count (including $, Len, ID, Data segments, CRC, and empty trailer)
    // For $:5:5:60:\r, colons split into: [$, 5, 5, 60, ""] -> 5 segments.
    // dataParts count + ID(1) + 4 extra ($ segment, Len segment, CRC segment, trailer segment)
    int msgLength = allParts.length + 4;
    allParts.insert(0, msgLength.toString());

    final payloadWithoutCrc = '\$:${allParts.join(':')}:';
    final crc = _calculateCrc(payloadWithoutCrc);
    
    final payloadStr = '$payloadWithoutCrc$crc:\r';

    if (kDebugMode) {
      print('--- OUTGOING PAYLOAD (ID: $payloadId) ---');
      print('String: ${payloadStr.replaceAll('\r', r'\r')}');
    }

    return utf8.encode(payloadStr);
  }

  static List<String> _timeToParts(FilterEntity time) {
    return [time.hour.toString(), time.minute.toString(), time.second.toString()];
  }

  static String _methodToCode(String method) {
    switch (method) {
      case 'DP':
        return '1';
      case 'Both':
        return '2';
      default:
        return '0'; // Time Based
    }
  }

  /// CRC is the sum of ASCII values of all characters modulo 256.
  static int _calculateCrc(String payloadWithoutCrc) {
    int sum = 0;
    for (final codeUnit in payloadWithoutCrc.codeUnits) {
      sum += codeUnit;
    }
    return sum % 256;
  }
}
