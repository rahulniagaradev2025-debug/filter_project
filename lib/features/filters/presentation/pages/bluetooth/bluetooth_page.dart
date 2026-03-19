import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:filter_project/features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';

class BluetoothPage extends StatelessWidget {
  const BluetoothPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Bluetooth'),
      ),
      body: BlocConsumer<BluetoothBloc, BluetoothState>(
        listener: (context, state) {
          if (state is BluetoothConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connected to ${state.device.remoteId}')),
            );
            Navigator.pop(context);
          } else if (state is BluetoothError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Devices',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (state is BluetoothScanning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          context.read<BluetoothBloc>().add(StartScanEvent());
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildDeviceList(context, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, BluetoothState state) {
    List<fbp.ScanResult> results = [];
    if (state is BluetoothScanResults) {
      results = state.results;
    }

    if (results.isEmpty && state is! BluetoothScanning) {
      return const Center(child: Text('No devices found. Start scanning.'));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final result = results[index];
        final device = result.device;
        final deviceName = device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
        
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(deviceName),
          subtitle: Text(device.remoteId.toString()),
          trailing: ElevatedButton(
            onPressed: state is BluetoothConnecting 
                ? null 
                : () {
                    context.read<BluetoothBloc>().add(ConnectDeviceEvent(device));
                  },
            child: const Text('Connect'),
          ),
        );
      },
    );
  }
}
