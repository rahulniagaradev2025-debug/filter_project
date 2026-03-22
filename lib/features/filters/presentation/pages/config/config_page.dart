import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:filter_project/features/filters/presentation/bloc/config/config_bloc.dart';
import 'package:filter_project/features/filters/domain/entities/filter_config_entity.dart';
import 'package:filter_project/features/filters/domain/entities/filter_entity.dart';
import '../../widgets/filter_input_widget.dart';

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

  void _showMaxLimitAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Limit Reached'),
        content: const Text('The controller supports a maximum of 8 relays. Please enter a value between 1 and 8.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _updateFilter(int index, int h, int m, int s) {
    setState(() {
      _filters[index] = FilterEntity(hour: h, minute: m, second: s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is ConfigSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configuration Sent Successfully'), behavior: SnackBarBehavior.floating),
          );
          Navigator.pop(context);
        } else if (state is ConfigError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Device Configuration'),
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('General Settings'),
              _buildDropdownField('Filter Method', ['Time', 'DP', 'Both'], _selectedMethod, (val) {
                setState(() => _selectedMethod = val!);
              }),
              const SizedBox(height: 16),
              _buildNumberField('Number of Relays (1-8)', (val) {
                final count = int.tryParse(val);
                if (count != null) {
                  if (count > 8) {
                    _showMaxLimitAlert();
                  } else if (count >= 1) {
                    setState(() => _filterCount = count);
                  }
                }
              }),
              const SizedBox(height: 32),
              _buildSectionHeader('Relay Operation Times'),
              _buildProtocolHintCard(),
              const SizedBox(height: 16),
              ...List.generate(
                _filterCount,
                (index) => FilterInputWidget(
                  index: index + 1,
                  hour: _filters[index].hour,
                  minute: _filters[index].minute,
                  second: _filters[index].second,
                  onTimeChanged: (h, m, s) => _updateFilter(index, h, m, s),
                  label: 'Relay ${index + 1} ON Time',
                ),
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildProtocolHintCard() {
    final payloadGroups = (_filterCount / 4).ceil();
    final relayWord = _filterCount == 1 ? 'relay' : 'relays';
    final packetWord = payloadGroups == 1 ? 'packet' : 'packets';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        'Hardware protocol supports 4 relay timers per settings packet. '
        'The app will send $payloadGroups $packetWord for $_filterCount $relayWord.',
        style: TextStyle(
          color: Colors.blue.shade900,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: ElevatedButton(
            onPressed: state is ConfigLoading
                ? null
                : () {
                    final config = FilterConfigEntity(
                      method: _selectedMethod,
                      filterCount: _filterCount,
                      filters: _filters.sublist(0, _filterCount),
                      offTime: const FilterEntity(hour: 0, minute: 0, second: 0),
                      initialDelay: const FilterEntity(hour: 0, minute: 0, second: 0),
                      delayBetween: const FilterEntity(hour: 0, minute: 0, second: 0),
                      dpScanTime: const FilterEntity(hour: 0, minute: 0, second: 0),
                      afterFilterDpScanTime: const FilterEntity(hour: 0, minute: 0, second: 0),
                      dpDifferenceValue: 0.0,
                    );
                    context.read<ConfigBloc>().add(SendConfigurationEvent(config));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: state is ConfigLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('SEND CONFIGURATION TO DEVICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        );
      },
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade50)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: InputBorder.none, labelStyle: TextStyle(color: Colors.blue.shade900)),
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberField(String label, ValueChanged<String> onChanged, {TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade50)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, border: InputBorder.none, labelStyle: TextStyle(color: Colors.blue.shade900)),
      ),
    );
  }
}
