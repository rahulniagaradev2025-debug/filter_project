import 'package:equatable/equatable.dart';
import 'filter_entity.dart';

class FilterConfigEntity extends Equatable {
  final String method;
  final int filterCount;
  final List<FilterEntity> filters;
  final FilterEntity offTime;
  final FilterEntity initialDelay;
  final FilterEntity delayBetween;
  final FilterEntity dpScanTime;
  final FilterEntity afterFilterDpScanTime;
  final double dpDifferenceValue;

  const FilterConfigEntity({
    required this.method,
    required this.filterCount,
    required this.filters,
    required this.offTime,
    required this.initialDelay,
    required this.delayBetween,
    required this.dpScanTime,
    required this.afterFilterDpScanTime,
    required this.dpDifferenceValue,
  });

  @override
  List<Object?> get props => [
        method,
        filterCount,
        filters,
        offTime,
        initialDelay,
        delayBetween,
        dpScanTime,
        afterFilterDpScanTime,
        dpDifferenceValue,
      ];
}
