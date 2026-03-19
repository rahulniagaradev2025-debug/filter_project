import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/filter_config_entity.dart';
import '../../../domain/usecases/send_config_usecase.dart';
import '../../../domain/usecases/listen_status_usecase.dart';
import '../../../domain/usecases/start_filter_usecase.dart';
import '../../../domain/usecases/stop_filter_usecase.dart';

part 'filter_event.dart';
part 'filter_state.dart';

class FilterBloc extends Bloc<FilterEvent, FilterState> {
  final SendConfigUseCase sendConfigUseCase;
  final ListenStatusUseCase listenStatusUseCase;
  final StartFilterUseCase startFilterUseCase;
  final StopFilterUseCase stopFilterUseCase;

  FilterBloc({
    required this.sendConfigUseCase,
    required this.listenStatusUseCase,
    required this.startFilterUseCase,
    required this.stopFilterUseCase,
  }) : super(FilterInitial()) {
    on<SendConfigurationEvent>((event, emit) async {
      emit(FilterLoading());
      final result = await sendConfigUseCase(event.config);
      result.fold(
        (failure) => emit(FilterError(failure.message)),
        (_) => emit(FilterConfigSent()),
      );
    });

    on<ListenStatusEvent>((event, emit) async {
      await emit.forEach(
        listenStatusUseCase(),
        onData: (result) => result.fold(
          (failure) => FilterError(failure.message),
          (status) => FilterStatusUpdate(status),
        ),
      );
    });

    on<StartFilterEvent>((event, emit) async {
      final result = await startFilterUseCase();
      result.fold(
        (failure) => emit(FilterError(failure.message)),
        (_) => null, // Status will be updated via listenStatusUseCase
      );
    });

    on<StopFilterEvent>((event, emit) async {
      final result = await stopFilterUseCase();
      result.fold(
        (failure) => emit(FilterError(failure.message)),
        (_) => null,
      );
    });
  }
}
