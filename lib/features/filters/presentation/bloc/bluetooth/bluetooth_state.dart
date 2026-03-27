part of 'bluetooth_bloc.dart';

abstract class BluetoothBlocState extends Equatable {
  const BluetoothBlocState();

  @override
  List<Object?> get props => [];
}

class BluetoothInitial extends BluetoothBlocState {}

class BluetoothScanning extends BluetoothBlocState {}

class BluetoothScanResults extends BluetoothBlocState {
  final List<ScanResult> results;
  const BluetoothScanResults(this.results);

  @override
  List<Object?> get props => [results];
}

class BluetoothConnecting extends BluetoothBlocState {}

class BluetoothConnected extends BluetoothBlocState {
  final BluetoothDevice device;
  final List<int>? receivedData; // Now holds latest received data
  const BluetoothConnected(this.device, {this.receivedData});

  @override
  List<Object?> get props => [device, receivedData];

  BluetoothConnected copyWith({
    BluetoothDevice? device,
    List<int>? receivedData,
  }) {
    return BluetoothConnected(
      device ?? this.device,
      receivedData: receivedData ?? this.receivedData,
    );
  }
}

class BluetoothError extends BluetoothBlocState {
  final String message;
  const BluetoothError(this.message);

  @override
  List<Object?> get props => [message];
}
