import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:filter_project/core/bluetooth/bluetooth_service.dart';

part 'bluetooth_event.dart';
part 'bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothState> {
  final AppBluetoothService bluetoothService;

  BluetoothBloc({required this.bluetoothService}) : super(BluetoothInitial()) {
    on<StartScanEvent>((event, emit) async {
      emit(BluetoothScanning());
      try {
        await bluetoothService.startScan();
        await emit.forEach<List<ScanResult>>(
          bluetoothService.scanResults,
          onData: (results) => BluetoothScanResults(results),
        );
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
