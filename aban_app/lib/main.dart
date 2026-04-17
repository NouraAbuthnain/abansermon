import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/preferences_service.dart';
import 'core/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Assuming options will be added later or defaults are used for Mock setup)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final prefsService = PreferencesService(prefs);

  // Initialize simple mock dependency injection for MVP
  await di.init();
  await EasyLocalization.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefsService),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar'), Locale('ur'), Locale('bn')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        child: const AbanApp(),
      ),
    ),
  );
}

class AbanApp extends ConsumerWidget {
  const AbanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsCache = ref.watch(settingsProvider);

    return MaterialApp.router(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Aban أبان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsCache.themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settingsCache.textScaleFactor),
          ),
          child: child!,
        );
      },
    );
  }
}
