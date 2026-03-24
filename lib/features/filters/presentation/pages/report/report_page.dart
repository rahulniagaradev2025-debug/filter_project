import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/excel_util.dart';

class ReportPage extends StatefulWidget {
  final VoidCallback? onNavigateDashboard;

  const ReportPage({
    super.key,
    this.onNavigateDashboard,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _fromDate = DateTime(2025, 11, 29);
  DateTime _toDate = DateTime(2025, 12, 29);

  final List<Map<String, dynamic>> _logs = [
    {
      'timestamp': DateTime(2025, 12, 3, 10, 0).toString(),
      'current_filter': 'Filter #1',
      'system_status': 'ON',
      'remaining_time': '02:10:00',
    },
    {
      'timestamp': DateTime(2025, 12, 9, 11, 30).toString(),
      'current_filter': 'Filter #2',
      'system_status': 'WAIT',
      'remaining_time': '00:00:00',
    },
    {
      'timestamp': DateTime(2025, 12, 11, 13, 0).toString(),
      'current_filter': 'Filter #3',
      'system_status': 'ON',
      'remaining_time': '01:05:00',
    },
  ];

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _logs.where((log) {
      final timestamp = DateTime.parse(log['timestamp'] as String);
      return !timestamp.isBefore(_fromDate) &&
          !timestamp.isAfter(_toDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final powerStatus = _filteredLogs.where((log) => log['system_status'] == 'ON').length * 95;
    final motorStatus = _filteredLogs.where((log) => log['system_status'] != 'OFF').length * 22;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DateField(
                  label: 'From',
                  value: DateFormat('dd/MM/yyyy').format(_fromDate),
                  onTap: () => _pickDate(true),
                ),
                _DateField(
                  label: 'To',
                  value: DateFormat('dd/MM/yyyy').format(_toDate),
                  onTap: () => _pickDate(false),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      _LegendDot(color: Color(0xFF15B7D6), label: 'Power Status'),
                      SizedBox(width: 16),
                      _LegendDot(color: Color(0xFF66E31B), label: 'Motor Status'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
                    child: _ReportChart(
                      powerValue: powerStatus,
                      motorValue: motorStatus,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            'Report',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: _filteredLogs.isEmpty
              ? null
              : () => ExcelUtil.generateAndShareReport(_filteredLogs),
          icon: Image.asset('assests/icons/download_icon.png', width: 24, height: 24),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD9ECFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF8EBDE9)),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFF767676))),
      ],
    );
  }
}

class _ReportChart extends StatelessWidget {
  final int powerValue;
  final int motorValue;

  const _ReportChart({
    required this.powerValue,
    required this.motorValue,
  });

  @override
  Widget build(BuildContext context) {
    const maxValue = 450.0;

    return Stack(
      children: [
        Column(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: index == 0
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF6F6F6F),
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChartBar(
              color: const Color(0xFF15B7D6),
              value: powerValue,
              maxValue: maxValue,
            ),
            const SizedBox(width: 12),
            _ChartBar(
              color: const Color(0xFF66E31B),
              value: motorValue,
              maxValue: maxValue,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartBar extends StatelessWidget {
  final Color color;
  final int value;
  final double maxValue;

  const _ChartBar({
    required this.color,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final heightFactor = (value / maxValue).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        child: Container(
          width: 46,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
