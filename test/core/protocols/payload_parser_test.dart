import 'package:filter_project/core/protocols/payload_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PayloadParser', () {
    test('parses the hardware settings acknowledgement payload', () {
      const raw =
          '{"MID":"1","ACKID":"1\\","MESSAGE":"SET 1 RECEIVED","BOOT":"0"}';

      final parsed = PayloadParser.parseRaw(raw);

      expect(parsed['type'], 'settings_ack');
      expect(parsed['payloadId'], 1);
      expect(parsed['ack_id'], '1');
      expect(parsed['message'], 'SET 1 RECEIVED');
      expect(parsed['boot'], '0');
    });

    test('parses the hardware live payload and extracts active filter time', () {
      const raw =
          '{"MID":"31","L_MODE":"1","L_STATUS":"1","L_FILTER":"1,0,0,0,0,0,0,0","L_FILTERON1":"00:10:00/00:03:00","L_FILTEROFF":"00:00:00/00:00:00","BOOT":"0"}';

      final parsed = PayloadParser.parseRaw(raw);

      expect(parsed['type'], 'live');
      expect(parsed['payloadId'], 31);
      expect(parsed['mode'], 'Differential Pressure');
      expect(parsed['status'], 'ON');
      expect(parsed['current_filter'], 'Filter #1');
      expect(parsed['time'], '00:03:00');
    });
  });
}
