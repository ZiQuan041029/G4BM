import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:g4bm/services/api_service.dart'; // Adjust import as needed

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _currentStep = 1;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  final Color brownColor = const Color(0xFF5D4037);
  final Color creamBg = const Color(0xFFEBE5DE);

  // --- LOGIC METHODS ---

  Future<void> _handleGetCode() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    String? devCode = await ApiService().requestPasswordReset(email);

    setState(() => _isLoading = false);

    if (devCode != null) {
      setState(() => _currentStep = 2);

      // THE MOCK EMAIL MAGIC: Show the code on screen!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("TEST MODE: Your reset code is $devCode"),
            duration: const Duration(seconds: 10),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email not found."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleResetPassword() async {
    String email = _emailController.text.trim();
    String code = _codeController.text.trim();
    String newPassword = _passwordController.text.trim();

    if (code.isEmpty || newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter the code and a valid new password."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    bool success = await ApiService().resetPassword(email, code, newPassword);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back to Login Page
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid code. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentStep == 1 ? "Forgot Password" : "Reset Password",
                style: GoogleFonts.darumadropOne(
                  fontSize: 32,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _currentStep == 1
                    ? "Enter your email address to receive a 4-digit reset code."
                    : "Enter the code we sent you and your new password.",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // STEP 1 UI: EMAIL
              if (_currentStep == 1) ...[
                _buildTextField(
                  "Email Address",
                  Icons.email,
                  _emailController,
                  false,
                ),
                const SizedBox(height: 30),
                _buildButton("Send Code", _handleGetCode),
              ],

              // STEP 2 & 3 UI: CODE AND NEW PASSWORD
              if (_currentStep == 2) ...[
                _buildTextField(
                  "4-Digit Code",
                  Icons.numbers,
                  _codeController,
                  false,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "New Password",
                  Icons.lock,
                  _passwordController,
                  true,
                ),
                const SizedBox(height: 30),
                _buildButton("Update Password", _handleResetPassword),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
    bool isPassword,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: brownColor),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: brownColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
