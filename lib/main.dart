import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/storage/app_config_preferences.dart';
import 'core/storage/auth_preferences.dart';
import 'features/filters/presentation/bloc/bluetooth/bluetooth_bloc.dart';
import 'features/filters/presentation/bloc/config/config_bloc.dart';
import 'features/filters/presentation/bloc/execution/execution_bloc.dart';
import 'features/filters/presentation/pages/auth/login_page.dart';
import 'features/filters/presentation/pages/dashboard/dashboard_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await AppConfigPreferences.instance.init();
  await AuthPreferences.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthPreferences.instance.isLoggedIn();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<BluetoothBloc>()),
        BlocProvider(create: (_) => di.sl<ConfigBloc>()),
        BlocProvider(create: (_) => di.sl<ExecutionBloc>()..add(ListenStatusEvent())),
      ],
      child: MaterialApp(
        title: 'FLITER BACKWASH (BLE)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F80ED)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFEAF5FF),
          fontFamily: 'Roboto',
        ),
        home: isLoggedIn ? const DashboardPage() : const LoginPage(),
      ),
    );
  }
}
