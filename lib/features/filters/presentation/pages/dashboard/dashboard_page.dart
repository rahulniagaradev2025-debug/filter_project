import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/filter/filter_bloc.dart';
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
      body: BlocBuilder<FilterBloc, FilterState>(
        builder: (context, state) {
          String currentFilter = "N/A";
          String status = "OFF";
          String remainingTime = "00:00:00";
          Color statusColor = Colors.grey;

          if (state is FilterStatusUpdate) {
            // Dummy parsing logic for demo
            status = state.status;
            statusColor = Colors.green;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        onPressed: () {
                          context.read<FilterBloc>().add(StartFilterEvent());
                        },
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
                        onPressed: () {
                          context.read<FilterBloc>().add(StopFilterEvent());
                        },
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
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('SCAN FOR DEVICES'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
