import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import 'features/filters/presentation/bloc/config/config_bloc.dart';
import 'features/filters/presentation/bloc/execution/execution_bloc.dart';
import 'features/filters/presentation/pages/dashboard/dashboard_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<BluetoothBloc>()),
        BlocProvider(create: (_) => di.sl<ConfigBloc>()),
        BlocProvider(create: (_) => di.sl<ExecutionBloc>()..add(ListenStatusEvent())),
      ],
      child: MaterialApp(
        title: 'Filter Control System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const DashboardPage(),
      ),
    );
  }
}
