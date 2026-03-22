import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:filter_project/core/utils/excel_util.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTimeRange? _selectedDateRange;
  
  // Dummy data representing historical logs
  // In a real app, this would come from a local database (Sqflite/Hive)
  final List<Map<String, dynamic>> _allLogs = [
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toString(),
      'current_filter': 'Filter #1',
      'system_status': 'ON',
      'remaining_time': '00:05:30'
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toString(),
      'current_filter': 'Filter #2',
      'system_status': 'WAIT',
      'remaining_time': '00:10:00'
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(days: 3)).toString(),
      'current_filter': 'Filter #3',
      'system_status': 'ON',
      'remaining_time': '00:02:15'
    },
    {
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toString(),
      'current_filter': 'Filter #1',
      'system_status': 'ON',
      'remaining_time': '00:08:45'
    },
  ];

  List<Map<String, dynamic>> _filteredLogs = [];

  @override
  void initState() {
    super.initState();
    _filterLogs(3); // Default to last 3 days
  }

  void _filterLogs(int days) {
    setState(() {
      _selectedDateRange = null;
      final now = DateTime.now();
      final cutoff = now.subtract(Duration(days: days));
      _filteredLogs = _allLogs.where((log) {
        final logDate = DateTime.parse(log['timestamp']);
        return logDate.isAfter(cutoff);
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filteredLogs = _allLogs.where((log) {
          final logDate = DateTime.parse(log['timestamp']);
          return logDate.isAfter(picked.start) && 
                 logDate.isBefore(picked.end.add(const Duration(days: 1)));
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _filteredLogs.isEmpty 
              ? null 
              : () => ExcelUtil.generateAndShareReport(_filteredLogs),
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _filteredLogs.isEmpty
                ? _buildEmptyState()
                : _buildLogsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.blue.shade50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('Last 3 Days', () => _filterLogs(3), _selectedDateRange == null),
            const SizedBox(width: 8),
            _filterChip('Selective Range', _selectDateRange, _selectedDateRange != null),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onTap, bool isSelected) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isSelected ? Colors.blue : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.blue),
    );
  }

  Widget _buildLogsList() {
    return ListView.builder(
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        final date = DateTime.parse(log['timestamp']);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: log['system_status'] == 'ON' ? Colors.green : Colors.orange,
              child: const Icon(Icons.history, color: Colors.white),
            ),
            title: Text('${log['current_filter']} - ${log['system_status']}'),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(date)),
            trailing: Text(
              log['remaining_time'],
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No logs found for the selected period.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
