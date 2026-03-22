import 'package:flutter/material.dart';

class FilterInputWidget extends StatelessWidget {
  final int index;
  final ValueChanged<int>? onHourChanged;
  final ValueChanged<int>? onMinuteChanged;
  final ValueChanged<int>? onSecondChanged;

  const FilterInputWidget({
    super.key,
    required this.index,
    this.onHourChanged,
    this.onMinuteChanged,
    this.onSecondChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter $index',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildTimeField(context, 'Hour', onHourChanged)

                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeField(context, 'Min', onMinuteChanged),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimeField(context, 'Sec', onSecondChanged),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(BuildContext context, String label, ValueChanged<int>? onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged(int.tryParse(value) ?? 0);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
