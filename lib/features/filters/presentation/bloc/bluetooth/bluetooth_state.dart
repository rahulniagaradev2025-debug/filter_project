part of 'bluetooth_bloc.dart';

abstract class BluetoothBlocState extends Equatable {
  const BluetoothBlocState();

  @override
  List<Object> get props => [];
}

class BluetoothInitial extends BluetoothBlocState {}

class BluetoothScanning extends BluetoothBlocState {}

class BluetoothScanResults extends BluetoothBlocState {
  final List<ScanResult> results;
  const BluetoothScanResults(this.results);

  @override
  List<Object> get props => [results];
}

class BluetoothConnecting extends BluetoothBlocState {}

class BluetoothConnected extends BluetoothBlocState {
  final BluetoothDevice device;
  const BluetoothConnected(this.device);

  @override
  List<Object> get props => [device];
}

class BluetoothError extends BluetoothBlocState {
  final String message;
  const BluetoothError(this.message);

  @override
  List<Object> get props => [message];
}
