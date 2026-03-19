import '../../../../core/bluetooth/bluetooth_service.dart';
import '../models/filter_config_model.dart';

abstract class FilterRemoteDataSource {
  Future<void> sendConfiguration(FilterConfigModel config);
  Stream<String> getSystemStatus();
  Future<void> startFilter();
  Future<void> stopFilter();
}

class FilterRemoteDataSourceImpl implements FilterRemoteDataSource {
  final AppBluetoothService bluetoothService;

  FilterRemoteDataSourceImpl(this.bluetoothService);

  @override
  Future<void> sendConfiguration(FilterConfigModel config) async {
    // Convert model to byte protocol (Dummy implementation)
    final List<int> data = [0x01, config.filterCount];
    await bluetoothService.writeData(data);
  }

  @override
  Stream<String> getSystemStatus() {
    return bluetoothService.subscribeToNotifications().map((data) {
      // Parse byte data to status string (Dummy implementation)
      return "Status: ${data.toString()}";
    });
  }

  @override
  Future<void> startFilter() async {
    await bluetoothService.writeData([0x02]); // Start command
  }

  @override
  Future<void> stopFilter() async {
    await bluetoothService.writeData([0x03]); // Stop command
  }
}
