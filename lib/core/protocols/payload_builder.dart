import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../../features/filters/data/models/filter_config_model.dart';
import '../../features/filters/domain/entities/filter_entity.dart';

class PayloadBuilder {
  /// Builds the 3 hardware configuration payloads:
  /// 1. Filters 1-4
  /// 2. Filters 5-8
  /// 3. Common timing / DP settings
  static List<List<int>> buildConfigPayloads(FilterConfigModel config) {
    final allFilters = List<FilterEntity>.from(
      config.filters.take(AppConstants.maxFilterCount),
    );
    while (allFilters.length < AppConstants.maxFilterCount) {
      allFilters.add(const FilterEntity(hour: 0, minute: 0, second: 0));
    }

    final method = _methodToCode(config.method);
    final safeCount = config.filterCount.clamp(0, AppConstants.maxFilterCount);
    final count = safeCount.toString();

    final data1 = [
      method,
      count,
      for (final filter in allFilters.sublist(0, AppConstants.filtersPerPayload))
        ..._timeToParts(filter),
    ];

    final data2 = [
      method,
      count,
      for (final filter in allFilters.sublist(
        AppConstants.filtersPerPayload,
        AppConstants.maxFilterCount,
      ))
        ..._timeToParts(filter),
    ];

    final data3 = [
      method,
      count,
      ..._timeToParts(config.offTime),
      ..._timeToParts(config.initialDelay),
      ..._timeToParts(config.delayBetween),
      ..._timeToParts(config.dpScanTime),
      ..._timeToParts(config.afterFilterDpScanTime),
      config.dpDifferenceValue.toStringAsFixed(0),
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
    final payloadStr = '$payloadWithoutCrc$crc:\r\n';

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
