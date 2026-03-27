import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/filters/data/models/filter_config_model.dart';
import '../../features/filters/domain/entities/filter_entity.dart';

class PayloadBuilder {
  /// Builds 3 separate payloads for filter configuration (Set 1, 2, and 3).
  /// To ensure hardware response, all three payloads include the common settings
  /// to maintain a consistent message length and structure.
  static List<List<int>> buildConfigPayloads(FilterConfigModel config) {
    final allFilters = List<FilterEntity>.from(config.filters);
    // Support up to 12 filters (3 sets of 4)
    while (allFilters.length < 12) {
      allFilters.add(const FilterEntity(hour: 0, minute: 0, second: 0));
    }

    final method = _methodToCode(config.method);
    final count = config.filterCount.toString();

    // These common settings are appended to every config payload
    // to satisfy the hardware's expected fixed-length format.
    final commonSettings = [
      ..._timeToParts(config.offTime),
      ..._timeToParts(config.initialDelay),
      ..._timeToParts(config.delayBetween),
      ..._timeToParts(config.dpScanTime),
      ..._timeToParts(config.afterFilterDpScanTime),
      config.dpDifferenceValue.toStringAsFixed(0),
    ];

    // Set 1 (ID: 1): Filters 1-4 + Common Settings
    final data1 = [
      method,
      count,
      for (final filter in allFilters.sublist(0, 4)) ..._timeToParts(filter),
      ...commonSettings,
    ];

    // Set 2 (ID: 2): Filters 5-8 + Common Settings
    final data2 = [
      method,
      count,
      for (final filter in allFilters.sublist(4, 8)) ..._timeToParts(filter),
      ...commonSettings,
    ];

    // Set 3 (ID: 3): Filters 9-12 + Common Settings
    final data3 = [
      method,
      count,
      for (final filter in allFilters.sublist(8, 12)) ..._timeToParts(filter),
      ...commonSettings,
    ];

    return [
      _assemblePayload(1, data1),
      _assemblePayload(2, data2),
      _assemblePayload(3, data3),
    ];
  }

  /// Request View Settings (Payload ID 4)
  static List<int> buildViewSettingsRequest() => _assemblePayload(4, []);

  /// Request Live Update (Payload ID 5)
  static List<int> buildLiveRequest() => _assemblePayload(5, []);

  /// Start Filter Command (Payload ID 6)
  static List<int> buildStartCommand() => _assemblePayload(6, ['0']);

  /// Stop Filter Command (Payload ID 7)
  static List<int> buildStopCommand() => _assemblePayload(7, ['0']);

  static List<int> _assemblePayload(int payloadId, List<String> dataParts) {
    final payloadWithoutCrc = _buildPayloadWithoutCrc(payloadId, dataParts);
    final crc = _calculateCrc(payloadWithoutCrc);
    final payloadStr = '$payloadWithoutCrc$crc:\r';

    if (kDebugMode) {
      print('--- OUTGOING PAYLOAD (ID: $payloadId) ---');
      print('String: ${payloadStr.replaceAll('\r', r'\r')}');
    }

    return utf8.encode(payloadStr);
  }

  static String _buildPayloadWithoutCrc(int payloadId, List<String> dataParts) {
    final allParts = <String>[payloadId.toString(), ...dataParts];
    // MsgLength calculation: includes $, Len, ID, Data segments, CRC, and Trailer
    final msgLength = allParts.length + 4;
    allParts.insert(0, msgLength.toString());
    return '\$:${allParts.join(':')}:';
  }

  static List<String> _timeToParts(FilterEntity time) {
    return [time.hour.toString(), time.minute.toString(), time.second.toString()];
  }

  static String _methodToCode(String method) {
    switch (method) {
      case 'DP': return '1';
      case 'Both': return '2';
      default: return '0';
    }
  }

  static int _calculateCrc(String payloadWithoutCrc) {
    int sum = 0;
    for (int i = 0; i < payloadWithoutCrc.length; i++) {
      sum += payloadWithoutCrc.codeUnitAt(i);
    }
    return sum % 256;
  }
}
