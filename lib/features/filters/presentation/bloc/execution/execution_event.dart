part of 'execution_bloc.dart';

abstract class ExecutionEvent extends Equatable {
  const ExecutionEvent();

  @override
  List<Object> get props => [];
}

class ListenStatusEvent extends ExecutionEvent {}

class StartFilterEvent extends ExecutionEvent {}

class StopFilterEvent extends ExecutionEvent {}

class RequestViewSettingsEvent extends ExecutionEvent {}

class RequestLiveUpdateEvent extends ExecutionEvent {}
