import 'package:get_it/get_it.dart';
import 'core/bluetooth/bluetooth_service.dart';
import 'features/filters/data/datasources/filter_remote_data_source.dart';
import 'features/filters/data/repository/filter_repository_impl.dart';
import 'features/filters/domain/repository/filter_repository.dart';
import 'features/filters/domain/usecases/listen_status_usecase.dart';
import 'features/filters/domain/usecases/send_config_usecase.dart';
import 'features/filters/domain/usecases/start_filter_usecase.dart';
import 'features/filters/domain/usecases/stop_filter_usecase.dart';
import 'features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import 'features/filters/presentation/bloc/filter/filter_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoC
  sl.registerFactory(() => BluetoothBloc(bluetoothService: sl()));
  sl.registerFactory(() => FilterBloc(
        sendConfigUseCase: sl(),
        listenStatusUseCase: sl(),
        startFilterUseCase: sl(),
        stopFilterUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => SendConfigUseCase(sl()));
  sl.registerLazySingleton(() => ListenStatusUseCase(sl()));
  sl.registerLazySingleton(() => StartFilterUseCase(sl()));
  sl.registerLazySingleton(() => StopFilterUseCase(sl()));

  // Repository
  sl.registerLazySingleton<FilterRepository>(
    () => FilterRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<FilterRemoteDataSource>(
    () => FilterRemoteDataSourceImpl(sl()),
  );

  // Core
  sl.registerLazySingleton(() => AppBluetoothService());
}
