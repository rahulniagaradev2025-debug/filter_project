import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../../features/filters/data/models/filter_config_model.dart';
import '../../features/filters/domain/entities/filter_entity.dart';

class PayloadBuilder {
  /// Builds the string-based payload for settings.
  /// Format: $:MsgLength:PayloadId:FilterMethod:FilterCount:F1H:F1M:F1S:...:F4H:F4M:F4S:Crc:\r
  static List<List<int>> buildConfigPayloads(FilterConfigModel config) {
    final totalPayloads =
        (config.filterCount / AppConstants.filtersPerPayload).ceil();
    final payloadCount = totalPayloads
        .clamp(1, AppConstants.maxSettingsPayloadCount)
        .toInt();
    return List.generate(payloadCount, (payloadIndex) {
      final startIndex = payloadIndex * AppConstants.filtersPerPayload;
      final filtersForPayload = <FilterEntity>[
        ...config.filters.skip(startIndex).take(AppConstants.filtersPerPayload),
      ];

      while (filtersForPayload.length < AppConstants.filtersPerPayload) {
        filtersForPayload.add(
          const FilterEntity(hour: 0, minute: 0, second: 0),
        );
      }

      final parts = <String>[
        _methodToCode(config.method),
        config.filterCount.toString(),
        for (final filter in filtersForPayload) ..._timeToParts(filter),
      ];

      return _assemblePayload(payloadIndex + 1, parts);
    });
  }

  static List<int> buildViewSettingsRequest() => _assemblePayload(4, []);
  static List<int> buildLiveRequest() => _assemblePayload(5, []);
  static List<int> buildStartCommand() => _assemblePayload(6, ['0']);
  static List<int> buildStopCommand() => _assemblePayload(7, ['0']);

  /// Assembles the parts into the final byte array with correct terminator
  static List<int> _assemblePayload(int payloadId, List<String> dataParts) {
    List<String> allParts = [payloadId.toString(), ...dataParts];

    // MsgLength = ID + DataFields + CRC + LengthField itself
    int msgLength = allParts.length + 2;
    allParts.insert(0, msgLength.toString());

    int crc = _calculateCrc(allParts);
    allParts.add(crc.toString());

    // RESTORE PREVIOUS WORKING FORMAT
    // Build the string with colons and append \r exactly as it was yesterday
    String payloadStr = '\$:${allParts.join(':')}:\r';

    if (kDebugMode) {
      print('--- CONFIG PAYLOAD (ID: $payloadId) ---');
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
        return '0';
    }
  }

  static int _calculateCrc(List<String> parts) {
    int sum = 0;
    for (var part in parts) {
      sum += (double.tryParse(part)?.toInt() ?? 0);
    }
    return sum % 256;
  }
}
