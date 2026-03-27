import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:filter_project/core/utils/constants.dart';

class AppBluetoothService {
  Stream<List<fbp.ScanResult>> get scanResults => fbp.FlutterBluePlus.scanResults;
  
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  final List<StreamSubscription> _notifySubscriptions = [];
  String _receiveBuffer = '';

  // Global history of logs
  final List<LogEntry> _logHistory = [];
  List<LogEntry> get logHistory => List.unmodifiable(_logHistory);

  // Global stream for all data (Sent and Received)
  final _dataLogController = StreamController<LogEntry>.broadcast();
  Stream<LogEntry> get dataLogStream => _dataLogController.stream;

  // Stable notifications stream for the parser and UI listeners
  final _notificationController = StreamController<List<int>>.broadcast();

  Future<void> startScan() async {
    if (await fbp.FlutterBluePlus.adapterState.first != fbp.BluetoothAdapterState.on) {
      throw Exception("Bluetooth is off");
    }

    if (await fbp.FlutterBluePlus.isScanningNow == false) {
      await fbp.FlutterBluePlus.startScan(
        timeout: Duration(seconds: AppConstants.bluetoothScanTimeout),
        androidUsesFineLocation: false,
      );
    }
  }

  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  Future<void> connect(fbp.BluetoothDevice device) async {
    if (_connectedDevice != null && _connectedDevice!.remoteId != device.remoteId) {
      await disconnect();
    }

    try {
      await device.connect(
        timeout: const Duration(seconds: 15), 
        autoConnect: false,
      );
      
      _connectedDevice = device;
      
      device.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.disconnected) {
          _cleanupConnection();
        }
      });

      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint("MTU Request failed: $e");
        }
      }
      
      List<fbp.BluetoothService> services = await device.discoverServices();

      // 🔥 SELECT WRITE & NOTIFY CHARACTERISTICS
      _writeCharacteristic = _selectWriteChar(services);
      final notifyChars = _selectAllNotifyChars(services);

      if (_writeCharacteristic == null) {
        debugPrint("Warning: No preferred write characteristic found, using fallback.");
        _writeCharacteristic = _selectFallbackWriteChar(services);
      }

      // Step 1: Attach listeners to all notify characteristics
      for (final characteristic in notifyChars) {
        final sub = characteristic.onValueReceived.listen((data) {
          if (data.isEmpty) return;

          _receiveBuffer += utf8.decode(data, allowMalformed: true);

          for (final payload in _extractIncomingPayloads()) {
            _emitIncomingPayload(payload);
          }
        });
        _notifySubscriptions.add(sub);
      }

      // Step 2: Enable notifications
      for (final characteristic in notifyChars) {
        try {
          await characteristic.setNotifyValue(true);
          debugPrint('Notifications enabled for: ${characteristic.uuid}');
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (e) {
          debugPrint('Failed to enable notify for ${characteristic.uuid}: $e');
        }
      }

    } catch (e) {
      await device.disconnect();
      _cleanupConnection();
      rethrow;
    }
  }

  void _cleanupConnection() {
    for (final sub in _notifySubscriptions) {
      sub.cancel();
    }
    _notifySubscriptions.clear();
    _connectedDevice = null;
    _writeCharacteristic = null;
    _receiveBuffer = '';
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _cleanupConnection();
  }

  Future<void> writeData(List<int> data) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw Exception("Device not connected or not ready.");
    }

    final writeWithoutResponse =
        !characteristic.properties.write &&
        characteristic.properties.writeWithoutResponse;

    final chunks = _splitIntoChunks(data, AppConstants.bleWriteChunkSize);

    for (var i = 0; i < chunks.length; i++) {
      await characteristic.write(
        chunks[i],
        withoutResponse: writeWithoutResponse,
      );

      if (i < chunks.length - 1) {
        await Future.delayed(
          const Duration(milliseconds: AppConstants.bleWriteChunkDelayMs),
        );
      }
    }

    final text = utf8.decode(data, allowMalformed: true);
    debugPrint(
      'BLE TX (${chunks.length} chunk${chunks.length == 1 ? '' : 's'}): '
      '${text.replaceAll('\r', r'\r').replaceAll('\n', r'\n')}',
    );

    final entry = LogEntry(text: text, isResponse: false);
    _logHistory.add(entry);
    _dataLogController.add(entry);
  }

  Stream<List<int>> subscribeToNotifications() {
    return _notificationController.stream;
  }

  void clearLogs() {
    _logHistory.clear();
  }

  fbp.BluetoothCharacteristic? _selectWriteChar(List<fbp.BluetoothService> services) {
    final writeUuid = AppConstants.preferredBleWriteCharacteristicUuid.toLowerCase();
    final termUuid = AppConstants.terminalWriteUuid.toLowerCase();

    for (var s in services) {
      for (var c in s.characteristics) {
        final uuid = c.uuid.toString().toLowerCase();
        if (uuid == writeUuid || uuid == termUuid) {
          return c;
        }
      }
    }
    return null;
  }

  fbp.BluetoothCharacteristic? _selectFallbackWriteChar(List<fbp.BluetoothService> services) {
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.properties.write || c.properties.writeWithoutResponse) return c;
      }
    }
    return null;
  }

  List<fbp.BluetoothCharacteristic> _selectAllNotifyChars(List<fbp.BluetoothService> services) {
    final preferredNotifyUuid =
        AppConstants.preferredBleNotifyCharacteristicUuid.toLowerCase();
    final terminalNotifyUuid = AppConstants.terminalNotifyUuid.toLowerCase();

    final preferred = <fbp.BluetoothCharacteristic>[];
    final fallback = <fbp.BluetoothCharacteristic>[];

    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.properties.notify || c.properties.indicate) {
          final uuid = c.uuid.toString().toLowerCase();
          if (uuid == preferredNotifyUuid || uuid == terminalNotifyUuid) {
            preferred.add(c);
          } else {
            fallback.add(c);
          }
        }
      }
    }

    return preferred.isNotEmpty ? preferred : fallback;
  }

  List<List<int>> _splitIntoChunks(List<int> data, int chunkSize) {
    if (data.length <= chunkSize) {
      return [data];
    }

    final chunks = <List<int>>[];
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  List<String> _extractIncomingPayloads() {
    final payloads = <String>[];
    _receiveBuffer = _receiveBuffer.trimLeft();

    while (_receiveBuffer.isNotEmpty) {
      if (_receiveBuffer.startsWith('{')) {
        final endIndex = _findJsonPayloadEnd(_receiveBuffer);
        if (endIndex == -1) {
          break;
        }

        payloads.add(_receiveBuffer.substring(0, endIndex + 1));
        _receiveBuffer = _receiveBuffer.substring(endIndex + 1).trimLeft();
        continue;
      }

      if (_receiveBuffer.startsWith('\$')) {
        final endIndex = _receiveBuffer.indexOf('\r');
        if (endIndex == -1) {
          break;
        }

        payloads.add(_receiveBuffer.substring(0, endIndex + 1));
        _receiveBuffer = _receiveBuffer.substring(endIndex + 1).trimLeft();
        continue;
      }

      final nextStart = _indexOfNextPayloadStart(_receiveBuffer);
      if (nextStart == -1) {
        _receiveBuffer = '';
        break;
      }

      _receiveBuffer = _receiveBuffer.substring(nextStart).trimLeft();
    }

    return payloads;
  }

  int _findJsonPayloadEnd(String buffer) {
    var depth = 0;
    for (var i = 0; i < buffer.length; i++) {
      final char = buffer[i];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return i;
        }
      }
    }
    return -1;
  }

  int _indexOfNextPayloadStart(String buffer) {
    final jsonStart = buffer.indexOf('{');
    final protocolStart = buffer.indexOf('\$');

    if (jsonStart == -1) {
      return protocolStart;
    }
    if (protocolStart == -1) {
      return jsonStart;
    }

    return jsonStart < protocolStart ? jsonStart : protocolStart;
  }

  void _emitIncomingPayload(String payload) {
    final normalized = payload.trimRight();
    if (normalized.isEmpty) {
      return;
    }

    debugPrint(
      'BLE RX: ${normalized.replaceAll('\r', r'\r').replaceAll('\n', r'\n')}',
    );

    final entry = LogEntry(text: normalized, isResponse: true);
    _logHistory.add(entry);
    _dataLogController.add(entry);
    _notificationController.add(utf8.encode(normalized));
  }
}

class LogEntry {
  final String text;
  final DateTime timestamp;
  final bool isResponse;

  LogEntry({required this.text, required this.isResponse}) : timestamp = DateTime.now();
}
