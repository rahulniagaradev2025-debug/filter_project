import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../utils/constants.dart';

class AppBluetoothService {
  Stream<List<fbp.ScanResult>> get scanResults => fbp.FlutterBluePlus.scanResults;
  
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  final List<StreamSubscription> _notifySubscriptions = [];

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
        timeout: const Duration(seconds: 15),
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
      _logDiscoveredServices(services);

      // Select Write Characteristic
      _writeCharacteristic = _selectCharacteristic(
        services,
        preferredServiceUuid: AppConstants.preferredBleServiceUuid,
        preferredCharacteristicUuid: AppConstants.preferredBleWriteCharacteristicUuid,
        supportsCharacteristic: _supportsWrite,
      );

      if (_writeCharacteristic == null) {
        throw Exception("No writable BLE characteristic found.");
      }

      // Step 1: Identify all notify characteristics
      final notifyChars = <fbp.BluetoothCharacteristic>[];
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (_supportsNotify(characteristic)) {
            notifyChars.add(characteristic);
          }
        }
      }

      // Step 2: Attach listeners FIRST before enabling notifications
      for (final characteristic in notifyChars) {
        final sub = characteristic.onValueReceived.listen((data) {
          final text = utf8.decode(data, allowMalformed: true);
          debugPrint('BLE RX: $text');
          
          final entry = LogEntry(text: text, isResponse: true);
          _logHistory.add(entry);
          _dataLogController.add(entry);
          _notificationController.add(data);
        });
        _notifySubscriptions.add(sub);
      }

      // Step 3: Enable notifications on the characteristics
      for (final characteristic in notifyChars) {
        try {
          await characteristic.setNotifyValue(true);
          debugPrint('Notifications enabled for: ${characteristic.uuid}');
          // Small delay between descriptor writes to avoid GATT congestion
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
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _cleanupConnection();
  }

  Future<void> writeData(List<int> data) async {
    if (_writeCharacteristic != null) {
      bool canWriteWithoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(data, withoutResponse: canWriteWithoutResponse);
      
      final text = utf8.decode(data, allowMalformed: true);
      debugPrint('BLE TX: $text');
      
      final entry = LogEntry(text: text, isResponse: false);
      _logHistory.add(entry);
      _dataLogController.add(entry);
    } else {
      throw Exception("Device not connected or not ready.");
    }
  }

  Stream<List<int>> subscribeToNotifications() {
    return _notificationController.stream;
  }

  void clearLogs() {
    _logHistory.clear();
  }

  bool _supportsWrite(fbp.BluetoothCharacteristic characteristic) {
    return characteristic.properties.write ||
        characteristic.properties.writeWithoutResponse;
  }

  bool _supportsNotify(fbp.BluetoothCharacteristic characteristic) {
    return characteristic.properties.notify ||
        characteristic.properties.indicate;
  }

  void _logDiscoveredServices(List<fbp.BluetoothService> services) {
    for (final service in services) {
      debugPrint('BLE service discovered: ${service.uuid}');
      for (final characteristic in service.characteristics) {
        debugPrint(
          '  characteristic ${characteristic.uuid} '
          '[read=${characteristic.properties.read}, '
          'write=${characteristic.properties.write}, '
          'writeNoResp=${characteristic.properties.writeWithoutResponse}, '
          'notify=${characteristic.properties.notify}, '
          'indicate=${characteristic.properties.indicate}]',
        );
      }
    }
  }

  fbp.BluetoothCharacteristic? _selectCharacteristic(
    List<fbp.BluetoothService> services, {
    required String preferredServiceUuid,
    required String preferredCharacteristicUuid,
    required bool Function(fbp.BluetoothCharacteristic characteristic)
        supportsCharacteristic,
  }) {
    final normalizedServiceUuid = preferredServiceUuid.trim().toLowerCase();
    final normalizedCharacteristicUuid = preferredCharacteristicUuid.trim().toLowerCase();

    for (final service in services) {
      final serviceUuid = service.uuid.toString().toLowerCase();
      if (normalizedServiceUuid.isNotEmpty && serviceUuid != normalizedServiceUuid) continue;

      for (final characteristic in service.characteristics) {
        final characteristicUuid = characteristic.uuid.toString().toLowerCase();
        if (normalizedCharacteristicUuid.isNotEmpty && characteristicUuid != normalizedCharacteristicUuid) continue;

        if (supportsCharacteristic(characteristic)) {
          return characteristic;
        }
      }
    }

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (supportsCharacteristic(characteristic)) {
          return characteristic;
        }
      }
    }
    return null;
  }
}

class LogEntry {
  final String text;
  final DateTime timestamp;
  final bool isResponse;

  LogEntry({required this.text, required this.isResponse}) : timestamp = DateTime.now();
}
