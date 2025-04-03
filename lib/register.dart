import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePassword2 = true;

  // Inline error messages
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  String? _repeatPasswordErrorMessage;
  
  void _onRegisterPressed() {
    // Reset errors first
    setState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
      _repeatPasswordErrorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    bool hasError = false;

    // Check empty
    if (email.isEmpty) {
      setState(() => _emailErrorMessage = 'Please enter an email');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordErrorMessage = 'Please enter a password');
      hasError = true;
    }
    if (repeatPassword.isEmpty) {
      setState(() => _repeatPasswordErrorMessage = 'Please re-enter the password');
      hasError = true;
    }

    // Check mismatch
    if (!hasError && password != repeatPassword) {
      setState(() {
        _passwordErrorMessage = ' ';
        _repeatPasswordErrorMessage = 'Passwords do not match';
      });
      hasError = true;
    }

    // If no error, register
    if (!hasError) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color.fromARGB(255, 34, 34, 34) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color.fromARGB(255, 34, 34, 34) : Colors.white,
      ),
      body: Center(
        // Center the content both vertically and horizontally
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            // Column that centers items vertically
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start, // left-align text
              children: [
                
                // TITLE
                Center(
                  child: Text(
                    'Registration',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Helvetica',
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // EMAIL
                _buildFieldContainer(
                  child: TextField(
                    controller: _emailController,
                    decoration: _buildInputDecoration(
                      hintText: 'Email',
                      hasError: _emailErrorMessage != null,
                    ),
                  ),
                ),
                if (_emailErrorMessage != null)
                  _buildErrorMessage(_emailErrorMessage!)
                else
                  const SizedBox(height: 15),

                // PASSWORD
                _buildFieldContainer(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _buildInputDecoration(
                      hintText: 'Password',
                      hasError: _passwordErrorMessage != null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (_passwordErrorMessage != null)
                  _buildErrorMessage(_passwordErrorMessage!)
                else
                  const SizedBox(height: 15),

                // REPEAT PASSWORD
                _buildFieldContainer(
                  child: TextField(
                    controller: _repeatPasswordController,
                    obscureText: _obscurePassword2,
                    decoration: _buildInputDecoration(
                      hintText: 'Repeat Password',
                      hasError: _repeatPasswordErrorMessage != null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword2
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword2 = !_obscurePassword2;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (_repeatPasswordErrorMessage != null)
                  _buildErrorMessage(_repeatPasswordErrorMessage!)
                else
                  const SizedBox(height: 15),

                // REGISTER BUTTON with shadow & white text
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12, // lighter shadow
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
                        backgroundColor: Colors.red[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white, fontFamily: 'Helvetica', fontSize: 18,
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
                color: Colors.black12, // lighter than black26
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

  // Helper: Build the input decoration with optional suffix icon & red stroke on error
  InputDecoration _buildInputDecoration({
    required String hintText,
    bool hasError = false,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      suffixIcon: suffixIcon,
      // If there's an error, show red border
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: hasError
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
    );
  }

  // Helper: Build inline error message
  Widget _buildErrorMessage(String msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        msg, 
        style: const TextStyle(color: Colors.red, fontFamily: 'Helvetica', fontSize: 12,)
      ),
    );
  }
}