import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:filter_project/core/storage/database_helper.dart';
import 'package:filter_project/core/protocols/response_parser.dart';
import 'package:filter_project/core/utils/excel_util.dart';

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
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final dbData = await _dbHelper.getLogs();
      final parsedLogs = <Map<String, dynamic>>[];

      for (var entry in dbData) {
        final text = entry['text'] as String;
        final timestamp = entry['timestamp'] as String;
        
        // Only process incoming responses for the report
        if (entry['isResponse'] == 1) {
          final parsed = ResponseParser.parse(text);
          
          if (parsed != null && parsed['type'] == 'LIVE_STATUS') {
            final data = parsed['data'] as Map<String, dynamic>;
            
            parsedLogs.add({
              'timestamp': timestamp,
              'current_filter': 'Filter #${data['CURRFIL'] ?? '0'}',
              'system_status': _parseStatus(data['SYSSTATUS']),
              'remaining_time': data['REMTIME'] ?? '00:00:00',
            });
          }
        }
      }

      setState(() {
        _logs = parsedLogs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading report logs: $e");
      setState(() => _isLoading = false);
    }
  }

  String _parseStatus(dynamic status) {
    final s = status?.toString();
    if (s == '1') return 'ON';
    if (s == '2') return 'WAIT';
    return 'OFF';
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
      } else {
        _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _logs.where((log) {
      final timestamp = DateTime.parse(log['timestamp'] as String);
      return !timestamp.isBefore(_fromDate) && !timestamp.isAfter(_toDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLogs;
    
    // Calculate chart values based on parsed data
    final powerStatus = filtered.where((log) => log['system_status'] == 'ON').length;
    final motorStatus = filtered.where((log) => log['system_status'] == 'WAIT').length;

    return SafeArea(
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadLogs,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                children: [
                  _buildHeader(filtered),
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
                        const Row(
                          children: [
                            _LegendDot(color: Color(0xFF15B7D6), label: 'Power Status (ON)'),
                            SizedBox(width: 16),
                            _LegendDot(color: Color(0xFF66E31B), label: 'Motor Status (WAIT)'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 250,
                          child: filtered.isEmpty 
                            ? const Center(child: Text("No data for selected period"))
                            : _ReportChart(
                                powerValue: powerStatus,
                                motorValue: motorStatus,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Added a small list preview
                  ...filtered.take(10).map((log) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text("${log['current_filter']} - ${log['system_status']}"),
                      subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(log['timestamp']))),
                      trailing: Text(log['remaining_time']),
                    ),
                  )),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader(List<Map<String, dynamic>> filtered) {
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
          onPressed: filtered.isEmpty
              ? null
              : () => ExcelUtil.generateAndShareReport(filtered),
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
    // Dynamic max value based on data to make it look good
    final double maxValue = (powerValue > motorValue ? powerValue : motorValue).toDouble() + 5;

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
                          : const Color(0xFF6F6F6F).withOpacity(0.2),
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
              maxValue: maxValue == 0 ? 1 : maxValue,
            ),
            const SizedBox(width: 24),
            _ChartBar(
              color: const Color(0xFF66E31B),
              value: motorValue,
              maxValue: maxValue == 0 ? 1 : maxValue,
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
          width: 60,
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
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
