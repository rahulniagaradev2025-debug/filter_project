import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class AppBluetoothService {
  Stream<List<fbp.ScanResult>> get scanResults => fbp.FlutterBluePlus.scanResults;
  
  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _writeCharacteristic;
  fbp.BluetoothCharacteristic? _readCharacteristic;

  Future<void> startScan() async {
    if (await fbp.FlutterBluePlus.isScanningNow == false) {
      await fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
  }

  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  Future<void> connect(fbp.BluetoothDevice device) async {
    await device.connect();
    _connectedDevice = device;
    
    List<fbp.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          _writeCharacteristic = characteristic;
        }
        if (characteristic.properties.notify || characteristic.properties.indicate) {
          _readCharacteristic = characteristic;
          await _readCharacteristic!.setNotifyValue(true);
        }
      }
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
      await _writeCharacteristic!.write(data);
    } else {
      throw Exception("No write characteristic found. Connect to a device first.");
    }
  }

  Stream<List<int>> subscribeToNotifications() {
    return _readCharacteristic?.lastValueStream ?? const Stream.empty();
  }
}
