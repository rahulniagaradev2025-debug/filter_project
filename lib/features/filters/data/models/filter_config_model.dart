import '../../domain/entities/filter_config_entity.dart';
import 'filter_model.dart';

class FilterConfigModel extends FilterConfigEntity {
  const FilterConfigModel({
    required super.method,
    required super.filterCount,
    required super.filters,
    required super.offTime,
    required super.initialDelay,
    required super.delayBetween,
    required super.dpScanTime,
    required super.afterFilterDpScanTime,
    required super.dpDifferenceValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'filterCount': filterCount,
      'filters': filters.map((e) => FilterModel.fromEntity(e).toJson()).toList(),
      'offTime': FilterModel.fromEntity(offTime).toJson(),
      'initialDelay': FilterModel.fromEntity(initialDelay).toJson(),
      'delayBetween': FilterModel.fromEntity(delayBetween).toJson(),
      'dpScanTime': FilterModel.fromEntity(dpScanTime).toJson(),
      'afterFilterDpScanTime': FilterModel.fromEntity(afterFilterDpScanTime).toJson(),
      'dpDifferenceValue': dpDifferenceValue,
    };
  }

  factory FilterConfigModel.fromEntity(FilterConfigEntity entity) {
    return FilterConfigModel(
      method: entity.method,
      filterCount: entity.filterCount,
      filters: entity.filters,
      offTime: entity.offTime,
      initialDelay: entity.initialDelay,
      delayBetween: entity.delayBetween,
      dpScanTime: entity.dpScanTime,
      afterFilterDpScanTime: entity.afterFilterDpScanTime,
      dpDifferenceValue: entity.dpDifferenceValue,
    );
  }
}
