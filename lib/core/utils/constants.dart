class AppConstants {
  // Protocol Constants
  static const String protocolStartHeader = '\$';
  static const String configHeader = 'value:valve:';
  static const String startCommand = 'value:start:/r';
  static const String stopCommand = 'value:stop:/r';
  static const String protocolEnd = '/r';

  // Filter Configuration
  static const int maxFilterCount = 8;
  static const List<String> filterMethods = ['Time', 'DP', 'Both'];

  // Bluetooth
  static const int bluetoothScanTimeout = 15; // seconds

  // UI Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double cardElevation = 2.0;

  // Status Strings
  static const String statusConnected = 'CONNECTED';
  static const String statusDisconnected = 'DISCONNECTED';
  static const String statusOn = 'ON';
  static const String statusOff = 'OFF';
  static const String statusWait = 'WAIT';
}
