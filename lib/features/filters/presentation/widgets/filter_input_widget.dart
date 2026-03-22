import 'package:flutter/material.dart';

class FilterInputWidget extends StatelessWidget {
  final int index;
  final int hour;
  final int minute;
  final int second;
  final Function(int, int, int) onTimeChanged;
  final String label;

  const FilterInputWidget({
    super.key,
    required this.index,
    required this.hour,
    required this.minute,
    required this.second,
    required this.onTimeChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = label.isNotEmpty ? label : 'Filter $index On Time';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (index > 0) ...[
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        index.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    displayLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.access_time_rounded, color: Colors.blue, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showDurationPicker(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timeUnit(hour.toString().padLeft(2, '0'), 'HR'),
                  _separator(),
                  _timeUnit(minute.toString().padLeft(2, '0'), 'MIN'),
                  _separator(),
                  _timeUnit(second.toString().padLeft(2, '0'), 'SEC'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade300),
        ),
      ],
    );
  }

  Widget _separator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  void _showDurationPicker(BuildContext context) {
    int h = hour;
    int m = minute;
    int s = second;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Set Duration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pickerField("Hr", h, (v) => h = v),
                  _pickerField("Min", m, (v) => m = v),
                  _pickerField("Sec", s, (v) => s = v),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    onTimeChanged(h, m, s);
                    Navigator.pop(context);
                  },
                  child: const Text("SET TIME", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pickerField(String label, int initialValue, Function(int) onChanged) {
    return SizedBox(
      width: 70,
      child: TextFormField(
        initialValue: initialValue.toString(),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
      ),
    );
  }
}
