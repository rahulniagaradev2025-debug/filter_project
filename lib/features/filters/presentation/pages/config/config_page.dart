import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/filter/filter_bloc.dart';
import 'package:filter_project/features/filters/domain/entities/filter_config_entity.dart';
import 'package:filter_project/features/filters/domain/entities/filter_entity.dart';
import 'package:filter_project/features/filters/presentation/widgets/filter_input_widget.dart';

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

  final TextEditingController _offTimeController = TextEditingController();
  final TextEditingController _initialDelayController = TextEditingController();
  final TextEditingController _delayBetweenController = TextEditingController();
  final TextEditingController _dpValueController = TextEditingController();

  @override
  void dispose() {
    _offTimeController.dispose();
    _initialDelayController.dispose();
    _delayBetweenController.dispose();
    _dpValueController.dispose();
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
    return BlocListener<FilterBloc, FilterState>(
      listener: (context, state) {
        if (state is FilterConfigSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration Sent Successfully')),
          );
          Navigator.pop(context);
        } else if (state is FilterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Filter Configuration'),
        ),
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
                if (count >= 1 && count <= 8) {
                  setState(() => _filterCount = count);
                }
              }),
              const Divider(height: 32),
              Text(
                'Filter Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
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
              Text(
                'Additional Parameters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildTextField('Off Time (Sec)', _offTimeController),
              const SizedBox(height: 12),
              _buildTextField('Initial Delay (Sec)', _initialDelayController),
              const SizedBox(height: 12),
              _buildTextField('Delay Between (Sec)', _delayBetweenController),
              const SizedBox(height: 12),
              _buildTextField('DP Value', _dpValueController),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final config = FilterConfigEntity(
                    method: _selectedMethod,
                    filterCount: _filterCount,
                    filters: _filters.sublist(0, _filterCount),
                    offTime: int.tryParse(_offTimeController.text) ?? 0,
                    initialDelay: int.tryParse(_initialDelayController.text) ?? 0,
                    delayBetween: int.tryParse(_delayBetweenController.text) ?? 0,
                    dpValue: double.tryParse(_dpValueController.text) ?? 0.0,
                  );
                  context.read<FilterBloc>().add(SendConfigurationEvent(config));
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Configuration'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
