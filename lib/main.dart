import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';

// Conditional import for web-only URL strategy
import 'url_strategy_stub.dart'
    if (dart.library.html) 'url_strategy_web.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/join_queue_screen.dart';
import 'screens/display_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_conditions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only use path URL strategy on web
  if (kIsWeb) {
    usePathUrlStrategy();
  }

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
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/terms-conditions',
      builder: (context, state) => const TermsConditionsScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SkipQ',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
