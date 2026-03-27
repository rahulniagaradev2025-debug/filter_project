import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:filter_project/features/filters/domain/usecases/listen_status_usecase.dart';
import 'package:filter_project/features/filters/domain/usecases/start_filter_usecase.dart';
import 'package:filter_project/features/filters/domain/usecases/stop_filter_usecase.dart';
import 'package:filter_project/features/filters/domain/usecases/request_view_settings_usecase.dart';
import 'package:filter_project/features/filters/domain/usecases/request_live_update_usecase.dart';
import 'package:filter_project/core/protocols/response_parser.dart';
import 'package:filter_project/features/filters/data/models/filter_config_model.dart';

part 'execution_event.dart';
part 'execution_state.dart';

class ExecutionBloc extends Bloc<ExecutionEvent, ExecutionState> {
  final ListenStatusUseCase listenStatusUseCase;
  final StartFilterUseCase startFilterUseCase;
  final StopFilterUseCase stopFilterUseCase;
  final RequestViewSettingsUseCase requestViewSettingsUseCase;
  final RequestLiveUpdateUseCase requestLiveUpdateUseCase;

  ExecutionBloc({
    required this.listenStatusUseCase,
    required this.startFilterUseCase,
    required this.stopFilterUseCase,
    required this.requestViewSettingsUseCase,
    required this.requestLiveUpdateUseCase,
  }) : super(ExecutionInitial()) {
    on<ListenStatusEvent>((event, emit) async {
      await emit.forEach(
        listenStatusUseCase(),
        onData: (result) => result.fold(
          (failure) => ExecutionError(failure.message),
          (status) {
            // Try to parse the raw string from hardware
            final parsedResponse = ResponseParser.parse(status);
            
            if (parsedResponse != null && parsedResponse['type'] == 'CONFIG_UPDATE') {
              // If it's configuration data (ID 1, 2, 3, or 4), emit a config state
              return ExecutionConfigReceived(
                parsedResponse['config'] as FilterConfigModel, 
                parsedResponse['payloadId'] as int,
                status // Pass raw string
              );
            }
            
            // Otherwise, fall back to the raw status update
            return ExecutionStatusUpdate(status);
          },
        ),
      );
    });

    on<StartFilterEvent>((event, emit) async {
      final result = await startFilterUseCase();
      result.fold(
        (failure) => emit(ExecutionError(failure.message)),
        (_) => null,
      );
    });

    on<StopFilterEvent>((event, emit) async {
      final result = await stopFilterUseCase();
      result.fold(
        (failure) => emit(ExecutionError(failure.message)),
        (_) => null,
      );
    });

    on<RequestViewSettingsEvent>((event, emit) async {
      final result = await requestViewSettingsUseCase();
      result.fold(
        (failure) => emit(ExecutionError(failure.message)),
        (_) => null,
      );
    });

    on<RequestLiveUpdateEvent>((event, emit) async {
      final result = await requestLiveUpdateUseCase();
      result.fold(
        (failure) => emit(ExecutionError(failure.message)),
        (_) => null,
      );
    });
  }
}
