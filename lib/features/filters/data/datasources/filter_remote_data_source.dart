import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/bluetooth/bluetooth_service.dart';
import '../../../../core/protocols/payload_builder.dart';
import '../../../../core/protocols/payload_parser.dart';
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
    final payloads = PayloadBuilder.buildConfigPayloads(config);
    
    for (int i = 0; i < payloads.length; i++) {
      final setId = (i + 1).toString();
      debugPrint("Sending Configuration Set $setId...");

      final completer = Completer<void>();
      
      // 1. Start listening for the ACK BEFORE sending the data
      final subscription = bluetoothService.dataLogStream.listen((log) {
        if (!log.isResponse) return;

        final parsed = PayloadParser.parseRaw(log.text);
        if (parsed['type'] == 'settings_ack' && parsed['ack_id'] == setId) {
          debugPrint("Hardware Acknowledged Set $setId: ${parsed['message']}");
          if (!completer.isCompleted) completer.complete();
        }
      });

      try {
        // 2. Send the specific payload
        await bluetoothService.writeData(payloads[i]);

        // 3. Wait for ACK or 3.5s Timeout (per hardware spec)
        await completer.future.timeout(
          const Duration(milliseconds: 3500),
          onTimeout: () {
            debugPrint("Timeout waiting for Set $setId ACK. Proceeding with delay...");
          },
        );
      } finally {
        await subscription.cancel();
      }

      // Small additional delay to ensure hardware is ready for next set
      if (i < payloads.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    debugPrint("Full Configuration Transfer Complete.");
  }

  @override
  Stream<String> getSystemStatus() {
    return bluetoothService.subscribeToNotifications().map((data) {
      return utf8.decode(data, allowMalformed: true);
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
