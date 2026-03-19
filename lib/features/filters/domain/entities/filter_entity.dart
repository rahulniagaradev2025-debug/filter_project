import 'package:equatable/equatable.dart';

class FilterEntity extends Equatable {
  final int hour;
  final int minute;
  final int second;

  const FilterEntity({
    required this.hour,
    required this.minute,
    required this.second,
  });

  @override
  List<Object?> get props => [hour, minute, second];
}
