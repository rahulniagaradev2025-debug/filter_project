import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../../features/filters/data/models/filter_config_model.dart';
import '../../features/filters/domain/entities/filter_entity.dart';

class PayloadBuilder {
  /// Builds the 3 hardware configuration payloads according to the EXACT spec:
  /// Set 1 (ID 1): Method, Count, Filters 1-4
  /// Set 2 (ID 2): Filters 5-8, Off Time
  /// Set 3 (ID 3): Init Delay, Delay Btwn, DP Scan, DP After, DP Diff, Looping Limit
  static List<List<int>> buildConfigPayloads(FilterConfigModel config) {
    final allFilters = List<FilterEntity>.from(
      config.filters.take(AppConstants.maxFilterCount),
    );
    while (allFilters.length < AppConstants.maxFilterCount) {
      allFilters.add(const FilterEntity(hour: 0, minute: 0, second: 0));
    }

    final method = _methodToCode(config.method);
    final count = config.filterCount.clamp(0, AppConstants.maxFilterCount).toString();

    // Set 1: $:MsgLength:1:Method:Count:F1H:F1M:F1S:F2H:F2M:F2S:F3H:F3M:F3S:F4H:F4M:F4S:Crc:\r
    final data1 = [
      method,
      count,
      for (final filter in allFilters.sublist(0, 4))
        ..._timeToParts(filter),
    ];

    // Set 2: $:msgLength:2:F5H:F5M:F5S:F6H:F6M:F6S:F7H:F7M:F7S:F8H:F8M:F8S:OffH:OffM:OffS:crc:\r
    final data2 = [
      for (final filter in allFilters.sublist(4, 8))
        ..._timeToParts(filter),
      ..._timeToParts(config.offTime),
    ];

    // Set 3: $:msglength:3:InH:InM:InS:BtH:BtM:BtS:ScH:ScM:ScS:AfH:AfM:AfS:Diff:Loop:crc:\r
    final data3 = [
      ..._timeToParts(config.initialDelay),
      ..._timeToParts(config.delayBetween),
      ..._timeToParts(config.dpScanTime),
      ..._timeToParts(config.afterFilterDpScanTime),
      config.dpDifferenceValue.toStringAsFixed(0),
      config.loopingLimit.toString(),
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
    // Length is ID + Data + 4 ($, Len, CRC, :)
    final msgLength = allParts.length + 4;
    allParts.insert(0, msgLength.toString());
    return '\$:${allParts.join(':')}:';
  }

  static List<String> _timeToParts(FilterEntity time) {
    return [
      time.hour.toString().padLeft(2, '0'),
      time.minute.toString().padLeft(2, '0'),
      time.second.toString().padLeft(2, '0')
    ];
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
