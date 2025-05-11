//import packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
//imports as
import 'package:timezone/data/latest.dart' as tz;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
//import dart
import 'dart:async';
import 'dart:convert';
//import lib
import 'main_screen_accommodations.dart';
import 'register.dart';
import 'server_config.dart';
import 'app_settings.dart';
import 'accessibility_buttons.dart';
import 'offline_sync_repository.dart';
import 'accommodation_draft.dart';
import 'firebase_options.dart';

String? globalToken;
int? globalUserId;
final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final Trace trace = FirebasePerformance.instance.newTrace('test_trace');

Future<void> notifyNextStay() async {
  await trace.start();
  final uri = Uri.parse('http://$serverIp:$serverPort/upcoming_reservations');
  final res = await http.get(uri, headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $globalToken'
  });
  if (res.statusCode != 200) return;
  final List<dynamic> list = jsonDecode(res.body);
  if (list.isEmpty) return;
  final next = DateTime.parse(list.first['from']);
  final String dateOnly = DateFormat('yyyy-MM-dd').format(next);
  print('[${DateTime.now()}] > notifyNextStay: showing notification for next stay on $dateOnly');
  await notificationsPlugin.show(
    0,
    'Next stay',
    'Your next stay starts on $dateOnly',
    NotificationDetails(
      android: AndroidNotificationDetails(
        'next_stay_channel',
        'Next Stay',
        channelDescription: 'Minute-by-minute next stay reminder',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
  await trace.stop();
}

Future<void> _backgroundFetchTask(String taskId) async {
  print('[${DateTime.now()}] > backgroundFetchTask: showing promotional notification');

  final List<String> promos = [
    'Get 30% off on your next stay',
    'Enjoy a free breakfast with your stay',
    'Upgrade your room at no extra cost',
    'Early check-in available on request',
    'Late check-out at no extra charge'
  ];

  promos.shuffle();
  final String promoMessage = promos.first;
  await notificationsPlugin.show(
    0,
    'Special Offer',
    promoMessage,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'promo_channel',
        'Promotions',
        channelDescription: 'Latest deals and offers',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );

  print('[${DateTime.now()}] > backgroundFetchTask: finished');
  BackgroundFetch.finish(taskId);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  tz.initializeTimeZones();
  await Hive.initFlutter();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  Hive.registerAdapter(AccommodationDraftAdapter());
  OfflineSyncRepository.instance;

  await notificationsPlugin.initialize(
    InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      ),
    ),
  );

    final iosImpl = notificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
  if (iosImpl != null) {
    await iosImpl.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  BackgroundFetch.registerHeadlessTask(_backgroundFetchTask);

  Timer.periodic(const Duration(minutes: 1), (_) {
    print('[${DateTime.now()}] > Timer fired, calling notifyNextStay()');
    notifyNextStay();
  });

  await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 1,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
      requiredNetworkType: NetworkType.NONE,
    ),
    _backgroundFetchTask,
  );

  BackgroundFetch.status.then((status) {
    print('[BackgroundFetch] status: $status');
  });

  FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  runZonedGuarded<Future<void>>(() async {
  runApp(
    SyncToast(
      child: MultiProvider(
        providers: [
          Provider<OfflineSyncRepository>.value(
            value: OfflineSyncRepository.instance,
          ),
          ChangeNotifierProvider<AppSettings>(
            create: (_) => AppSettings(),
          ),
        ],
        child: const RoomFinderApp(),
      ),
    ),
  );
  }, FirebaseCrashlytics.instance.recordError);
}

class RoomFinderApp extends StatelessWidget {
  const RoomFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: globalScaffoldMessengerKey,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
      builder: (context, child) {
        final brightness = MediaQuery.of(context).platformBrightness;
        final overlayStyle =
            brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: child!,
        );
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      body: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.small: SlotLayout.from(
            key: const Key('phone-layout'),
            builder: (_) => const _PhoneLogin(),
          ),
          Breakpoints.medium: SlotLayout.from(
            key: const Key('tablet-layout'),
            builder: (_) => const _TabletLogin(),
          ),
        },
      ),
    );
  }
}

class _PhoneLogin extends StatelessWidget {
  const _PhoneLogin();

  @override
  Widget build(BuildContext context) => _ScaffoldWrapper(
    child: const _LoginForm(maxWidth: 500, showTopLogo: true),
  );
}

class _TabletLogin extends StatelessWidget {
  const _TabletLogin();

  @override
  Widget build(BuildContext context) => _ScaffoldWrapper(
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'assets/logo_dark.png'
                  : 'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Expanded(
          child: Center(child: _LoginForm(maxWidth: 420, showTopLogo: false)),
        ),
      ],
    ),
  );
}

