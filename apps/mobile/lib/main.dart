import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'
    show
        kIsWeb,
        kDebugMode,
        defaultTargetPlatform,
        TargetPlatform,
        PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:limousineexecutive/driver/models/driver_state.dart';
import 'package:limousineexecutive/driver/pages/driver_profile.dart';
import 'package:limousineexecutive/driver/pages/initial_page_driver.dart';
import 'package:limousineexecutive/driver/pages/menu_page.dart';
import 'package:limousineexecutive/driver/pages/my_gain.dart';
import 'package:limousineexecutive/driver/pages/my_rides.dart';
import 'package:limousineexecutive/driver/pages/ratings_page.dart';
import 'package:limousineexecutive/passenger/models/passenger_state.dart';
import 'package:limousineexecutive/passenger/pages/splash_page.dart';
import 'package:limousineexecutive/repositories/auth_repository.dart';
import 'package:limousineexecutive/repositories/firebase_auth_repository.dart';
import 'package:limousineexecutive/repositories/trip_repository.dart';
import 'package:limousineexecutive/repositories/firebase_trip_repository.dart';
import 'package:provider/provider.dart';
import 'authentication/otp_verification.dart';
import 'passenger/pages/my_locations_page.dart';
import 'passenger/pages/passenger_home_page.dart';
import 'passenger/pages/discount_page.dart';
import 'passenger/pages/information_page.dart';
import 'authentication/phone_number_page.dart';
import 'passenger/pages/menu_page.dart';
import 'passenger/pages/settings_page.dart';
import 'passenger/pages/user_profile_page.dart';
import 'passenger/pages/payment_methods_page.dart';
import 'passenger/pages/support_page.dart';
import 'passenger/pages/security_page.dart';
import 'passenger/pages/notifications_page.dart';
import 'passenger/pages/contact_us_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'services/messaging_service.dart';
import 'shared/pages/chat_page.dart';

// Global notifications plugin instance (shared with MessagingService)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    MessagingService.localNotifications;

// Global navigator key so notification tap handlers can navigate without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Route a tapped notification to the correct screen. Driver-targeted events
/// (e.g. a new trip request) push to the driver home; passenger-targeted events
/// (status updates on their trip) push to the passenger home.
void _handleNotificationTap(NotificationPayload payload) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  switch (payload.type) {
    case 'new_trip':
      if (payload.tripId != null) {
        // Find DriverState and trigger ringing logic
        Provider.of<DriverState>(
          context,
          listen: false,
        ).handleNewTripRequest(payload.tripId!);
      }
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/driver_home',
        (r) => false,
      );
      break;
    case 'trip_accepted':
    case 'trip_started':
    case 'trip_completed':
    case 'trip_cancelled':
      final isDriver = Provider.of<DriverState>(context, listen: false).isOnline;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        isDriver ? '/driver_home' : '/passenger_home',
        (r) => false,
      );
      break;
    case 'chat_message':
      if (payload.tripId != null) {
        // We might need extra info here, but let's assume we can fetch it or pass it in payload
        // Alternatively, push to home and the state will handle showing the button
        // For direct navigation, we need otherUserName/PhotoUrl which are not in the basic payload yet.
        // For now, let's just go home where the user can see the chat button.
        final userType = Provider.of<PassengerState>(context, listen: false).tripStatus.isNotEmpty ? 'passenger' : 'driver';
        navigatorKey.currentState?.pushNamed(
          userType == 'passenger' ? '/passenger_home' : '/driver_home'
        );
      }
      break;
  }
}

/// Set with `--dart-define=USE_EMULATORS=true` to run the app against the local
/// Firebase emulator suite instead of production.
const bool kUseEmulators = bool.fromEnvironment('USE_EMULATORS');

