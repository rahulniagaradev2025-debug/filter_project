import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/execution/execution_bloc.dart';
import 'package:filter_project/core/utils/excel_util.dart';
import 'package:filter_project/core/protocols/payload_parser.dart';
import '../../widgets/status_card.dart';
import '../config/config_page.dart';
import '../bluetooth/bluetooth_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Map<String, dynamic>> _statusHistory = [];
  Map<String, dynamic> _lastParsedData = {};

  void _showSettingsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hardware Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payload ID: ${data['payloadId']}'),
            Text('Method: ${data['method'] == '0' ? 'Time' : data['method'] == '1' ? 'DP' : 'Both'}'),
            Text('Filter Count: ${data['count']}'),
            const SizedBox(height: 10),
            Text('Raw: ${data['raw']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Dashboard'),
        actions: [
          BlocBuilder<BluetoothBloc, BluetoothBlocState>(
            builder: (context, state) {
              Color connectionColor = state is BluetoothConnected ? Colors.green : (state is BluetoothConnecting ? Colors.orange : Colors.red);
              return Icon(Icons.bluetooth, color: connectionColor);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfigPage())),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ExecutionBloc, ExecutionState>(
            listener: (context, state) {
              if (state is ExecutionStatusUpdate) {
                final data = PayloadParser.parseRaw(state.status);
                setState(() {
                  _lastParsedData = data;
                  if (data['type'] == 'live') {
                    _statusHistory.add({
                      'timestamp': DateTime.now().toString().split('.').first,
                      'current_filter': data['current_filter'],
                      'system_status': data['status'],
                      'remaining_time': data['time'],
                    });
                  }
                });

                if (data['type'] == 'settings') {
                  _showSettingsDialog(data);
                }
              }
            },
          ),
        ],
        child: BlocBuilder<ExecutionBloc, ExecutionState>(
          builder: (context, filterState) {
            return BlocBuilder<BluetoothBloc, BluetoothBlocState>(
              builder: (context, bluetoothState) {
                bool isConnected = bluetoothState is BluetoothConnected;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isConnected)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Please connect to a Bluetooth device to control the filter.',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      StatusCard(
                        title: 'Current Filter',
                        value: _lastParsedData['current_filter'] ?? 'N/A',
                        icon: Icons.filter_alt,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      StatusCard(
                        title: 'System Status',
                        value: _lastParsedData['status'] ?? 'OFF',
                        icon: Icons.power_settings_new,
                        color: _lastParsedData['status'] == 'ON' ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      StatusCard(
                        title: 'Remaining Time',
                        value: _lastParsedData['time'] ?? '00:00:00',
                        icon: Icons.timer,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 32),
                      // EXECUTION BUTTONS
                      _buildControlSection(context, isConnected),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // HARDWARE REQUEST BUTTONS
                      _buildHardwareRequests(context, isConnected),
                      const SizedBox(height: 16),
                      _buildReportButton(),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // SCAN BUTTON
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

  Widget _buildControlSection(BuildContext context, bool isEnabled) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? () => context.read<ExecutionBloc>().add(StartFilterEvent()) : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('START'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? () => context.read<ExecutionBloc>().add(StopFilterEvent()) : null,
            icon: const Icon(Icons.stop),
            label: const Text('STOP'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900),
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareRequests(BuildContext context, bool isEnabled) {
    return Column(
      children: [
        const Text("Hardware Requests", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled ? () => context.read<ExecutionBloc>().add(RequestViewSettingsEvent()) : null,
                icon: const Icon(Icons.visibility),
                label: const Text('VIEW SETTINGS'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled ? () => context.read<ExecutionBloc>().add(RequestLiveUpdateEvent()) : null,
                icon: const Icon(Icons.refresh),
                label: const Text('LIVE REQUEST'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportButton() {
    return ElevatedButton.icon(
      onPressed: _statusHistory.isEmpty ? null : () => ExcelUtil.generateAndShareReport(_statusHistory),
      icon: const Icon(Icons.description),
      label: const Text('DOWNLOAD EXCEL REPORT'),
    );
  }
}