class _ScaffoldWrapper extends StatelessWidget {
  const _ScaffoldWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bg =
        highContrast
            ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (isDark ? AppColors.colorBgDark : AppColors.colorBg);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: child,
                ),
              ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.maxWidth, this.showTopLogo = true});

  final double maxWidth;
  final bool showTopLogo;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _emailError = false, _passwordError = false, _obscure = true;
  String? _emailErrorMsg, _loginErrorMsg;

  bool _validEmail(String v) =>
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$').hasMatch(v);

  void _validate() {
    setState(() {
      _emailError = _email.text.isEmpty || !_validEmail(_email.text);
      _passwordError = _password.text.isEmpty;
      _emailErrorMsg =
          _email.text.isEmpty
              ? 'This text field cannot be empty'
              : !_validEmail(_email.text)
              ? 'Invalid email format'
              : null;
    });
  }

Future<void> _login() async {
  _validate();
  if (_emailError || _passwordError) return;

  late io.Socket socket;

  void connectSocket(String jwt) {
    debugPrint('connectSocket called with jwt: $jwt');
    socket = io.io('http://$serverIp:$serverPort', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'token': jwt},
    });
    socket.onConnect((_) {
      debugPrint('WS connected');
    });
    socket.onDisconnect((_) {
      debugPrint('WS disconnected');
    });
    socket.on('connect_error', (err) {
      debugPrint('WS connect_error: $err');
    });
    socket.on('accommodation_liked', (payload) {
      debugPrint('Received accommodation_liked: $payload');
      final message = payload['message'] as String? ?? 'Notification';
      globalScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
    debugPrint('Calling socket.connect()');
    socket.connect();
  }

  setState(() => _loginErrorMsg = null);

  try {
    final res = await http.post(
      Uri.parse('http://$serverIp:$serverPort/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _email.text, 'password': _password.text}),
    );

    if (res.statusCode == 200) {
      globalToken = jsonDecode(res.body)['token'];
      connectSocket(globalToken!);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MainScreenAccommodations()),
      );
    } else {
      setState(() => _loginErrorMsg = 'Invalid email or password');
    }
  } catch (e) {
    setState(() => _loginErrorMsg = 'Connection error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;

    final buttonTextStyle = TextStyle(
      fontSize: bigText ? 20 : 16,
      color:
          highContrast
              ? (isDark
                  ? AppColors.colorButtonTextDarkHigh
                  : AppColors.colorButtonTextHigh)
              : (isDark
                  ? AppColors.colorButtonTextDark
                  : AppColors.colorButtonText),
      fontFamily: 'Helvetica',
      fontWeight: bigText ? FontWeight.bold : FontWeight.normal,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showTopLogo)
              Container(
                width: 240,
                height: 240,
                margin: const EdgeInsets.only(bottom: 10),
                child: Image.asset(
                  isDark ? 'assets/logo_dark.png' : 'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            _ShadowBox(
              child: TextField(
                controller: _email,
                style: TextStyle(
                  color:
                      highContrast
                          ? (isDark
                              ? AppColors.colorTextDarkHigh
                              : AppColors.colorTextHigh)
                          : (isDark
                              ? AppColors.colorTextDark
                              : AppColors.colorText),
                  fontSize: bigText ? 18 : 14,
                ),
                decoration: _inputDecoration(
                  context,
                  hint: 'Email',
                  errorText: null,
                ),
              ),
            ),
            if (_emailError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailErrorMsg!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color:
                          highContrast
                              ? AppColors.color1High
                              : AppColors.color1,
                      fontWeight:
                          highContrast ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'Helvetica',
                      fontSize: bigText ? 18 : 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            _ShadowBox(
              child: TextField(
                controller: _password,
                obscureText: _obscure,
                style: TextStyle(
                  color:
                      highContrast
                          ? (isDark
                              ? AppColors.colorTextDarkHigh
                              : AppColors.colorTextHigh)
                          : (isDark
                              ? AppColors.colorTextDark
                              : AppColors.colorText),
                  fontSize: bigText ? 18 : 14,
                ),
                decoration: _inputDecoration(
                  context,
                  hint: 'Password',
                  errorText: null,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            if (_passwordError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'This text field cannot be empty',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color:
                          highContrast
                              ? AppColors.color1High
                              : AppColors.color1,
                      fontWeight:
                          highContrast ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'Helvetica',
                      fontSize: bigText ? 18 : 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _ShadowBox(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        highContrast
                            ? (isDark
                                ? AppColors.color1DarkHigh
                                : AppColors.color1High)
                            : (isDark
                                ? AppColors.color1Dark
                                : AppColors.color1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _login,
                  child: Text('Login', style: buttonTextStyle),
                ),
              ),
            ),
            if (_loginErrorMsg != null) ...[
              const SizedBox(height: 10),
              Text(_loginErrorMsg!, style: const TextStyle(color: Colors.red)),
            ],
            TextButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
              child: Text(
                'Register',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  decoration: TextDecoration.underline,
                  fontFamily: 'Helvetica',
                ),
              ),
            ),
            const AccessibilityButtons(),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext ctx, {
    required String hint,
    String? errorText,
  }) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? AppColors.colorInputBgDark : AppColors.colorInputBg,
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.colorHintDark : AppColors.colorHint,
        fontFamily: 'Helvetica',
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      errorText: errorText,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

class _ShadowBox extends StatelessWidget {
  const _ShadowBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 55),
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
      ],
    ),
    child: child,
  );
}
