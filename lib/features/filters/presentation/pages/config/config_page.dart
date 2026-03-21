import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/config/config_bloc.dart';
import 'package:filter_project/features/filters/domain/entities/filter_config_entity.dart';
import 'package:filter_project/features/filters/domain/entities/filter_entity.dart';
import '../../widgets/config/filter_input_widget.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  String _selectedMethod = 'Time';
  int _filterCount = 1;

  final List<FilterEntity> _filters = List.generate(
    8,
    (_) => const FilterEntity(hour: 0, minute: 0, second: 0),
  );

  FilterEntity _offTime = const FilterEntity(hour: 0, minute: 0, second: 0);
  FilterEntity _initialDelay = const FilterEntity(hour: 0, minute: 0, second: 0);
  FilterEntity _delayBetween = const FilterEntity(hour: 0, minute: 0, second: 0);
  FilterEntity _dpScanTime = const FilterEntity(hour: 0, minute: 0, second: 0);
  FilterEntity _afterFilterDpScanTime = const FilterEntity(hour: 0, minute: 0, second: 0);
  final TextEditingController _dpDifferenceController = TextEditingController();

  @override
  void dispose() {
    _dpDifferenceController.dispose();
    super.dispose();
  }

  void _updateFilter(int index, {int? h, int? m, int? s}) {
    final current = _filters[index];
    _filters[index] = FilterEntity(
      hour: h ?? current.hour,
      minute: m ?? current.minute,
      second: s ?? current.second,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is ConfigSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration Sent Successfully')),
          );
          Navigator.pop(context);
        } else if (state is ConfigError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Filter Configuration')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDropdownField('Filter Method', ['Time', 'DP', 'Both'], _selectedMethod, (val) {
                setState(() => _selectedMethod = val!);
              }),
              const SizedBox(height: 16),
              _buildNumberField('Filter Count (1-8)', (val) {
                final count = int.tryParse(val) ?? 1;
                if (count >= 1 && count <= 8) setState(() => _filterCount = count);
              }),
              const Divider(height: 32),
              Text('Filter Settings', style: Theme.of(context).textTheme.titleLarge),
              ...List.generate(
                _filterCount,
                (index) => FilterInputWidget(
                  index: index + 1,
                  onHourChanged: (val) => _updateFilter(index, h: val),
                  onMinuteChanged: (val) => _updateFilter(index, m: val),
                  onSecondChanged: (val) => _updateFilter(index, s: val),
                ),
              ),
              const Divider(height: 32),
              Text('Additional Parameters', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildTimeInput('Filter OFF Time', (h, m, s) => _offTime = FilterEntity(hour: h, minute: m, second: s)),
              _buildTimeInput('Filter Initial Delay', (h, m, s) => _initialDelay = FilterEntity(hour: h, minute: m, second: s)),
              _buildTimeInput('Filter Delay Between', (h, m, s) => _delayBetween = FilterEntity(hour: h, minute: m, second: s)),
              _buildTimeInput('Filter Dp Scan Time', (h, m, s) => _dpScanTime = FilterEntity(hour: h, minute: m, second: s)),
              _buildTimeInput('After Filter Dp Scan Time', (h, m, s) => _afterFilterDpScanTime = FilterEntity(hour: h, minute: m, second: s)),
              const SizedBox(height: 12),
              TextField(
                controller: _dpDifferenceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dp Difference Value', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 32),
              BlocBuilder<ConfigBloc, ConfigState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is ConfigLoading
                        ? null
                        : () {
                            final config = FilterConfigEntity(
                              method: _selectedMethod,
                              filterCount: _filterCount,
                              filters: _filters.sublist(0, _filterCount),
                              offTime: _offTime,
                              initialDelay: _initialDelay,
                              delayBetween: _delayBetween,
                              dpScanTime: _dpScanTime,
                              afterFilterDpScanTime: _afterFilterDpScanTime,
                              dpDifferenceValue: double.tryParse(_dpDifferenceController.text) ?? 0.0,
                            );
                            context.read<ConfigBloc>().add(SendConfigurationEvent(config));
                          },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: state is ConfigLoading
                        ? const CircularProgressIndicator()
                        : const Text('Submit Configuration'),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInput(String label, Function(int, int, int) onTimeChanged) {
    int h = 0, m = 0, s = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            Expanded(child: _buildSmallField('Hr', (v) { h = int.tryParse(v) ?? 0; onTimeChanged(h, m, s); })),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallField('Min', (v) { m = int.tryParse(v) ?? 0; onTimeChanged(h, m, s); })),
            const SizedBox(width: 8),
            Expanded(child: _buildSmallField('Sec', (v) { s = int.tryParse(v) ?? 0; onTimeChanged(h, m, s); })),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallField(String label, ValueChanged<String> onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(8)),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(String label, ValueChanged<String> onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: onChanged,
    );
  }
}
