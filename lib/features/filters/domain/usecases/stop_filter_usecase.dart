import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repository/filter_repository.dart';

class StopFilterUseCase {
  final FilterRepository repository;

  StopFilterUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.stopFilter();
  }
}
