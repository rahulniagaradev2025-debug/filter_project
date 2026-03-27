import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:filter_project/core/bluetooth/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothBlocState> {
  final AppBluetoothService bluetoothService;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  BluetoothBloc({required this.bluetoothService}) : super(BluetoothInitial()) {
    on<StartScanEvent>((event, emit) async {
      emit(BluetoothScanning());
      try {
        // Stop any ongoing scan first
        await bluetoothService.stopScan();
        await Future.delayed(const Duration(milliseconds: 200));

        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

        if (statuses[Permission.bluetoothScan]!.isGranted &&
            statuses[Permission.bluetoothConnect]!.isGranted) {
          if (await FlutterBluePlus.adapterState.first !=
              BluetoothAdapterState.on) {
            try {
              await FlutterBluePlus.turnOn();
              await Future.delayed(const Duration(seconds: 1));
            } catch (e) {
              emit(const BluetoothError("Could not turn on Bluetooth."));
              return;
            }
          }

          await bluetoothService.startScan();

          await emit.forEach<List<ScanResult>>(
            bluetoothService.scanResults.map(_prepareScanResults),
            onData: (results) => BluetoothScanResults(results),
          );
        } else {
          emit(const BluetoothError("Permissions denied."));
        }
      } catch (e) {
        emit(BluetoothError(e.toString()));
      }
    });

    on<ConnectDeviceEvent>((event, emit) async {
      emit(BluetoothConnecting());
      try {
        // Stop scanning before connecting
        await bluetoothService.stopScan();

        await bluetoothService.connect(event.device);

        // Subscribe to connection state changes to keep the UI in sync
        _connectionSubscription?.cancel();
        _connectionSubscription = event.device.connectionState.listen((state) {
          add(BluetoothStatusChangedEvent(state, event.device));
        });

        // Small delay to allow services to be fully ready and state to stabilize
        await Future.delayed(const Duration(milliseconds: 1000));

        emit(BluetoothConnected(event.device));
      } catch (e) {
        emit(BluetoothError(e.toString()));
      }
    });

    on<BluetoothStatusChangedEvent>((event, emit) {
      if (event.state == BluetoothConnectionState.connected) {
        emit(BluetoothConnected(event.device));
      } else if (event.state == BluetoothConnectionState.disconnected) {
        emit(BluetoothInitial());
      }
      // Note: We ignore 'connecting' and 'disconnecting' states to prevent
      // the dashboard icon from flickering or turning red during transitions.
    });

    on<DisconnectDeviceEvent>((event, emit) async {
      await bluetoothService.disconnect();
      _connectionSubscription?.cancel();
      emit(BluetoothInitial());
    });
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    return super.close();
  }

  List<ScanResult> _prepareScanResults(List<ScanResult> results) {
    final uniqueResults = <String, ScanResult>{};

    for (final result in results) {
      final deviceId = result.device.remoteId.toString();
      final previousResult = uniqueResults[deviceId];

      if (previousResult == null || result.rssi > previousResult.rssi) {
        uniqueResults[deviceId] = result;
      }
    }

    final preparedResults = uniqueResults.values.toList();

    preparedResults.sort((a, b) {
      final aHasName = a.device.platformName.trim().isNotEmpty;
      final bHasName = b.device.platformName.trim().isNotEmpty;

      if (aHasName != bHasName) {
        return aHasName ? -1 : 1;
      }

      return b.rssi.compareTo(a.rssi);
    });

    return preparedResults;
  }
}
