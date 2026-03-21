import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../features/filters/data/models/filter_config_model.dart';
import '../../features/filters/domain/entities/filter_entity.dart';

class PayloadBuilder {
  /// Builds the string-based payload for settings.
  /// Format: $:MsgLength:PayloadId:FilterMethod:FilterCount:F1H:F1M:F1S:...:Crc:\r
  static List<int> buildConfigPayload(FilterConfigModel config, {int payloadId = 1}) {
    List<String> parts = [];
    
    // 1. Filter Method (0: Time, 1: DP, 2: Both)
    int methodValue = 0;
    if (config.method == 'DP') methodValue = 1;
    if (config.method == 'Both') methodValue = 2;
    parts.add(methodValue.toString());

    // 2. Filter Count
    parts.add(config.filterCount.toString());

    // 3. Individual Filter ON Times (H, M, S for each)
    for (var filter in config.filters) {
      parts.addAll(_timeToParts(filter));
    }

    // 4. Additional Parameters (H, M, S for each)
    parts.addAll(_timeToParts(config.offTime));
    parts.addAll(_timeToParts(config.initialDelay));
    parts.addAll(_timeToParts(config.delayBetween));
    parts.addAll(_timeToParts(config.dpScanTime));
    parts.addAll(_timeToParts(config.afterFilterDpScanTime));

    // 5. DP Difference Value
    parts.add(config.dpDifferenceValue.toStringAsFixed(1));

    final payload = _assemblePayload(payloadId, parts);
    if (kDebugMode) {
      print('--- CONFIG PAYLOAD (ID: $payloadId) ---');
      print('String: ${utf8.decode(payload)}');
      print('Bytes: $payload');
      print('---------------------------------------');
    }
    return payload;
  }

  /// Format: $:MsgLength:PayloadId:Crc:\r
  static List<int> buildViewSettingsRequest() {
    final payload = _assemblePayload(4, []);
    if (kDebugMode) {
      print('--- VIEW SETTINGS REQUEST (ID: 4) ---');
      print('String: ${utf8.decode(payload)}');
      print('-------------------------------------');
    }
    return payload;
  }

  /// Format: $:MsgLength:PayloadId:Crc:\r
  static List<int> buildLiveRequest() {
    final payload = _assemblePayload(5, []);
    if (kDebugMode) {
      print('--- LIVE DATA REQUEST (ID: 5) ---');
      print('String: ${utf8.decode(payload)}');
      print('---------------------------------');
    }
    return payload;
  }

  static List<int> _assemblePayload(int payloadId, List<String> dataParts) {
    // Basic structure: [PayloadId, ...dataParts]
    List<String> allParts = [payloadId.toString(), ...dataParts];
    
    // Add MsgLength at the beginning (Length of all parts + CRC + MsgLength itself)
    int msgLength = allParts.length + 2;
    
    allParts.insert(0, msgLength.toString());

    // Calculate CRC (Simple sum of all numeric values in the string)
    int crc = _calculateCrc(allParts);
    allParts.add(crc.toString());

    // Join with colons and add delimiters
    String payloadStr = '\$:' + allParts.join(':') + ':\\r';
    return utf8.encode(payloadStr);
  }

  static List<String> _timeToParts(FilterEntity time) {
    return [time.hour.toString(), time.minute.toString(), time.second.toString()];
  }

  static int _calculateCrc(List<String> parts) {
    int sum = 0;
    for (var part in parts) {
      sum += (double.tryParse(part)?.toInt() ?? 0);
    }
    return sum % 256; 
  }

  static List<int> buildStartCommand() {
    final payload = _assemblePayload(6, ['0']); // Example ID 6 for Start
    if (kDebugMode) {
      print('--- START COMMAND (ID: 6) ---');
      print('String: ${utf8.decode(payload)}');
      print('-----------------------------');
    }
    return payload;
  }

  static List<int> buildStopCommand() {
    final payload = _assemblePayload(7, ['0']); // Example ID 7 for Stop
    if (kDebugMode) {
      print('--- STOP COMMAND (ID: 7) ---');
      print('String: ${utf8.decode(payload)}');
      print('----------------------------');
    }
    return payload;
  }
}
