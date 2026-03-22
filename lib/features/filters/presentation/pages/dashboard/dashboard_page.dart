import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:filter_project/features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/execution/execution_bloc.dart' as exec;
import 'package:filter_project/core/utils/excel_util.dart';
import 'package:filter_project/core/protocols/payload_parser.dart';
import '../../widgets/status_card.dart';
import '../config/config_page.dart';
import '../bluetooth/bluetooth_page.dart';
import '../report/report_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Map<String, dynamic>> _statusHistory = [];
  Map<String, dynamic> _lastParsedData = {};
  Map<String, dynamic>? _lastConfigData;

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
            icon: const Icon(Icons.add_chart),
            tooltip: 'View Reports',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuration',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConfigPage()),
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<exec.ExecutionBloc, exec.ExecutionState>(
            listener: (context, state) {
              if (state is exec.ExecutionStatusUpdate) {
                final data = PayloadParser.parseRaw(state.status);
                setState(() {
                  if (data['type'] == 'live') {
                    _lastParsedData = data;
                    _statusHistory.add({
                      'timestamp': DateTime.now().toString().split('.').first,
                      'current_filter': data['current_filter'],
                      'system_status': data['status'],
                      'remaining_time': data['time'],
                    });
                  } else if (data['type'] == 'settings') {
                    _lastConfigData = data;
                  }
                });
              }
            },
          ),
        ],
        child: BlocBuilder<exec.ExecutionBloc, exec.ExecutionState>(
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
                        _buildConnectionWarning(),
                      
                      // SVG DISPLAY
                      _buildSvgDisplay(),
                      
                      const SizedBox(height: 24),
                      
                      // LIVE STATUS CARDS
                      _buildLiveStatusSection(),
                      
                      const SizedBox(height: 32),
                      _buildControlSection(context, isConnected),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      
                      // CURRENT CONFIGURATION SECTION
                      if (_lastConfigData != null)
                        _buildConfigDisplay(),
                      
                      const SizedBox(height: 16),
                      _buildHardwareRequests(context, isConnected),
                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 24),
                      _buildScanButton(context, isConnected),
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

  Widget _buildSvgDisplay() {
    int count = int.tryParse(_lastConfigData?['count']?.toString() ?? '0') ?? 0;
    if (count == 0) {
      return const Center(child: Text("No filters configured", style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        const Text("Active Backwash System", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/images/fliter_backwash.svg',
                      width: 50,
                      height: 50,
                      colorFilter: _lastParsedData['current_filter'] == 'Filter #${index + 1}' 
                          ? const ColorFilter.mode(Colors.blue, BlendMode.srcIn)
                          : const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                    ),
                    Text("F${index + 1}", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStatusSection() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildConfigDisplay() {
    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Current Device Configuration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const Divider(),
            Text('Method: ${_lastConfigData!['method']}'),
            Text('Total Filters: ${_lastConfigData!['count']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
      child: const Text('Please connect to a Bluetooth device to control the filter.',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    );
  }

  Widget _buildControlSection(BuildContext context, bool isEnabled) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? () => context.read<exec.ExecutionBloc>().add(exec.StartFilterEvent()) : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('START'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green.shade900),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isEnabled ? () => context.read<exec.ExecutionBloc>().add(exec.StopFilterEvent()) : null,
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
                onPressed: isEnabled ? () => context.read<exec.ExecutionBloc>().add(exec.RequestViewSettingsEvent()) : null,
                icon: const Icon(Icons.visibility),
                label: const Text('VIEW SETTINGS'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isEnabled ? () => context.read<exec.ExecutionBloc>().add(exec.RequestLiveUpdateEvent()) : null,
                icon: const Icon(Icons.refresh),
                label: const Text('LIVE REQUEST'),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildScanButton(BuildContext context, bool isConnected) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BluetoothPage())),
      icon: Icon(isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
      label: Text(isConnected ? 'RECONNECT / CHANGE DEVICE' : 'SCAN FOR DEVICES'),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
    );
  }
}
