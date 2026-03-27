import 'dart:convert';

import 'package:filter_project/core/protocols/payload_builder.dart';
import 'package:filter_project/features/filters/data/models/filter_config_model.dart';
import 'package:filter_project/features/filters/domain/entities/filter_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadBuilder', () {
    test('builds the known live request payload with matching CRC', () {
      final payload = utf8.decode(PayloadBuilder.buildLiveRequest());

      expect(payload, '\$:5:5:60:\r');
    });

    test('builds the 3 settings payloads expected by the 8-filter protocol', () {
      const config = FilterConfigModel(
        method: 'Both',
        filterCount: 6,
        filters: [
          FilterEntity(hour: 1, minute: 1, second: 1),
          FilterEntity(hour: 2, minute: 2, second: 2),
          FilterEntity(hour: 3, minute: 3, second: 3),
          FilterEntity(hour: 4, minute: 4, second: 4),
          FilterEntity(hour: 5, minute: 5, second: 5),
          FilterEntity(hour: 6, minute: 6, second: 6),
        ],
        offTime: FilterEntity(hour: 7, minute: 7, second: 7),
        initialDelay: FilterEntity(hour: 8, minute: 8, second: 8),
        delayBetween: FilterEntity(hour: 9, minute: 9, second: 9),
        dpScanTime: FilterEntity(hour: 10, minute: 10, second: 10),
        afterFilterDpScanTime: FilterEntity(hour: 11, minute: 11, second: 11),
        dpDifferenceValue: 12,
      );

      final payloads =
          PayloadBuilder.buildConfigPayloads(config).map(utf8.decode).toList();

      expect(payloads, hasLength(3));
      expect(
        payloads[0],
        startsWith('\$:19:1:2:6:1:1:1:2:2:2:3:3:3:4:4:4:'),
      );
      expect(
        payloads[1],
        startsWith('\$:19:2:2:6:5:5:5:6:6:6:0:0:0:0:0:0:'),
      );
      expect(
        payloads[2],
        startsWith('\$:23:3:2:6:7:7:7:8:8:8:9:9:9:10:10:10:11:11:11:12:'),
      );

      for (final payload in payloads) {
        expect(payload.endsWith(':\r'), isTrue);
        _expectValidCrc(payload);
      }
    });
  });
}

void _expectValidCrc(String payload) {
  final lastColonIndex = payload.lastIndexOf(':', payload.length - 3);
  final crcSource = payload.substring(0, lastColonIndex + 1);
  final crcValue = int.parse(
    payload.substring(lastColonIndex + 1, payload.length - 2),
  );

  final expectedCrc = ascii.encode(crcSource).fold<int>(
        0,
        (sum, byte) => sum + byte,
      ) %
      256;

  expect(crcValue, expectedCrc);
}
