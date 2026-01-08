import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:flutter_localizations/flutter_localizations.dart";
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme/app_theme.dart';
import 'config/localization/app_localizations.dart';
import 'routes/app_routes.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize Storage Service
  await StorageService.initialize();

  runApp(
    ProviderScope(
      child: MobileTradeApp(prefs: prefs),
    ),
  );
}

class MobileTradeApp extends ConsumerWidget {
  final SharedPreferences prefs;

  const MobileTradeApp({
    Key? key,
    required this.prefs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'MobileTrade Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light, // Can be changed from settings
          
          // Localization
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'DZ'), // Arabic - Algeria
            Locale('en', 'US'), // English - United States
          ],
          locale: const Locale('ar', 'DZ'),
          
          // Routes
          home: _buildHome(ref),
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }

  Widget _buildHome(WidgetRef ref) {
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return const LoginScreen();
    }

    // Initialize sync in background
    Future.microtask(() {
      final syncService = ref.read(syncServiceProvider);
      syncService.startPeriodicSync();
    });

    return const DashboardScreen();
  }
}

// Placeholder Screens (سيتم إنشاؤها لاحقاً)
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Login Screen'),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Dashboard Screen'),
      ),
    );
  }
}
