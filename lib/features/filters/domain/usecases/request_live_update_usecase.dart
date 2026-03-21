import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repository/filter_repository.dart';

class RequestLiveUpdateUseCase {
  final FilterRepository repository;

  RequestLiveUpdateUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.requestLiveUpdate();
  }
}
