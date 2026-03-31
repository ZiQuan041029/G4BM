import 'package:flutter/material.dart';
import 'sign_up_page.dart'; // Need this to go to Sign Up
import 'mood_entry_page.dart';
import 'package:g4bm/main.dart';
import 'package:provider/provider.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 48.0,
          ), // Updated Padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Image.asset('assets/G4BM_logo.png', width: 100),
                SizedBox(height: 10),
                Text(
                  'Log In to your account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter your email to log in for this app',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('email@domain.com'),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter your email';
                    return null;
                  },
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter your password';
                    return null;
                  },
                ),
                SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // 2. Show a Loading Spinner
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        );

                        var appState = context.read<MyAppState>();

                        // 3. TALK TO MONGODB: Attempt to Log In!
                        bool success = await appState.loginUser(
                          _emailController.text.trim(),
                          _passwordController
                              .text, // Your password text field controller
                        );

                        // 4. Hide the Loading Spinner
                        Navigator.pop(context);

                        if (success) {
                          // Success! Send them to today's mood entry.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MoodEntryPage(initialDate: DateTime.now()),
                            ),
                          );
                        } else {
                          // Show Error if password/email is wrong
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Invalid email or password."),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot your password ?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: Text(
                    'No account ?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                    ),
                  ),
                ),

                SizedBox(height: 30),
                _buildDivider(),
                SizedBox(height: 30),
                _buildGoogleButton(),
                SizedBox(height: 40),
                _buildFooterText(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widgets for Login Page
InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}

Widget _buildDivider([String text = "or Log in with"]) {
  return Row(
    children: [
      Expanded(child: Divider(color: Colors.grey.shade300)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(text, style: TextStyle(color: Colors.grey)),
      ),
      Expanded(child: Divider(color: Colors.grey.shade300)),
    ],
  );
}

Widget _buildGoogleButton() {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: () {
        print("sign in with google");
      },
      icon: Icon(Icons.g_mobiledata, color: Colors.black, size: 30),
      label: Text(
        'Google',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

Widget _buildFooterText() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Text(
      'By clicking continue, you agree to our Terms of Service and Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Colors.grey),
    ),
  );
}
