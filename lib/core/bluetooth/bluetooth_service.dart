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
  fbp.BluetoothCharacteristic? _readCharacteristic;

  Future<void> startScan() async {
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
    if (device.isConnected) return;
    
    try {
      await device.connect(timeout: const Duration(seconds: 10), autoConnect: false);
      _connectedDevice = device;
      _writeCharacteristic = null;
      _readCharacteristic = null;

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

      _writeCharacteristic = _selectCharacteristic(
        services,
        preferredServiceUuid: AppConstants.preferredBleServiceUuid,
        preferredCharacteristicUuid: AppConstants.preferredBleWriteCharacteristicUuid,
        supportsCharacteristic: (characteristic) =>
            characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse,
      );

      _readCharacteristic = _selectCharacteristic(
        services,
        preferredServiceUuid: AppConstants.preferredBleServiceUuid,
        preferredCharacteristicUuid: AppConstants.preferredBleNotifyCharacteristicUuid,
        supportsCharacteristic: (characteristic) =>
            characteristic.properties.notify ||
            characteristic.properties.indicate,
      );

      if (_writeCharacteristic == null) {
        throw Exception("No writable BLE characteristic found on the device.");
      }

      if (_readCharacteristic != null) {
        await _readCharacteristic!.setNotifyValue(true);
        debugPrint("Subscribed to Notify Characteristic: ${_readCharacteristic!.uuid}");
      }
    } catch (e) {
      await device.disconnect();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _writeCharacteristic = null;
    _readCharacteristic = null;
  }

  Future<void> writeData(List<int> data) async {
    if (_writeCharacteristic != null) {
      bool canWriteWithoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(data, withoutResponse: canWriteWithoutResponse);
    } else {
      throw Exception("Device not ready for writing.");
    }
  }

  Stream<List<int>> subscribeToNotifications() {
    if (_readCharacteristic == null) return const Stream.empty();
    return _readCharacteristic!.onValueReceived.map((data) {
      if (kDebugMode) {
        print('--- DATA RECEIVED FROM HARDWARE ---');
        print('Raw Bytes: $data');
        print('String: ${utf8.decode(data, allowMalformed: true)}');
        print('------------------------------------');
      }
      return data;
    });
  }

  fbp.BluetoothCharacteristic? _selectCharacteristic(
    List<fbp.BluetoothService> services, {
    required String preferredServiceUuid,
    required String preferredCharacteristicUuid,
    required bool Function(fbp.BluetoothCharacteristic characteristic)
        supportsCharacteristic,
  }) {
    final normalizedServiceUuid = _normalizeUuid(preferredServiceUuid);
    final normalizedCharacteristicUuid =
        _normalizeUuid(preferredCharacteristicUuid);

    for (final service in services) {
      final serviceUuid = _normalizeUuid(service.uuid.toString());
      final serviceMatches = normalizedServiceUuid.isEmpty ||
          serviceUuid == normalizedServiceUuid;
      if (!serviceMatches) {
        continue;
      }

      for (final characteristic in service.characteristics) {
        final characteristicUuid =
            _normalizeUuid(characteristic.uuid.toString());
        final characteristicMatches = normalizedCharacteristicUuid.isEmpty ||
            characteristicUuid == normalizedCharacteristicUuid;

        if (characteristicMatches &&
            supportsCharacteristic(characteristic)) {
          debugPrint(
            "Selected Characteristic ${characteristic.uuid} from service ${service.uuid}",
          );
          return characteristic;
        }
      }
    }

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (supportsCharacteristic(characteristic)) {
          debugPrint(
            "Falling back to Characteristic ${characteristic.uuid} from service ${service.uuid}",
          );
          return characteristic;
        }
      }
    }

    return null;
  }

  String _normalizeUuid(String uuid) => uuid.trim().toLowerCase();

  void _logDiscoveredServices(List<fbp.BluetoothService> services) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('--- DISCOVERED BLE SERVICES ---');
    for (final service in services) {
      debugPrint('Service: ${service.uuid}');
      for (final characteristic in service.characteristics) {
        debugPrint(
          '  Characteristic: ${characteristic.uuid} '
          '[write=${characteristic.properties.write}, '
          'writeWithoutResponse=${characteristic.properties.writeWithoutResponse}, '
          'notify=${characteristic.properties.notify}, '
          'indicate=${characteristic.properties.indicate}]',
        );
      }
    }
    debugPrint('-------------------------------');
  }
}
