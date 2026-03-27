class AppConstants {
  // Protocol Constants
  static const String protocolStartHeader = '\$';
  static const String protocolEnd = '\r';

  // BLE Hardware UUIDs
  static const String preferredBleServiceUuid = "12345678-1234-5678-1234-56789abcdef0";
  
  // App Mode (Settings/Config)
  static const String preferredBleWriteCharacteristicUuid = "12345678-1234-5678-1234-56789abcdef1";
  static const String preferredBleNotifyCharacteristicUuid = "12345678-1234-5678-1234-56789abcdef2";

  // Terminal Mode (Raw Console)
  static const String terminalWriteUuid = "12345678-1234-5678-1234-56789abcdef3";
  static const String terminalNotifyUuid = "12345678-1234-5678-1234-56789abcdef4";

  // Configuration
  static const int maxFilterCount = 8;
  static const int filtersPerPayload = 4;
  static const int bluetoothScanTimeout = 15;
  static const int bleWriteChunkSize = 20;
  static const int bleWriteChunkDelayMs = 40;

  // UI Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double cardElevation = 2.0;
}
