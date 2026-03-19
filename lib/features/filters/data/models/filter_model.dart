import '../../domain/entities/filter_entity.dart';

class FilterModel extends FilterEntity {
  const FilterModel({
    required super.hour,
    required super.minute,
    required super.second,
  });

  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
      second: json['second'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'second': second,
    };
  }

  factory FilterModel.fromEntity(FilterEntity entity) {
    return FilterModel(
      hour: entity.hour,
      minute: entity.minute,
      second: entity.second,
    );
  }
}
