import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/protocols/payload_parser.dart';
import '../../../../../core/storage/app_config_preferences.dart';
import '../../../../../core/utils/time_utils.dart';
import '../../../data/models/filter_config_model.dart';
import '../../../domain/entities/filter_entity.dart';
import '../../bloc/bluetooth/bluetooth_bloc.dart';
import '../../bloc/execution/execution_bloc.dart' as exec;
import '../../widgets/app_bottom_nav.dart';
import '../bluetooth/bluetooth_page.dart';
import '../config/config_page.dart';
import '../report/report_page.dart';
import 'send_receive_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _preferences = AppConfigPreferences.instance;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FF),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardHome(
            preferences: _preferences,
            onOpenBluetooth: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothPage()),
              );
            },
          ),
          ReportPage(onNavigateDashboard: () => _onTabSelected(0)),
          ConfigPage(onNavigateDashboard: () => _onTabSelected(0)),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }
}

class _DashboardHome extends StatefulWidget {
  final AppConfigPreferences preferences;
  final VoidCallback onOpenBluetooth;

  const _DashboardHome({
    required this.preferences,
    required this.onOpenBluetooth,
  });

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  Map<String, dynamic> _lastParsedData = {};
  String _latestBleResponse = 'Waiting for device response...';

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<exec.ExecutionBloc, exec.ExecutionState>(
          listener: (context, state) {
            if (state is exec.ExecutionStatusUpdate) {
              final data = PayloadParser.parseRaw(state.status);
              setState(() {
                _latestBleResponse = state.status.replaceAll('\r', r'\r');
                if (data['type'] == 'live' || data['type'] == 'settings') {
                  _lastParsedData = data;
                  if (data['type'] == 'settings') {
                    _showSettingsUpdateDialog(data);
                  }
                }
              });
            } else if (state is exec.ExecutionConfigReceived) {
              // Handle the new structured config state
              setState(() {
                _latestBleResponse = state.rawResponse.replaceAll('\r', r'\r');
                // We convert the config model to the map format the dashboard expects
                _lastParsedData = {
                  'type': 'settings',
                  'method': state.config.method,
                  'count': state.config.filterCount.toString(),
                  'filters': state.config.filters.map((f) => TimeUtils.formatFilterTime(f)).toList(),
                };
              });
              _showSettingsUpdateDialog(_lastParsedData);
            }
          },
        ),
      ],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: ValueListenableBuilder<FilterConfigModel?>(
            valueListenable: widget.preferences.configNotifier,
            builder: (context, savedConfig, _) {
              final filterCount = savedConfig?.filterCount ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      _ActionButtons(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ResponseCard(response: _latestBleResponse),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filterCount == 0
                        ? const SizedBox.shrink()
                        : ListView.separated(
                            itemCount: filterCount,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              return _FilterCard(
                                index: index,
                                config: savedConfig!,
                                liveData: _lastParsedData,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SendReceivePage()),
            );
          },
          icon: const Icon(Icons.history_edu_rounded, color: Color(0xFF2F80ED)),
          tooltip: 'Send & Receive Logs',
        ),
        const Spacer(),
        const Text(
          'Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        BlocBuilder<BluetoothBloc, BluetoothBlocState>(
          builder: (context, state) {
            final isConnected = state is BluetoothConnected;
            final borderColor = isConnected
                ? Colors.green.withOpacity(0.7)
                : Colors.red.withOpacity(0.7);

            return InkWell(
              onTap: widget.onOpenBluetooth,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Image.asset('assests/images/bluetooth_icon.png'),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSettingsUpdateDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings Received'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text('Method: ${data['method']}'),
              Text('Count: ${data['count']}'),
              const SizedBox(height: 8),
              const Text('Filter Times:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(data['filters'] as List<dynamic>).asMap().entries.map(
                    (e) => Text('Filter ${e.key + 1}: ${e.value}'),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final String response;

  const _ResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Response',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2F80ED),
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            response,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallActionBtn(
          label: 'Live Request',
          icon: Icons.refresh_rounded,
          onTap: () {
            context.read<exec.ExecutionBloc>().add(exec.RequestLiveUpdateEvent());
          },
        ),
        const SizedBox(width: 8),
        _SmallActionBtn(
          label: 'View Settings',
          icon: Icons.visibility_outlined,
          onTap: () {
            context.read<exec.ExecutionBloc>().add(exec.RequestViewSettingsEvent());
          },
        ),
      ],
    );
  }
}

class _SmallActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2F80ED).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2F80ED).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF2F80ED)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F80ED),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final int index;
  final FilterConfigModel config;
  final Map<String, dynamic> liveData;

  const _FilterCard({
    required this.index,
    required this.config,
    required this.liveData,
  });

  @override
  Widget build(BuildContext context) {
    final filterNumber = index + 1;
    final setTime = index < config.filters.length
        ? config.filters[index]
        : const FilterEntity(hour: 0, minute: 0, second: 0);
    final setTimeText = TimeUtils.formatFilterTime(setTime);
    
    final activeFilter = liveData['current_filter']?.toString();
    final isSystemOn = liveData['status'] != 'OFF' && liveData['status'] != null;
    final isActive = activeFilter == 'Filter #$filterNumber' && isSystemOn;

    final remainingTime = isActive
        ? (liveData['time']?.toString() ?? '00:00:00')
        : '00:00:00';
    final progress = _calculateProgress(setTimeText, remainingTime, isActive);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8EE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter $filterNumber',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                isActive ? 'On' : 'Off',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              BlocBuilder<BluetoothBloc, BluetoothBlocState>(
                builder: (context, bluetoothState) {
                  final isConnected = bluetoothState is BluetoothConnected;
                  return CupertinoSwitch(
                    value: isActive,
                    activeTrackColor: const Color(0xFFF24836),
                    onChanged: isConnected
                        ? (value) {
                            if (value) {
                              context
                                  .read<exec.ExecutionBloc>()
                                  .add(exec.StartFilterEvent());
                            } else {
                              context
                                  .read<exec.ExecutionBloc>()
                                  .add(exec.StopFilterEvent());
                            }
                          }
                        : null,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusPill(
                color: isActive
                    ? const Color(0xFF22A447) // Green for Active
                    : const Color(0xFFE53935), // Red for In Active
                label: isActive ? 'Active' : 'In Active',
              ),
              const SizedBox(width: 10),
              _InfoPill(label: '${config.method} Mode'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDADADA)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Image.asset(
                      'assests/images/filter_backwash.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 118,
                  color: const Color(0xFFE2E2E2),
                ),
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _TimeInfoCard(
                                title: 'Set Time',
                                value: setTimeText,
                                baseColor: isActive
                                    ? const Color(0xFF679436)
                                    : const Color(0xFFBDC3C7),
                                headerColor: isActive
                                    ? const Color(0xFF53782B)
                                    : const Color(0xFFABB2B9),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _TimeInfoCard(
                                title: 'Time Left',
                                value: remainingTime,
                                baseColor: isActive
                                    ? const Color(0xFF54A8D8)
                                    : const Color(0xFFBDC3C7),
                                headerColor: isActive
                                    ? const Color(0xFF4286AD)
                                    : const Color(0xFFABB2B9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFE7E7E7),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isActive
                                        ? const Color(0xFF5DDA6A)
                                        : const Color(0xFFD6D6D6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(String setTime, String remainingTime, bool isActive) {
    if (!isActive) {
      return 0;
    }

    final totalSeconds = _parseTime(setTime);
    final remainingSeconds = _parseTime(remainingTime);
    if (totalSeconds <= 0) {
      return 0;
    }

    final completed =
        (totalSeconds - remainingSeconds).clamp(0, totalSeconds);
    return completed / totalSeconds;
  }

  int _parseTime(String value) {
    final parts = value.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.length != 3) {
      return 0;
    }
    return (parts[0] * 3600) + (parts[1] * 60) + parts[2];
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusPill({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _TimeInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color baseColor;
  final Color headerColor;

  const _TimeInfoCard({
    required this.title,
    required this.value,
    required this.baseColor,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
