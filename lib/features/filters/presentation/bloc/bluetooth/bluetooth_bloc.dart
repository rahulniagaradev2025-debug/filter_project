import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:filter_project/core/bluetooth/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothBlocState> {
  final AppBluetoothService bluetoothService;

  BluetoothBloc({required this.bluetoothService}) : super(BluetoothInitial()) {
    on<StartScanEvent>((event, emit) async {
      emit(BluetoothScanning());
      try {
        // Request only necessary permissions for Android 12+
        // With neverForLocation in Manifest, we only need bluetoothScan and bluetoothConnect
        Map<Permission, PermissionStatus> statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

        if (statuses[Permission.bluetoothScan]!.isGranted &&
            statuses[Permission.bluetoothConnect]!.isGranted) {
          
          // Check if Bluetooth is ON. If not, try to turn it ON (Android only)
          if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
            try {
              await FlutterBluePlus.turnOn();
              // Wait a bit for adapter to change state
              await Future.delayed(const Duration(seconds: 1));
            } catch (e) {
              emit(const BluetoothError("Could not turn on Bluetooth. Please enable it manually."));
              return;
            }
          }

          // Double check after attempting to turn on
          if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
            emit(const BluetoothError("Bluetooth is turned OFF. Please turn it ON."));
            return;
          }

          await bluetoothService.startScan();
          await emit.forEach<List<ScanResult>>(
            bluetoothService.scanResults,
            onData: (results) => BluetoothScanResults(results),
          );
        } else {
          emit(const BluetoothError("Bluetooth permissions denied. Please allow them in settings."));
        }
      } catch (e) {
        emit(BluetoothError(e.toString()));
      }
    });

    on<ConnectDeviceEvent>((event, emit) async {
      emit(BluetoothConnecting());
      try {
        await bluetoothService.connect(event.device);
        emit(BluetoothConnected(event.device));
      } catch (e) {
        emit(BluetoothError(e.toString()));
      }
    });

    on<DisconnectDeviceEvent>((event, emit) async {
      await bluetoothService.disconnect();
      emit(BluetoothInitial());
    });
  }
}
