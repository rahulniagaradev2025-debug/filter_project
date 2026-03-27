class AppConstants {
  // Protocol Constants
  static const String protocolStartHeader = '\$';
  static const String protocolEnd = '\r';

  // BLE Hardware UUIDs
  static const String preferredBleServiceUuid = "49535343-8841-43f4-a8d4-ecbe34729bb3";
  
  // App Mode (Settings/Config)
  static const String preferredBleWriteCharacteristicUuid = "49535343-8841-43f4-a8d4-ecbe34729bb3";
  static const String preferredBleNotifyCharacteristicUuid = "49535343-8841-43f4-a8d4-ecbe34729bb3";

  // Terminal Mode (Raw Console)
  static const String terminalWriteUuid = "49535343-8841-43f4-a8d4-ecbe34729bb3";
  static const String terminalNotifyUuid = "49535343-8841-43f4-a8d4-ecbe34729bb3";

  // Configuration
  static const int maxFilterCount = 8;
  static const int filtersPerPayload = 4;
  static const int bluetoothScanTimeout = 15;
  static const int bleWriteChunkSize = 244;
  static const int bleWriteChunkDelayMs = 10;

  // UI Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double cardElevation = 2.0;
}
