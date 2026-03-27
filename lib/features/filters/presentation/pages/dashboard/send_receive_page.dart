import 'package:flutter/material.dart';
import '../../../../../core/bluetooth/bluetooth_service.dart';
import '../../../../../injection_container.dart';

class SendReceivePage extends StatefulWidget {
  const SendReceivePage({super.key});

  @override
  State<SendReceivePage> createState() => _SendReceivePageState();
}

class _SendReceivePageState extends State<SendReceivePage> {
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final AppBluetoothService _bluetoothService = sl<AppBluetoothService>();

  @override
  void initState() {
    super.initState();
    
    // 1. Load existing history immediately so it's not empty when opened
    _logs.addAll(_bluetoothService.logHistory);
    
    // 2. Subscribe to the global data log stream for new entries
    _bluetoothService.dataLogStream.listen((entry) {
      if (mounted) {
        setState(() {
          _logs.add(entry);
        });
        _scrollToBottom();
      }
    });

    // Initial scroll if we have history
    if (_logs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E232C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Communication Logs',
          style: TextStyle(color: Color(0xFF1E232C), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFE53935)),
            onPressed: () {
              setState(() {
                _logs.clear();
                _bluetoothService.clearLogs();
              });
            },
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTerminalHeader(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E232C), // Dark terminal background
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _logs.isEmpty 
                  ? const Center(child: Text("No logs yet...", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return _LogItem(log: log);
                      },
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          const Icon(Icons.terminal_rounded, color: Color(0xFF2F80ED), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Live Console',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A707C),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(backgroundColor: Colors.green, radius: 3),
                SizedBox(width: 6),
                Text(
                  'Monitoring',
                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final LogEntry log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isRes = log.isResponse;
    final color = isRes ? const Color(0xFF4CAF50) : const Color(0xFF2196F3);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isRes ? 'RX ←' : 'TX →',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond.toString().padLeft(3, '0')}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SelectableText(
              log.text.replaceAll('\r', '\\r').replaceAll('\n', '\\n'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
