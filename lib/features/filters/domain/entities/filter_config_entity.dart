import 'package:equatable/equatable.dart';
import 'filter_entity.dart';

class FilterConfigEntity extends Equatable {
  final String method;
  final int filterCount;
  final List<FilterEntity> filters;
  final int offTime;
  final int initialDelay;
  final int delayBetween;
  final double dpValue;

  const FilterConfigEntity({
    required this.method,
    required this.filterCount,
    required this.filters,
    required this.offTime,
    required this.initialDelay,
    required this.delayBetween,
    required this.dpValue,
  });

  @override
  List<Object?> get props => [
        method,
        filterCount,
        filters,
        offTime,
        initialDelay,
        delayBetween,
        dpValue,
      ];
}
