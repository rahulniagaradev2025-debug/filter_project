import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class AppBluetoothState extends Equatable {
  const AppBluetoothState();

  @override
  List<Object?> get props => [];
}

class BluetoothIdle extends AppBluetoothState {}

class BluetoothScanning extends AppBluetoothState {}

class BluetoothConnected extends AppBluetoothState {
  final BluetoothDevice device;
  const BluetoothConnected(this.device);

  @override
  List<Object?> get props => [device];
}

class BluetoothDisconnected extends AppBluetoothState {}

class BluetoothError extends AppBluetoothState {
  final String message;
  const BluetoothError(this.message);

  @override
  List<Object?> get props => [message];
}
