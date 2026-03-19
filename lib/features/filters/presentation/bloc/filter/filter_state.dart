part of 'filter_bloc.dart';

abstract class FilterState extends Equatable {
  const FilterState();

  @override
  List<Object> get props => [];
}

class FilterInitial extends FilterState {}

class FilterLoading extends FilterState {}

class FilterConfigSent extends FilterState {}

class FilterStatusUpdate extends FilterState {
  final String status;
  const FilterStatusUpdate(this.status);

  @override
  List<Object> get props => [status];
}

class FilterError extends FilterState {
  final String message;
  const FilterError(this.message);

  @override
  List<Object> get props => [message];
}
