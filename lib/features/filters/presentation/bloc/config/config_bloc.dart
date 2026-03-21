import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/filter_config_entity.dart';
import '../../../domain/usecases/send_config_usecase.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final SendConfigUseCase sendConfigUseCase;

  ConfigBloc({required this.sendConfigUseCase}) : super(ConfigInitial()) {
    on<SendConfigurationEvent>((event, emit) async {
      emit(ConfigLoading());
      final result = await sendConfigUseCase(event.config);
      result.fold(
        (failure) => emit(ConfigError(failure.message)),
        (_) => emit(ConfigSuccess()),
      );
    });
  }
}
