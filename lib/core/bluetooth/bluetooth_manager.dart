import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'bluetooth_service.dart';
import 'bluetooth_state.dart';

class BluetoothManager {
  final AppBluetoothService _bluetoothService;
  final StreamController<AppBluetoothState> _stateController = StreamController<AppBluetoothState>.broadcast();

  BluetoothManager(this._bluetoothService) {
    _stateController.add(BluetoothIdle());
  }

  Stream<AppBluetoothState> get stateStream => _stateController.stream;

  Future<void> scanForDevices() async {
    _stateController.add(BluetoothScanning());
    try {
      await _bluetoothService.startScan();
    } catch (e) {
      _stateController.add(BluetoothError(e.toString()));
    }
  }

  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      await _bluetoothService.connect(device);
      _stateController.add(BluetoothConnected(device));
    } catch (e) {
      _stateController.add(BluetoothError(e.toString()));
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetoothService.disconnect();
      _stateController.add(BluetoothDisconnected());
    } catch (e) {
      _stateController.add(BluetoothError(e.toString()));
    }
  }

  void dispose() {
    _stateController.close();
  }
}
