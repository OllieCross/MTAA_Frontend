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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: ThemeMode.system,
          home: const LoginScreen(),
        ),
      );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      body: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          // Handsets: one column, small logo above the form
          Breakpoints.small: SlotLayout.from(
            key: const Key('phone-layout'),
            builder: (_) => const _PhoneLogin(),
          ),
          // Tablets / desktops: two-pane layout; no second logo
          Breakpoints.medium: SlotLayout.from(
            key: const Key('tablet-layout'),
            builder: (_) => const _TabletLogin(),
          ),
        },
      ),
    );
  }
}

/// Phone / narrow layout (single column)
class _PhoneLogin extends StatelessWidget {
  const _PhoneLogin();

  @override
  Widget build(BuildContext context) => _ScaffoldWrapper(
        child: const _LoginForm(maxWidth: 500, showTopLogo: true),
      );
}

/// Tablet / wide layout (logo left, form right)
class _TabletLogin extends StatelessWidget {
  const _TabletLogin();

  @override
  Widget build(BuildContext context) => _ScaffoldWrapper(
        child: Row(
          children: [
            // big logo pane
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
            // form pane (no duplicate logo)
            const Expanded(
              child: Center(
                child: _LoginForm(maxWidth: 420, showTopLogo: false),
              ),
            ),
          ],
        ),
      );
}

/// Adds SafeArea + scroll + some padding
class _ScaffoldWrapper extends StatelessWidget {
  const _ScaffoldWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: child,
              ),
            ),
          ),
        ),
      );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({
    required this.maxWidth,
    this.showTopLogo = true,
  });

  final double maxWidth;
  final bool   showTopLogo;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email    = TextEditingController();
  final _password = TextEditingController();

  bool   _emailError = false,
          _passwordError = false,
          _obscure = true;
  String? _emailErrorMsg, _loginErrorMsg;

  bool _validEmail(String v) =>
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')
          .hasMatch(v);

  void _validate() {
    setState(() {
      _emailError = _email.text.isEmpty || !_validEmail(_email.text);
      _passwordError = _password.text.isEmpty;
      _emailErrorMsg = _email.text.isEmpty
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
        body: jsonEncode({
          'email': _email.text,
          'password': _password.text,
        }),
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
    // Settings coming from Provider
    final settings      = context.watch<AppSettings>();
    final bigText       = settings.bigText;
    final highContrast  = settings.highContrast;
    final isDark        = Theme.of(context).brightness == Brightness.dark;

    // TextStyle you requested for the Login label
    final loginLabelStyle = TextStyle(
      fontSize: bigText ? 20 : 16,
      color: highContrast
          ? (isDark ? AppColors.colorTextDarkHigh : AppColors.colorTextHigh)
          : (isDark ? AppColors.colorTextDark     : AppColors.colorText),
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
                decoration: _inputDecoration(
                  context,
                  hint: 'Email',
                  errorText: _emailError ? _emailErrorMsg : null,
                ),
              ),
            ),
            const SizedBox(height: 10),

            _ShadowBox(
              child: TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: _inputDecoration(
                  context,
                  hint: 'Password',
                  errorText: _passwordError
                      ? 'This text field cannot be empty'
                      : null,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
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
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _login,
                  child: Text('Login', style: loginLabelStyle),
                ),
              ),
            ),

            if (_loginErrorMsg != null) ...[
              const SizedBox(height: 10),
              Text(_loginErrorMsg!, style: const TextStyle(color: Colors.red)),
            ],

            TextButton(
              onPressed: () => Navigator.push(
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
          ],
        ),
      ),
    );
  }

  // helper for consistent decoration
  InputDecoration _inputDecoration(BuildContext ctx,
      {required String hint, String? errorText}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.grey[800] : Colors.grey[300],
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black54,
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

/// Re-usable container with drop shadow (so code above stays clean)
class _ShadowBox extends StatelessWidget {
  const _ShadowBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        height: 55,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: child,
      );
}