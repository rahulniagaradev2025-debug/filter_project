import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repository/filter_repository.dart';

class StartFilterUseCase {
  final FilterRepository repository;

  StartFilterUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.startFilter();
  }
}
