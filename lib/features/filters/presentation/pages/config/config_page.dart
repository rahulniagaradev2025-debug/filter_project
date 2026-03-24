import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/storage/app_config_preferences.dart';
import '../../../domain/entities/filter_config_entity.dart';
import '../../../domain/entities/filter_entity.dart';
import '../../bloc/config/config_bloc.dart';

class ConfigPage extends StatefulWidget {
  final VoidCallback? onNavigateDashboard;

  const ConfigPage({
    super.key,
    this.onNavigateDashboard,
  });

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _preferences = AppConfigPreferences.instance;
  final _filterCountController = TextEditingController();
  final _flowController = TextEditingController(text: '0');

  String _selectedMethod = 'Time';
  int _filterCount = 0;
  late List<FilterEntity> _filters;
  FilterEntity _offTime = const FilterEntity(hour: 0, minute: 0, second: 0);
  FilterEntity _initialDelay = const FilterEntity(hour: 0, minute: 0, second: 0);
  FilterEntity _delayBetween = const FilterEntity(hour: 0, minute: 0, second: 0);
  FilterEntity _dpScanTime = const FilterEntity(hour: 0, minute: 0, second: 0);

  @override
  void initState() {
    super.initState();
    _filters = List.generate(
      8,
      (_) => const FilterEntity(hour: 0, minute: 0, second: 0),
    );
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final config = await _preferences.loadSavedConfig();
    if (!mounted || config == null) {
      return;
    }

    setState(() {
      _selectedMethod = config.method;
      _filterCount = config.filterCount;
      _filterCountController.text =
          _filterCount == 0 ? '' : _filterCount.toString();
      for (var i = 0; i < config.filters.length && i < _filters.length; i++) {
        _filters[i] = config.filters[i];
      }
      _offTime = config.offTime;
      _initialDelay = config.initialDelay;
      _delayBetween = config.delayBetween;
      _dpScanTime = config.dpScanTime;
      _flowController.text = config.dpDifferenceValue.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _filterCountController.dispose();
    _flowController.dispose();
    super.dispose();
  }

  Future<void> _showMaxLimitAlert() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Limit Reached'),
        content: const Text(
          'The maximum number of filters is 8. Please enter a value from 1 to 8.',
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

  void _onFilterCountChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() => _filterCount = 0);
      return;
    }

    final count = int.tryParse(value);
    if (count == null) {
      return;
    }

    if (count > 8) {
      _filterCountController.text = _filterCount == 0 ? '' : _filterCount.toString();
      _filterCountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _filterCountController.text.length),
      );
      _showMaxLimitAlert();
      return;
    }

    if (count >= 0) {
      setState(() => _filterCount = count);
    }
  }

  Future<void> _pickFilterTime(int index) async {
    final current = _filters[index];
    final picked = await _pickTime(current);
    if (picked == null) {
      return;
    }

    setState(() => _filters[index] = picked);
  }

  Future<void> _pickCommonTime(
    FilterEntity current,
    ValueChanged<FilterEntity> onChanged,
  ) async {
    final picked = await _pickTime(current);
    if (picked == null) {
      return;
    }

    setState(() => onChanged(picked));
  }

  Future<FilterEntity?> _pickTime(FilterEntity current) async {
    Duration tempDuration = Duration(
      hours: current.hour,
      minutes: current.minute,
      seconds: current.second,
    );

    final picked = await showModalBottomSheet<Duration>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, tempDuration),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: tempDuration,
                  onTimerDurationChanged: (duration) {
                    tempDuration = duration;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked == null) {
      return null;
    }

    return FilterEntity(
      hour: picked.inHours,
      minute: picked.inMinutes % 60,
      second: picked.inSeconds % 60,
    );
  }

  String _formatTime(FilterEntity time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  FilterConfigEntity _buildConfig() {
    return FilterConfigEntity(
      method: _selectedMethod,
      filterCount: _filterCount,
      filters: _filters.sublist(0, _filterCount),
      offTime: _offTime,
      initialDelay: _initialDelay,
      delayBetween: _delayBetween,
      dpScanTime: _dpScanTime,
      afterFilterDpScanTime: const FilterEntity(hour: 0, minute: 0, second: 0),
      dpDifferenceValue: double.tryParse(_flowController.text) ?? 0,
    );
  }

  Future<void> _saveAndSendConfig() async {
    final config = _buildConfig();
    await _preferences.saveConfig(config);
    if (!mounted) {
      return;
    }
    context.read<ConfigBloc>().add(SendConfigurationEvent(config));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is ConfigSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration saved and sent successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onNavigateDashboard?.call();
        } else if (state is ConfigError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 26),
              const Text('General Settings', style: _sectionTitleStyle),
              const SizedBox(height: 12),
              _buildDropdownField(),
              const SizedBox(height: 10),
              _buildTextFieldCard(
                controller: _filterCountController,
                label: 'Enter number of relays(1-8)',
                keyboardType: TextInputType.number,
                onChanged: _onFilterCountChanged,
              ),
              const SizedBox(height: 18),
              if (_filterCount > 0) ...[
                for (var i = 0; i < _filterCount; i++) ...[
                  Text('Filter ${i + 1}', style: _sectionTitleStyle),
                  const SizedBox(height: 10),
                  _buildTimeField(
                    label: 'Filter ${i + 1} On Time',
                    value: _formatTime(_filters[i]),
                    onTap: () => _pickFilterTime(i),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              const Text('Common Settings', style: _sectionTitleStyle),
              const SizedBox(height: 10),
              _buildTimeField(
                label: 'Filter Off Time',
                value: _formatTime(_offTime),
                onTap: () => _pickCommonTime(
                  _offTime,
                  (value) => _offTime = value,
                ),
              ),
              const SizedBox(height: 10),
              _buildTimeField(
                label: 'Filter Initial Delay',
                value: _formatTime(_initialDelay),
                onTap: () => _pickCommonTime(
                  _initialDelay,
                  (value) => _initialDelay = value,
                ),
              ),
              const SizedBox(height: 10),
              _buildTimeField(
                label: 'Filter Delay Between',
                value: _formatTime(_delayBetween),
                onTap: () => _pickCommonTime(
                  _delayBetween,
                  (value) => _delayBetween = value,
                ),
              ),
              const SizedBox(height: 10),
              _buildTimeField(
                label: 'Filter Dp Scan Time',
                value: _formatTime(_dpScanTime),
                onTap: () => _pickCommonTime(
                  _dpScanTime,
                  (value) => _dpScanTime = value,
                ),
              ),
              const SizedBox(height: 10),
              _buildTextFieldCard(
                controller: _flowController,
                label: 'Calc Flow 3Phase',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<ConfigBloc, ConfigState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is ConfigLoading ? null : _saveAndSendConfig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80ED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state is ConfigLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Settings',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onNavigateDashboard,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const Expanded(
          child: Text(
            'Device Configuration',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _cardDecoration(),
      child: DropdownButtonFormField<String>(
        value: _selectedMethod,
        decoration: const InputDecoration(
          labelText: 'Filter Method',
          border: InputBorder.none,
        ),
        items: const [
          DropdownMenuItem(value: 'Time', child: Text('Time')),
          DropdownMenuItem(value: 'DP', child: Text('DP')),
          DropdownMenuItem(value: 'Both', child: Text('Both')),
        ],
        onChanged: (value) {
          if (value == null) {
            return;
          }
          setState(() => _selectedMethod = value);
        },
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD9D9D9)),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8A8A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _cardDecoration(),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFA6D6FF)),
    );
  }
}

const _sectionTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w500,
  color: Color(0xFF303030),
);
