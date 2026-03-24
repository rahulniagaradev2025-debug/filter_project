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

  factory FilterConfigModel.fromJson(Map<String, dynamic> json) {
    return FilterConfigModel(
      method: json['method']?.toString() ?? 'Time',
      filterCount: json['filterCount'] as int? ?? 0,
      filters: ((json['filters'] as List<dynamic>? ?? const [])
              .map((e) => FilterModel.fromJson(e as Map<String, dynamic>)))
          .toList(),
      offTime: FilterModel.fromJson(
        (json['offTime'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      initialDelay: FilterModel.fromJson(
        (json['initialDelay'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      delayBetween: FilterModel.fromJson(
        (json['delayBetween'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      dpScanTime: FilterModel.fromJson(
        (json['dpScanTime'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      afterFilterDpScanTime: FilterModel.fromJson(
        (json['afterFilterDpScanTime'] as Map<String, dynamic>? ??
            const <String, dynamic>{}),
      ),
      dpDifferenceValue:
          double.tryParse(json['dpDifferenceValue']?.toString() ?? '0') ?? 0,
    );
  }
}
