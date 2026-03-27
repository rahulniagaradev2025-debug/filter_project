part of 'bluetooth_bloc.dart';

abstract class BluetoothEvent extends Equatable {
  const BluetoothEvent();

  @override
  List<Object> get props => [];
}

class StartScanEvent extends BluetoothEvent {}

class ConnectDeviceEvent extends BluetoothEvent {
  final BluetoothDevice device;
  const ConnectDeviceEvent(this.device);

  @override
  List<Object> get props => [device];
}

class DisconnectDeviceEvent extends BluetoothEvent {}

class BluetoothStatusChangedEvent extends BluetoothEvent {
  final BluetoothConnectionState state;
  final BluetoothDevice device;
  const BluetoothStatusChangedEvent(this.state, this.device);

  @override
  List<Object> get props => [state, device];
}
