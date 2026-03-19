part of 'filter_bloc.dart';

abstract class FilterEvent extends Equatable {
  const FilterEvent();

  @override
  List<Object> get props => [];
}

class SendConfigurationEvent extends FilterEvent {
  final FilterConfigEntity config;
  const SendConfigurationEvent(this.config);

  @override
  List<Object> get props => [config];
}

class ListenStatusEvent extends FilterEvent {}

class StartFilterEvent extends FilterEvent {}

class StopFilterEvent extends FilterEvent {}
