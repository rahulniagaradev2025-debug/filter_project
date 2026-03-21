import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/filter/filter_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import '../../widgets/status_card.dart';
import '../config/config_page.dart';
import '../bluetooth/bluetooth_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Dashboard'),
        actions: [
          BlocBuilder<BluetoothBloc, BluetoothBlocState>(
            builder: (context, state) {
              Color connectionColor = Colors.red;
              if (state is BluetoothConnected) {
                connectionColor = Colors.green;
              } else if (state is BluetoothConnecting) {
                connectionColor = Colors.orange;
              }
              return Icon(Icons.bluetooth, color: connectionColor);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfigPage()),
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BluetoothBloc, BluetoothBlocState>(
            listener: (context, state) {
              if (state is BluetoothError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bluetooth Error: ${state.message}')),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<FilterBloc, FilterState>(
          builder: (context, filterState) {
            return BlocBuilder<BluetoothBloc, BluetoothBlocState>(
              builder: (context, bluetoothState) {
                bool isConnected = bluetoothState is BluetoothConnected;
                String currentFilter = "N/A";
                String status = isConnected ? "CONNECTED" : "DISCONNECTED";
                String remainingTime = "00:00:00";
                Color statusColor = isConnected ? Colors.green : Colors.red;

                if (filterState is FilterStatusUpdate) {
                  status = filterState.status;
                  statusColor = Colors.blue;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isConnected)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Please connect to a Bluetooth device to control the filter.',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      StatusCard(
                        title: 'Current Filter',
                        value: currentFilter,
                        icon: Icons.filter_alt,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      StatusCard(
                        title: 'System Status',
                        value: status,
                        icon: Icons.power_settings_new,
                        color: statusColor,
                      ),
                      const SizedBox(height: 16),
                      StatusCard(
                        title: 'Remaining Time',
                        value: remainingTime,
                        icon: Icons.timer,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isConnected
                                  ? () {
                                      context.read<FilterBloc>().add(StartFilterEvent());
                                    }
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('START'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade100,
                                foregroundColor: Colors.green.shade900,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isConnected
                                  ? () {
                                      context.read<FilterBloc>().add(StopFilterEvent());
                                    }
                                  : null,
                              icon: const Icon(Icons.stop),
                              label: const Text('STOP'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade100,
                                foregroundColor: Colors.red.shade900,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BluetoothPage()),
                          );
                        },
                        icon: Icon(isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
                        label: Text(isConnected ? 'RECONNECT / CHANGE DEVICE' : 'SCAN FOR DEVICES'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
