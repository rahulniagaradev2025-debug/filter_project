import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:filter_project/features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Start scanning when page opens
    context.read<BluetoothBloc>().add(StartScanEvent());
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E232C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Connect Device',
          style: TextStyle(color: Color(0xFF1E232C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BluetoothBloc, BluetoothBlocState>(
        listener: (context, state) {
          if (state is BluetoothConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connected to ${state.device.platformName.isNotEmpty ? state.device.platformName : state.device.remoteId}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is BluetoothError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              const SizedBox(height: 20),
              _buildRadarScanner(state is BluetoothScanning),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Available Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E232C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildDeviceList(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadarScanner(bool isScanning) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Circles
          ...List.generate(3, (index) {
            return Container(
              width: 100.0 * (index + 1),
              height: 100.0 * (index + 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2F80ED).withOpacity(0.1 * (3 - index)),
                  width: 2,
                ),
              ),
            );
          }),
          // Radar Sweep
          if (isScanning)
            RotationTransition(
              turns: _radarController,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    center: Alignment.center,
                    colors: [
                      const Color(0xFF2F80ED).withOpacity(0.0),
                      const Color(0xFF2F80ED).withOpacity(0.5),
                    ],
                    stops: const [0.75, 1.0],
                  ),
                ),
              ),
            ),
          // Center Icon
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF2F80ED),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2F80ED),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.bluetooth_searching,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, BluetoothBlocState state) {
    List<fbp.ScanResult> results = [];
    if (state is BluetoothScanResults) {
      results = state.results;
    } else if (state is BluetoothScanning) {
      // While scanning, we might still have partial results in some implementations
      // but typically we wait for the scan result state.
    }

    if (results.isEmpty && state is! BluetoothScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No devices found',
              style: TextStyle(color: Color(0xFF6A707C)),
            ),
            TextButton(
              onPressed: () => context.read<BluetoothBloc>().add(StartScanEvent()),
              child: const Text('Tap to Scan Again'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final device = result.device;
        final deviceName = device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
        final rssi = result.rssi;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bluetooth, color: Color(0xFF2F80ED)),
            ),
            title: Text(
              deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E232C)),
            ),
            subtitle: Text(
              device.remoteId.toString(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6A707C)),
            ),
            trailing: _buildConnectionTrailing(context, state, device, rssi),
          ),
        );
      },
    );
  }

  Widget _buildConnectionTrailing(BuildContext context, BluetoothBlocState state, fbp.BluetoothDevice device, int rssi) {
    bool isConnecting = state is BluetoothConnecting; // Simplification
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.signal_cellular_alt,
          size: 16,
          color: rssi > -70 ? Colors.green : (rssi > -90 ? Colors.orange : Colors.red),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isConnecting
              ? null
              : () => context.read<BluetoothBloc>().add(ConnectDeviceEvent(device)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F80ED),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Connect', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
