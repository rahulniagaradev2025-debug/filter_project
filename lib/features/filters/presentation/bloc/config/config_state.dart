part of 'config_bloc.dart';

abstract class ConfigState extends Equatable {
  const ConfigState();

  @override
  List<Object> get props => [];
}

class ConfigInitial extends ConfigState {}

class ConfigLoading extends ConfigState {}

class ConfigSuccess extends ConfigState {}

class ConfigError extends ConfigState {
  final String message;
  const ConfigError(this.message);

  @override
  List<Object> get props => [message];
}
