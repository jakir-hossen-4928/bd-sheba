import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';

import 'models/service_model.dart';
import 'providers/services_provider.dart';
import 'providers/history_provider.dart';
import 'providers/update_provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_wrapper.dart';
import 'widgets/error_view.dart';
import 'utils/ad_helper.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Framework Error Handler (Handles build/rendering errors)
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('Caught Framework Error: ${details.exception}');
    };

    // 2. Global Error Widget (The screen users see on crash)
    ErrorWidget.builder = (details) => ErrorView(errorDetails: details);

    // 3. Platform/Async Error Handler
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Caught Global Async Error: $error');
      // Show error view if possible or log it
      return true;
    };

    // Initialize AdMob
    await MobileAds.instance.initialize();

    // Configure Test Device ID for development
    // MobileAds.instance.updateRequestConfiguration(
    //   RequestConfiguration(testDeviceIds: ['AD8FDFD6D93DCF73FCE563DC591442D7']),
    // );

    AdHelper.loadAppOpenAd();

    // Initialize Hive
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ServiceAdapter());
    }

    final servicesBox = await Hive.openBox<Service>('services');
    final historyBox = await Hive.openBox<String>('history');

    // Initialize Shared Preferences
    final sharedPrefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(sharedPrefs),
          servicesBoxProvider.overrideWithValue(servicesBox),
          historyBoxProvider.overrideWithValue(historyBox),
        ],
        child: const MainApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('CRITICAL STARTUP ERROR: $e');
    debugPrint(stack.toString());

    // Ensure we still run the app but show an error view
    runApp(
      MaterialApp(
        home: ErrorView(
          errorDetails: FlutterErrorDetails(
            exception: e,
            stack: stack,
            library: 'Startup',
            context: ErrorDescription('during app initialization'),
          ),
        ),
      ),
    );
  }
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show App Open Ad on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdHelper.showAppOpenAdIfAvailable();
      _checkForUpdate();
      ref.read(updateProvider.notifier).checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android)) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      if (e is PlatformException &&
          e.code == 'TASK_FAILURE' &&
          e.message?.contains('-9') == true) {
        debugPrint(
          'In-app update check failed: Play Store not found. Skipping update check.',
        );
      } else {
        debugPrint('In-app update check failed: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdHelper.showAppOpenAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BD Sheba',
      theme: AppTheme.light(settings.locale),
      darkTheme: AppTheme.dark(settings.locale),
      themeMode: settings.themeMode,
      locale: settings.locale,
      home: const MainWrapper(),
    );
  }
}
