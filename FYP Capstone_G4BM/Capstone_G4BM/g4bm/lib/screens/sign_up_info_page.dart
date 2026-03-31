import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'login_page.dart';
import 'identity_page.dart';

class SignUpInfoPage extends StatefulWidget {
  final String email;
  const SignUpInfoPage({super.key, required this.email});

  @override
  State<SignUpInfoPage> createState() => _SignUpInfoPageState();
}

class _SignUpInfoPageState extends State<SignUpInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGender;
  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // --- FIXED HEADER SECTION ---
              const SizedBox(height: 10),
              Image.asset('assets/G4BM_logo.png', width: 120),
              const SizedBox(height: 10),
              const Text(
                'Nice to meet you!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your details to create your account.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),

              // --- SCROLLABLE CARD SECTION ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Name"),
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('Name'),
                            validator: (value) =>
                                value!.isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Username"),
                          TextFormField(
                            controller: _usernameController,
                            decoration: _inputDecoration('@username'),
                            validator: (value) =>
                                value!.isEmpty ? 'Enter a username' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("Gender"),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: _inputDecoration('-'),
                            items: _genderOptions.map((String gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              );
                            }).toList(),
                            onChanged: (newValue) =>
                                setState(() => _selectedGender = newValue),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel("D.O.B"),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: _inputDecoration('DD-MM-YYYY').copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // --- SAVE TO PROVIDER DATABASE ---
                                  var appState = context.read<MyAppState>();

                                  // 1. Save Email from previous page
                                  appState.updateUserProfile(
                                    'email',
                                    widget.email,
                                  );

                                  // 2. Save Name
                                  appState.updateUserProfile(
                                    'name',
                                    _nameController.text.trim(),
                                  );

                                  // 3. Format and Save Username
                                  String uName = _usernameController.text
                                      .trim();
                                  if (!uName.startsWith('@')) {
                                    uName = '@$uName';
                                  }
                                  appState.updateUserProfile('username', uName);

                                  // 4. Save Optional Fields
                                  if (_selectedGender != null) {
                                    appState.updateUserProfile(
                                      'gender',
                                      _selectedGender ?? "-",
                                    );
                                  }
                                  if (_dobController.text.isNotEmpty) {
                                    appState.updateUserProfile(
                                      'dob',
                                      _dobController.text,
                                    );
                                  }

                                  // --- NAVIGATE TO IDENTITY PAGE ---
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IdentityPage(
                                        userName: _nameController.text,
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                child: const Text(
                                  "Log in Here.",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
