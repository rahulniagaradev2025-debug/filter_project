part of 'config_bloc.dart';

abstract class ConfigEvent extends Equatable {
  const ConfigEvent();

  @override
  List<Object> get props => [];
}

class SendConfigurationEvent extends ConfigEvent {
  final FilterConfigEntity config;
  const SendConfigurationEvent(this.config);

  @override
  List<Object> get props => [config];
}
