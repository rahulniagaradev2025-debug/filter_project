part of 'bluetooth_bloc.dart';

abstract class BluetoothState extends Equatable {
  const BluetoothState();

  @override
  List<Object> get props => [];
}

class BluetoothInitial extends BluetoothState {}

class BluetoothScanning extends BluetoothState {}

class BluetoothScanResults extends BluetoothState {
  final List<ScanResult> results;
  const BluetoothScanResults(this.results);

  @override
  List<Object> get props => [results];
}

class BluetoothConnecting extends BluetoothState {}

class BluetoothConnected extends BluetoothState {
  final BluetoothDevice device;
  const BluetoothConnected(this.device);

  @override
  List<Object> get props => [device];
}

class BluetoothError extends BluetoothState {
  final String message;
  const BluetoothError(this.message);

  @override
  List<Object> get props => [message];
}
