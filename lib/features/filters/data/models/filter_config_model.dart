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
    required super.dpValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'filterCount': filterCount,
      'filters': filters.map((e) => FilterModel.fromEntity(e).toJson()).toList(),
      'offTime': offTime,
      'initialDelay': initialDelay,
      'delayBetween': delayBetween,
      'dpValue': dpValue,
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
      dpValue: entity.dpValue,
    );
  }
}
