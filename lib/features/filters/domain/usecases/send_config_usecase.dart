import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/filter_config_entity.dart';
import '../repository/filter_repository.dart';

class SendConfigUseCase {
  final FilterRepository repository;

  SendConfigUseCase(this.repository);

  Future<Either<Failure, void>> call(FilterConfigEntity config) {
    return repository.sendConfiguration(config);
  }
}
