import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/filter_config_entity.dart';

abstract class FilterRepository {
  Future<Either<Failure, void>> sendConfiguration(FilterConfigEntity config);
  Stream<Either<Failure, String>> getSystemStatus();
  Future<Either<Failure, void>> startFilter();
  Future<Either<Failure, void>> stopFilter();
  Future<Either<Failure, void>> requestViewSettings();
  Future<Either<Failure, void>> requestLiveUpdate();
}
