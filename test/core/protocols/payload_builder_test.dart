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

    test('builds a settings payload with protocol length 47 and valid CRC', () {
      const config = FilterConfigModel(
        method: 'Time',
        filterCount: 1,
        filters: [FilterEntity(hour: 1, minute: 12, second: 10)],
        offTime: FilterEntity(hour: 4, minute: 2, second: 2),
        initialDelay: FilterEntity(hour: 0, minute: 0, second: 5),
        delayBetween: FilterEntity(hour: 0, minute: 0, second: 0),
        dpScanTime: FilterEntity(hour: 29, minute: 0, second: 0),
        afterFilterDpScanTime: FilterEntity(hour: 0, minute: 12, second: 0),
        dpDifferenceValue: 6,
      );

      final payload = utf8.decode(
        PayloadBuilder.buildConfigPayloads(config).single,
      );

      expect(payload.startsWith('\$:47:1:'), isTrue);
      expect(payload.endsWith(':\r'), isTrue);

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
    });
  });
}
