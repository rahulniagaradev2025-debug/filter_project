import 'dart:convert';

class PayloadParser {
  /// Parses incoming data based on Payload ID
  /// Format: $:MsgLength:PayloadId:Data1:Data2:...:Crc:\r
  static Map<String, dynamic> parse(List<int> data) {
    return parseRaw(utf8.decode(data));
  }

  /// Parses the raw string received from the hardware
  static Map<String, dynamic> parseRaw(String raw) {
    try {
      String decoded = raw.trim();
      
      // Remove start ($:) and end (:\r) delimiters
      // Handling both literal "\r" and character '\r'
      if (decoded.startsWith('\$:')) decoded = decoded.substring(2);
      if (decoded.endsWith(':\\r')) {
        decoded = decoded.substring(0, decoded.length - 3);
      } else if (decoded.endsWith(':\r')) {
        decoded = decoded.substring(0, decoded.length - 2);
      }

      List<String> parts = decoded.split(':');
      if (parts.length < 3) return {'type': 'unknown', 'raw': decoded};

      int payloadId = int.tryParse(parts[1]) ?? -1;

      switch (payloadId) {
        case 1:
        case 2:
        case 3:
        case 4:
          return {
            'type': 'settings',
            'payloadId': payloadId,
            'method': parts.length > 2 ? parts[2] : 'N/A',
            'count': parts.length > 3 ? parts[3] : 'N/A',
            'raw': decoded,
          };
        case 5:
          return {
            'type': 'live',
            'current_filter': parts.length > 2 ? parts[2] : 'N/A',
            'status': parts.length > 3 ? parts[3] : 'N/A',
            'time': parts.length > 6 ? '${parts[4]}:${parts[5]}:${parts[6]}' : '00:00:00',
            'raw': decoded,
          };
        default:
          return {'type': 'notification', 'raw': decoded};
      }
    } catch (e) {
      return {'type': 'error', 'message': e.toString()};
    }
  }
}
