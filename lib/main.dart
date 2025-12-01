import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:jagar/providers/event_provider.dart';
import 'package:jagar/providers/scan_history_provider.dart';
import 'package:jagar/providers/ticket_provider.dart';
import 'package:jagar/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('id_ID', null);
  runApp(const JagadBadungApp());
}

class JagadBadungApp extends StatelessWidget {
  const JagadBadungApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => ScanHistoryProvider()),
      ],
      child: MaterialApp(
        title: 'Jagad Badung Events',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}