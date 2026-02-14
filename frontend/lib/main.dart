import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:maxima_rpg/config/theme.dart';
import 'package:maxima_rpg/config/routes.dart';
import 'package:maxima_rpg/config/firebase_options.dart';
import 'package:maxima_rpg/services/auth_service.dart';
import 'package:maxima_rpg/services/socket_service.dart';
import 'package:maxima_rpg/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.web : null,
  );
  runApp(const MaximaRPGApp());
}

/// Root widget for the MAXIMA RPG application.
/// Sets up providers for auth, socket, and Firestore services.
class MaximaRPGApp extends StatelessWidget {
  const MaximaRPGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth service provider – exposes authentication state and methods.
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),

        // Socket service singleton – manages real-time game communication.
        Provider<SocketService>(
          create: (_) => SocketService(),
          dispose: (_, service) => service.disconnect(),
        ),

        // Firebase / Firestore service – handles persistent data CRUD.
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
      ],
      child: MaterialApp(
        title: 'MAXIMA RPG',
        debugShowCheckedModeBanner: false,
        theme: buildRPGTheme(),
        initialRoute: AppRoutes.login,
        onGenerateRoute: generateRoute,
      ),
    );
  }
}
