import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'search.dart';
import 'register.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RoomFinderApp());
}

class RoomFinderApp extends StatelessWidget {
  const RoomFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: MediaQuery.of(context).platformBrightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: LoginScreen(),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _emailError = false;
  bool _passwordError = false;
  bool _obscurePassword = true;
  String? _emailErrorMessage;
  String? _loginErrorMessage;

  bool _isValidEmail(String email) {
    final RegExp regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  void _validateAndLogin() {
    setState(() {
      _emailError = _emailController.text.isEmpty || !_isValidEmail(_emailController.text);
      _passwordError = _passwordController.text.isEmpty;
      _emailErrorMessage = _emailController.text.isEmpty
          ? "This text field cannot be empty"
          : (!_isValidEmail(_emailController.text) ? "Invalid email format" : null);
    });

    if (!_emailError && !_passwordError && _loginErrorMessage == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SearchScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color.fromARGB(255, 34, 34, 34) : Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Logo
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.transparent,
                ),
                child: Image.asset( isDarkMode ? 'assets/logo_dark.png' :
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              
              // Email Input Field
              Stack(
                children: [
                  Container(
                    height: 55,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      hintText: "Email",
                      hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontFamily: 'Helvetica'),
                        border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _emailError ? _emailErrorMessage : null,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Password Input Field
              Stack(
                children: [
                  Container(
                    height: 55,
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      hintText: "Password",
                      hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontFamily: 'Helvetica'),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _passwordError ? "This text field cannot be empty" : null,
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Login Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      _validateAndLogin();
                      if (!_emailError && !_passwordError) {
                        final email = _emailController.text;
                        final password = _passwordController.text;
                        try {
                          final response = await http.post(
                            Uri.parse('http://127.0.0.1:5000/login'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'email': email, 'password': password}),
                          );
                          if (response.statusCode == 200) {
                            setState(() => _loginErrorMessage = null);
                          } else {
                            setState(() {
                              _loginErrorMessage = "invalid email or password";
                            });
                          }
                        } catch (e) {
                          setState(() {
                            _loginErrorMessage = "connection error";
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Helvetica'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10), // Some spacing before error text

              // 3. Show the error message under the button if there is one:
              if (_loginErrorMessage != null) ...[
                Text(
                  _loginErrorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              
              // Register text button
              TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: Text(
                "Register",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  decoration: TextDecoration.underline,
                  fontFamily: 'Helvetica',
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}