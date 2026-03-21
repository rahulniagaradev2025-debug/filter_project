import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/filter_config_entity.dart';
import '../../domain/repository/filter_repository.dart';
import '../datasources/filter_remote_data_source.dart';
import '../models/filter_config_model.dart';

class FilterRepositoryImpl implements FilterRepository {
  final FilterRemoteDataSource remoteDataSource;

  FilterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> sendConfiguration(FilterConfigEntity config) async {
    try {
      final model = FilterConfigModel.fromEntity(config);
      await remoteDataSource.sendConfiguration(model);
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, String>> getSystemStatus() {
    return remoteDataSource.getSystemStatus().map(
      (status) => Right<Failure, String>(status),
    ).handleError((error) {
      return Left<Failure, String>(BluetoothFailure(error.toString()));
    });
  }

  @override
  Future<Either<Failure, void>> startFilter() async {
    try {
      await remoteDataSource.startFilter();
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopFilter() async {
    try {
      await remoteDataSource.stopFilter();
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestViewSettings() async {
    try {
      await remoteDataSource.requestViewSettings();
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestLiveUpdate() async {
    try {
      await remoteDataSource.requestLiveUpdate();
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }
}
