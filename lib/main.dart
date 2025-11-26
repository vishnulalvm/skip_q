import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/join_queue_screen.dart';
import 'screens/display_screen.dart';
import 'screens/admin_login_screen.dart'; // Added this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

// Router configuration
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/admin-login/:queueId', // Added this route
      builder: (context, state) {
        final queueId = state.pathParameters['queueId']!;
        return AdminLoginScreen(queueId: queueId);
      },
    ),
    GoRoute(
      path: '/admin/:queueId',
      builder: (context, state) {
        final queueId = state.pathParameters['queueId']!;
        return AdminScreen(queueId: queueId);
      },
    ),
    GoRoute(
      path: '/join/:queueId',
      builder: (context, state) {
        final queueId = state.pathParameters['queueId']!;
        return JoinQueueScreen(queueId: queueId);
      },
    ),
    GoRoute(
      path: '/display/:queueId',
      builder: (context, state) {
        final queueId = state.pathParameters['queueId']!;
        return DisplayScreen(queueId: queueId);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Queue Management System',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
