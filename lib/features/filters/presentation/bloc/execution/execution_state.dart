part of 'execution_bloc.dart';

abstract class ExecutionState extends Equatable {
  const ExecutionState();

  @override
  List<Object> get props => [];
}

class ExecutionInitial extends ExecutionState {}

class ExecutionStatusUpdate extends ExecutionState {
  final String status;
  const ExecutionStatusUpdate(this.status);

  @override
  List<Object> get props => [status];
}

class ExecutionError extends ExecutionState {
  final String message;
  const ExecutionError(this.message);

  @override
  List<Object> get props => [message];
}
