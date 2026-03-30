import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/execution/execution_bloc.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Responses'),
        backgroundColor: const Color(0xFFEAF5FF),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFEAF5FF),
      body: BlocBuilder<ExecutionBloc, ExecutionState>(
        builder: (context, state) {
          // We can maintain a list of recent responses in the state 
          // or just show the last one for now if that's all the bloc keeps.
          String displayData = "Waiting for data...";
          if (state is ExecutionStatusUpdate) {
            displayData = state.status;
            print("Received data: $displayData");
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Raw Payload from Device:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    displayData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Note: This shows the raw ASCII strings received via Bluetooth notifications.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
