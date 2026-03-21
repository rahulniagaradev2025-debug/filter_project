import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repository/filter_repository.dart';

class RequestViewSettingsUseCase {
  final FilterRepository repository;

  RequestViewSettingsUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.requestViewSettings();
  }
}
