// main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'main_screen_accommodations.dart';
import 'register.dart';
import 'server_config.dart';
import 'app_settings.dart';
import 'accessibility_buttons.dart';

String? globalToken;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const RoomFinderApp(),
    ),
  );
}

class RoomFinderApp extends StatelessWidget {
  const RoomFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

    setState(() => _loginErrorMsg = null);

    try {
      final res = await http.post(
        Uri.parse('http://$serverIp:$serverPort/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email.text, 'password': _password.text}),
      );

      if (res.statusCode == 200) {
        globalToken = jsonDecode(res.body)['token'];
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