/// Wires the Firebase SDKs to the local emulator suite. Android emulators reach
/// the host machine via 10.0.2.2; everything else (iOS sim, web, desktop) uses
/// localhost.
Future<void> _connectEmulators() async {
  final String host =
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? '10.0.2.2'
          : 'localhost';
  FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

void main() async {
  // Ensure Flutter is initialized before running async code
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Mantém o splash nativo visível até o SplashScreen do Flutter desenhar o
  // seu primeiro frame — evita os dois splashes (nativo + Flutter) a
  // aparecerem sobrepostos por instantes durante a transição.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Lock rotation: portrait only
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white, // navigation bar colour
      systemNavigationBarIconBrightness: Brightness.dark, // icon colour
      statusBarColor: Colors.transparent, // status bar colour
      statusBarIconBrightness: Brightness.dark, // status bar icon colour
    ),
  );

  final FirebaseOptions firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(
    // Under emulators, point at the `ya-app-z-default-rtdb` namespace — the
    // default RTDB instance where the functions' admin.database() and the DB
    // triggers attach (same as production). Using the bare `ya-app-z` namespace
    // leaves writes invisible to triggers.
    options: kUseEmulators
        ? firebaseOptions.copyWith(
            databaseURL: 'https://ya-app-z-default-rtdb.firebaseio.com',
          )
        : firebaseOptions,
  );
  if (kUseEmulators) await _connectEmulators();

  // Crash reporting: capture Flutter and platform errors in release builds.
  if (!kIsWeb && !kUseEmulators && !kDebugMode) {
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await initializeDateFormatting('pt_BR');

  // Skip local notifications & FCM on web (not supported / causes errors)
  if (!kIsWeb) {
    // Android initial configuration
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initial configuration
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = NotificationPayload.tryParse(response.payload);
        if (payload != null) _handleNotificationTap(payload);
      },
    );

    // Wire the FCM tap handler (background + cold-start) through the same router
    MessagingService.onNotificationTap = _handleNotificationTap;

    // Initialize Firebase Cloud Messaging
    await MessagingService.initialize();
  }

  // App Check: debug provider for local dev/emulators, real attestation in
  // release builds (Play Integrity on Android, DeviceCheck on iOS).
  // Skipped on web: activate() without a webProvider (reCAPTCHA, ainda não
  // configurado) lança antes do runApp e o app fica preso no splash HTML.
  if (!kIsWeb) {
    final bool useDebugAppCheck = kDebugMode || kUseEmulators;
    await FirebaseAppCheck.instance.activate(
      androidProvider: useDebugAppCheck
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider:
          useDebugAppCheck ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  }

  runApp(
    // For responsiveness
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, __) {
        return MultiProvider(
          providers: [
            Provider<IAuthRepository>(create: (_) => FirebaseAuthRepository()),
            Provider<ITripRepository>(create: (_) => FirebaseTripRepository()),
            ChangeNotifierProvider(
              create: (context) => DriverState(
                repository: Provider.of<ITripRepository>(context, listen: false),
              ),
            ),
            ChangeNotifierProvider(
              create: (context) => PassengerState(
                repository: Provider.of<ITripRepository>(context, listen: false),
                auth: Provider.of<IAuthRepository>(context, listen: false),
              ),
            ),
          ],
          child: const MyApp(),
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Ya',
      home: const SplashScreen(),
      routes: {
        // Autenticacao
        '/login': (context) => const PhoneNumberPage(),
        '/otp_verification': (context) => const OtpVerification(),

        // Passanger Routes
        '/passenger_home': (context) => const PassengerHomePage(),
        '/user_profile': (context) => const UserProfilePage(),
        '/menu': (context) => const PassengerMenuPage(),
        '/information': (context) => const InformationPage(),
        '/settings': (context) => const SettingsPage(),
        '/my_locations': (context) => const LocationsPage(),
        '/discount': (context) => const DiscountPage(),

        // Driver Routes
        '/driver_home': (context) => const DriverHomePage(),
        '/driver_menu': (context) => const DriverMenuPage(),
        '/driver_profile': (context) => const DriverProfile(),
        '/my_rides': (context) => const MyRidesPage(),
        '/my_gain': (context) => const MyGainPage(),
        '/ratings': (context) => const RatingsPage(),

        // Common Shared Screens
        '/payment_methods': (context) => const PaymentMethodsPage(),
        '/support': (context) => const SupportPage(),
        '/security': (context) => const SecurityPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/contact_us': (context) => const ContactUsPage(),
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatPage(
            tripId: args['tripId'],
            currentUserUid: args['currentUserUid'],
            currentUserType: args['currentUserType'],
            otherUserName: args['otherUserName'],
            otherUserPhotoUrl: args['otherUserPhotoUrl'],
          );
        },
      },
    );
  }
}
