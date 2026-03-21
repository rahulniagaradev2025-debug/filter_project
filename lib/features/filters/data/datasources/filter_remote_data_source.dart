import 'dart:convert';
import '../../../../core/bluetooth/bluetooth_service.dart';
import '../../../../core/protocols/payload_builder.dart';
import '../models/filter_config_model.dart';

abstract class FilterRemoteDataSource {
  Future<void> sendConfiguration(FilterConfigModel config);
  Stream<String> getSystemStatus();
  Future<void> startFilter();
  Future<void> stopFilter();
  Future<void> requestViewSettings();
  Future<void> requestLiveUpdate();
}

class FilterRemoteDataSourceImpl implements FilterRemoteDataSource {
  final AppBluetoothService bluetoothService;

  FilterRemoteDataSourceImpl(this.bluetoothService);

  @override
  Future<void> sendConfiguration(FilterConfigModel config) async {
    final List<int> data = PayloadBuilder.buildConfigPayload(config);
    await bluetoothService.writeData(data);
  }

  @override
  Stream<String> getSystemStatus() {
    // We decode the bytes directly to UTF8 string so the Parser gets the raw '$:...' format
    return bluetoothService.subscribeToNotifications().map((data) {
      return utf8.decode(data);
    });
  }

  @override
  Future<void> startFilter() async {
    await bluetoothService.writeData(PayloadBuilder.buildStartCommand());
  }

  @override
  Future<void> stopFilter() async {
    await bluetoothService.writeData(PayloadBuilder.buildStopCommand());
  }

  @override
  Future<void> requestViewSettings() async {
    await bluetoothService.writeData(PayloadBuilder.buildViewSettingsRequest());
  }

  @override
  Future<void> requestLiveUpdate() async {
    await bluetoothService.writeData(PayloadBuilder.buildLiveRequest());
  }
}
