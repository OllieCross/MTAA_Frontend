import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'server_config.dart';
import 'register_succesful.dart';
import 'app_settings.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePassword2 = true;

  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  String? _repeatPasswordErrorMessage;

  Future<void> _onRegisterPressed() async {
    if (!mounted) return;
    setState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
      _repeatPasswordErrorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    bool hasError = false;

    if (email.isEmpty) {
      setState(() => _emailErrorMessage = 'Please enter an email');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordErrorMessage = 'Please enter a password');
      hasError = true;
    }
    if (repeatPassword.isEmpty) {
      setState(
        () => _repeatPasswordErrorMessage = 'Please re-enter the password',
      );
      hasError = true;
    }

    if (!hasError && password != repeatPassword) {
      setState(() {
        _passwordErrorMessage = ' ';
        _repeatPasswordErrorMessage = 'Passwords do not match';
      });
      hasError = true;
    }

    if (!hasError) {
      try {
        final response = await http.post(
          Uri.parse('http://$serverIp:$serverPort/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'role': 'customer',
          }),
        );

        if (response.statusCode == 201) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegisterSuccesful()),
          );
        } else {
          final body = jsonDecode(response.body);
          setState(() {
            _emailErrorMessage = body['message'] ?? 'Registration failed';
          });
        }
      } catch (e) {
        setState(() {
          _emailErrorMessage = "Connection error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<AppSettings>();
    final highContrast = settings.highContrast;
    final bigText = settings.bigText;

    final bgColor =
        highContrast
            ? (isDark ? AppColors.colorBgDarkHigh : AppColors.colorBgHigh)
            : (isDark ? AppColors.colorBgDark : AppColors.colorBg);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(backgroundColor: bgColor, elevation: 0),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Registration',
                          style: TextStyle(
                            fontSize: bigText ? 38 : 30,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Helvetica',
                            color:
                                highContrast
                                    ? (isDark
                                        ? AppColors.colorTextDarkHigh
                                        : AppColors.colorTextHigh)
                                    : (isDark
                                        ? AppColors.colorTextDark
                                        : AppColors.colorText),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildFieldContainer(
                        child: TextField(
                          controller: _emailController,
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: bigText ? 18 : 16,
                            fontWeight:
                                bigText ? FontWeight.bold : FontWeight.normal,
                            color:
                                highContrast
                                    ? (isDark
                                        ? AppColors.colorTextDarkHigh
                                        : AppColors.colorTextHigh)
                                    : (isDark
                                        ? AppColors.colorTextDark
                                        : AppColors.colorText),
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Email',
                            hasError: _emailErrorMessage != null,
                            isDark: isDark,
                            highContrast: highContrast,
                          ),
                        ),
                      ),
                      if (_emailErrorMessage != null)
                        _buildErrorMessage(
                          _emailErrorMessage!,
                          isDark,
                          highContrast,
                          bigText,
                        )
                      else
                        const SizedBox(height: 15),
                      _buildFieldContainer(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: bigText ? 18 : 16,
                            fontWeight:
                                bigText ? FontWeight.bold : FontWeight.normal,
                            color:
                                highContrast
                                    ? (isDark
                                        ? AppColors.colorTextDarkHigh
                                        : AppColors.colorTextHigh)
                                    : (isDark
                                        ? AppColors.colorTextDark
                                        : AppColors.colorText),
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Password',
                            hasError: _passwordErrorMessage != null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color:
                                    highContrast
                                        ? (isDark
                                            ? AppColors.colorTextDarkHigh
                                            : AppColors.colorTextHigh)
                                        : (isDark
                                            ? AppColors.colorTextDark
                                            : AppColors.colorText),
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            ),
                            isDark: isDark,
                            highContrast: highContrast,
                          ),
                        ),
                      ),
                      if (_passwordErrorMessage != null)
                        _buildErrorMessage(
                          _passwordErrorMessage!,
                          isDark,
                          highContrast,
                          bigText,
                        )
                      else
                        const SizedBox(height: 15),
                      _buildFieldContainer(
                        child: TextField(
                          controller: _repeatPasswordController,
                          obscureText: _obscurePassword2,
                          style: TextStyle(
                            fontFamily: 'Helvetica',
                            fontSize: bigText ? 18 : 16,
                            fontWeight:
                                bigText ? FontWeight.bold : FontWeight.normal,
                            color:
                                highContrast
                                    ? (isDark
                                        ? AppColors.colorTextDarkHigh
                                        : AppColors.colorTextHigh)
                                    : (isDark
                                        ? AppColors.colorTextDark
                                        : AppColors.colorText),
                          ),
                          decoration: _buildInputDecoration(
                            hintText: 'Repeat Password',
                            hasError: _repeatPasswordErrorMessage != null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword2
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color:
                                    highContrast
                                        ? (isDark
                                            ? AppColors.colorTextDarkHigh
                                            : AppColors.colorTextHigh)
                                        : (isDark
                                            ? AppColors.colorTextDark
                                            : AppColors.colorText),
                              ),
                              onPressed:
                                  () => setState(
                                    () =>
                                        _obscurePassword2 = !_obscurePassword2,
                                  ),
                            ),
                            isDark: isDark,
                            highContrast: highContrast,
                          ),
                        ),
                      ),
                      if (_repeatPasswordErrorMessage != null)
                        _buildErrorMessage(
                          _repeatPasswordErrorMessage!,
                          isDark,
                          highContrast,
                          bigText,
                        )
                      else
                        const SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _onRegisterPressed,
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
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color:
                                    highContrast
                                        ? (isDark
                                            ? AppColors.colorButtonTextDarkHigh
                                            : AppColors.colorButtonTextHigh)
                                        : (isDark
                                            ? AppColors.colorButtonTextDark
                                            : AppColors.colorButtonText),
                                fontFamily: 'Helvetica',
                                fontSize: bigText ? 20 : 18,
                                fontWeight:
                                    bigText
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Registration',
                      style: TextStyle(
                        fontSize: bigText ? 38 : 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Helvetica',
                        color:
                            highContrast
                                ? (isDark
                                    ? AppColors.colorTextDarkHigh
                                    : AppColors.colorTextHigh)
                                : (isDark
                                    ? AppColors.colorTextDark
                                    : AppColors.colorText),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),
                            _buildFieldContainer(
                              child: TextField(
                                controller: _emailController,
                                style: TextStyle(
                                  fontFamily: 'Helvetica',
                                  fontSize: bigText ? 18 : 16,
                                  fontWeight:
                                      bigText
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      highContrast
                                          ? (isDark
                                              ? AppColors.colorTextDarkHigh
                                              : AppColors.colorTextHigh)
                                          : (isDark
                                              ? AppColors.colorTextDark
                                              : AppColors.colorText),
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: 'Email',
                                  hasError: _emailErrorMessage != null,
                                  isDark: isDark,
                                  highContrast: highContrast,
                                ),
                              ),
                            ),
                            if (_emailErrorMessage != null)
                              _buildErrorMessage(
                                _emailErrorMessage!,
                                isDark,
                                highContrast,
                                bigText,
                              )
                            else
                              const SizedBox(height: 15),
                            _buildFieldContainer(
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(
                                  fontFamily: 'Helvetica',
                                  fontSize: bigText ? 18 : 16,
                                  fontWeight:
                                      bigText
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      highContrast
                                          ? (isDark
                                              ? AppColors.colorTextDarkHigh
                                              : AppColors.colorTextHigh)
                                          : (isDark
                                              ? AppColors.colorTextDark
                                              : AppColors.colorText),
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: 'Password',
                                  hasError: _passwordErrorMessage != null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color:
                                          highContrast
                                              ? (isDark
                                                  ? AppColors.colorTextDarkHigh
                                                  : AppColors.colorTextHigh)
                                              : (isDark
                                                  ? AppColors.colorTextDark
                                                  : AppColors.colorText),
                                    ),
                                    onPressed:
                                        () => setState(
                                          () =>
                                              _obscurePassword =
                                                  !_obscurePassword,
                                        ),
                                  ),
                                  isDark: isDark,
                                  highContrast: highContrast,
                                ),
                              ),
                            ),
                            if (_passwordErrorMessage != null)
                              _buildErrorMessage(
                                _passwordErrorMessage!,
                                isDark,
                                highContrast,
                                bigText,
                              )
                            else
                              const SizedBox(height: 15),
                            _buildFieldContainer(
                              child: TextField(
                                controller: _repeatPasswordController,
                                obscureText: _obscurePassword2,
                                style: TextStyle(
                                  fontFamily: 'Helvetica',
                                  fontSize: bigText ? 18 : 16,
                                  fontWeight:
                                      bigText
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      highContrast
                                          ? (isDark
                                              ? AppColors.colorTextDarkHigh
                                              : AppColors.colorTextHigh)
                                          : (isDark
                                              ? AppColors.colorTextDark
                                              : AppColors.colorText),
                                ),
                                decoration: _buildInputDecoration(
                                  hintText: 'Repeat Password',
                                  hasError: _repeatPasswordErrorMessage != null,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword2
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color:
                                          highContrast
                                              ? (isDark
                                                  ? AppColors.colorTextDarkHigh
                                                  : AppColors.colorTextHigh)
                                              : (isDark
                                                  ? AppColors.colorTextDark
                                                  : AppColors.colorText),
                                    ),
                                    onPressed:
                                        () => setState(
                                          () =>
                                              _obscurePassword2 =
                                                  !_obscurePassword2,
                                        ),
                                  ),
                                  isDark: isDark,
                                  highContrast: highContrast,
                                ),
                              ),
                            ),
                            if (_repeatPasswordErrorMessage != null)
                              _buildErrorMessage(
                                _repeatPasswordErrorMessage!,
                                isDark,
                                highContrast,
                                bigText,
                              )
                            else
                              const SizedBox(height: 15),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _onRegisterPressed,
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
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      color:
                                          highContrast
                                              ? (isDark
                                                  ? AppColors
                                                      .colorButtonTextDarkHigh
                                                  : AppColors
                                                      .colorButtonTextHigh)
                                              : (isDark
                                                  ? AppColors
                                                      .colorButtonTextDark
                                                  : AppColors.colorButtonText),
                                      fontFamily: 'Helvetica',
                                      fontSize: bigText ? 20 : 18,
                                      fontWeight:
                                          bigText
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFieldContainer({required Widget child}) {
    return Stack(
      children: [
        Container(
          height: 55,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    bool hasError = false,
    Widget? suffixIcon,
    required bool isDark,
    required bool highContrast,
  }) {
    final fillColor =
        highContrast
            ? (isDark
                ? AppColors.colorInputBgDarkHigh
                : AppColors.colorInputBgHigh)
            : (isDark ? AppColors.colorInputBgDark : AppColors.colorInputBg);
    final hintColor =
        highContrast
            ? (isDark ? AppColors.colorHintDarkHigh : AppColors.colorHintHigh)
            : (isDark ? AppColors.colorHintDark : AppColors.colorHint);
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      hintStyle: TextStyle(color: hintColor, fontFamily: 'Helvetica'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            hasError
                ? const BorderSide(color: Colors.red, width: 2)
                : BorderSide.none,
      ),
    );
  }

  Widget _buildErrorMessage(
    String msg,
    bool isDark,
    bool highContrast,
    bool bigText,
  ) {
    final textColor = highContrast ? AppColors.color1High : AppColors.color1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        msg,
        style: TextStyle(
          color: textColor,
          fontFamily: 'Helvetica',
          fontSize: bigText ? 14 : 12,
        ),
      ),
    );
  }
}
