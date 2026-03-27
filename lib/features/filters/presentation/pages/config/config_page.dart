import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/constants.dart';
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
      AppConstants.maxFilterCount,
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
        content: Text(
          'The maximum number of filters is ${AppConstants.maxFilterCount}. Please enter a value from 1 to ${AppConstants.maxFilterCount}.',
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

    if (count > AppConstants.maxFilterCount) {
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    const Text('Select Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context, tempDuration),
                      child: const Text('Done', style: TextStyle(color: Color(0xFF2F80ED), fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FF),
      body: BlocListener<ConfigBloc, ConfigState>(
        listener: (context, state) {
          if (state is ConfigSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuration saved and sent successfully'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
            widget.onNavigateDashboard?.call();
          } else if (state is ConfigError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('General Settings'),
                      _buildDropdownField(),
                      const SizedBox(height: 12),
                      _buildTextFieldCard(
                        controller: _filterCountController,
                        label: 'Number of Relays',
                        hint: 'Enter 1-${AppConstants.maxFilterCount}',
                        keyboardType: TextInputType.number,
                        onChanged: _onFilterCountChanged,
                        icon: Icons.numbers_rounded,
                      ),
                      const SizedBox(height: 24),
                      if (_filterCount > 0) ...[
                        _buildSectionHeader('Filter Settings'),
                        ...List.generate(_filterCount, (i) => Column(
                          children: [
                            _buildTimeField(
                              label: 'Filter ${i + 1} On Time',
                              value: _formatTime(_filters[i]),
                              onTap: () => _pickFilterTime(i),
                              icon: Icons.timer_outlined,
                            ),
                            const SizedBox(height: 12),
                          ],
                        )),
                        const SizedBox(height: 12),
                      ],
                      _buildSectionHeader('Common Settings'),
                      _buildTimeField(
                        label: 'Filter Off Time',
                        value: _formatTime(_offTime),
                        onTap: () => _pickCommonTime(
                          _offTime,
                          (value) => _offTime = value,
                        ),
                        icon: Icons.power_settings_new_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeField(
                        label: 'Initial Delay',
                        value: _formatTime(_initialDelay),
                        onTap: () => _pickCommonTime(
                          _initialDelay,
                          (value) => _initialDelay = value,
                        ),
                        icon: Icons.hourglass_top_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeField(
                        label: 'Delay Between',
                        value: _formatTime(_delayBetween),
                        onTap: () => _pickCommonTime(
                          _delayBetween,
                          (value) => _delayBetween = value,
                        ),
                        icon: Icons.sync_problem_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildTimeField(
                        label: 'DP Scan Time',
                        value: _formatTime(_dpScanTime),
                        onTap: () => _pickCommonTime(
                          _dpScanTime,
                          (value) => _dpScanTime = value,
                        ),
                        icon: Icons.analytics_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFieldCard(
                        controller: _flowController,
                        label: 'Calc Flow 3Phase',
                        hint: 'Enter value',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        icon: Icons.waves_rounded,
                      ),
                      const SizedBox(height: 40),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onNavigateDashboard,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E232C)),
          ),
          const Expanded(
            child: Text(
              'Configuration',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E232C),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E232C),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: _cardDecoration(),
      child: DropdownButtonFormField<String>(
        value: _selectedMethod,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2F80ED)),
        decoration: const InputDecoration(
          labelText: 'Filter Method',
          labelStyle: TextStyle(color: Color(0xFF6A707C)),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.settings_suggest_rounded, color: Color(0xFF2F80ED)),
        ),
        items: const [
          DropdownMenuItem(value: 'Time', child: Text('Time Based')),
          DropdownMenuItem(value: 'DP', child: Text('DP Based')),
          DropdownMenuItem(value: 'Both', child: Text('Both (Time & DP)')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedMethod = value);
        },
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2F80ED), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E232C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F80ED),
                  fontSize: 14,
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
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: _cardDecoration(),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF6A707C)),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFF2F80ED)),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<ConfigBloc, ConfigState>(
        builder: (context, state) {
          return ElevatedButton(
            onPressed: state is ConfigLoading ? null : _saveAndSendConfig,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: state is ConfigLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save & Send Configuration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
