import '../../features/filters/domain/entities/filter_entity.dart';

class TimeUtils {
  /// Formats a FilterEntity into a HH:mm:ss string
  static String formatFilterTime(FilterEntity time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Formats total seconds into a HH:mm:ss string
  static String formatSeconds(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Converts total seconds into a FilterEntity
  static FilterEntity secondsToFilterEntity(int totalSeconds) {
    return FilterEntity(
      hour: totalSeconds ~/ 3600,
      minute: (totalSeconds % 3600) ~/ 60,
      second: totalSeconds % 60,
    );
  }

  /// Converts a FilterEntity into total seconds
  static int filterEntityToSeconds(FilterEntity time) {
    return (time.hour * 3600) + (time.minute * 60) + time.second;
  }
}
