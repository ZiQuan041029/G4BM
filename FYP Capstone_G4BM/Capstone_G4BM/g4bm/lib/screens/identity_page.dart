import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mood_entry_page.dart';
import 'package:g4bm/main.dart';
import 'package:provider/provider.dart';

class IdentityPage extends StatefulWidget {
  final String userName;

  const IdentityPage({super.key, required this.userName});

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  String _selectedRole = 'Mama';
  String _selectedGoal = 'Elevate Mood';

  final List<String> _goals = [
    'Elevate Mood',
    'Time Management',
    'Improve Sleep',
    'Maternity & Parenting Tips',
    'Increase Productivity',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    // Colors
    final lightBrownColor = const Color(0xFFB38E6B);

    final creamBg = const Color(0xFFFFF9F0);
    final brownColor = const Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Text(
                'Nice to meet you!',
                style: GoogleFonts.darumadropOne(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'About you...',
                style: GoogleFonts.darumadropOne(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),

              Text(
                'Are you a...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              // --- UPDATED ROLE CARDS ---
              Row(
                children: [
                  // MAMA CARD
                  Expanded(
                    child: _buildRoleCard(
                      label: 'Mama',
                      imagePath: 'assets/gender/mama_bear.png',
                      isSelected: _selectedRole == 'Mama',
                      selectedColor: lightBrownColor,
                      onTap: () => setState(() => _selectedRole = 'Mama'),
                    ),
                  ),
                  SizedBox(width: 15),

                  // PAPA CARD
                  Expanded(
                    child: _buildRoleCard(
                      label: 'Papa',
                      imagePath: 'assets/gender/papa_bear.png',
                      isSelected: _selectedRole == 'Papa',
                      selectedColor: lightBrownColor,
                      onTap: () => setState(() => _selectedRole = 'Papa'),
                    ),
                  ),
                ],
              ),

              // ---------------------------
              SizedBox(height: 20),

              Text(
                'What’s on your mind?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              // Goals List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: _goals.map((goal) {
                    final isSelected = _selectedGoal == goal;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGoal = goal),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? lightBrownColor : Colors.white,
                          borderRadius: _getBorderRadius(goal),
                        ),
                        child: Text(
                          goal,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 40),

              // Next Button
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedRole.isEmpty || _selectedGoal.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select a role and a goal to continue.",
                          ),
                        ),
                      );
                      return;
                    }
                    // 2. Show a Loading Spinner
                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // Prevents user from tapping out
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    );

                    var appState = context.read<MyAppState>();

                    // 3. Save the final Role & Goal to the profile map
                    appState.userProfile['role'] = _selectedRole;
                    appState.userProfile['goal'] = _selectedGoal;

                    // 4. TALK TO MONGODB: Register the user!
                    bool success = await appState.registerNewUser(
                      appState.tempPassword,
                    );

                    // 5. Hide the Loading Spinner
                    Navigator.pop(context);

                    if (success) {
                      appState.tempPassword =
                          ''; // Clear password from memory for security

                      // Go to the first Mood check-in!
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MoodEntryPage(initialDate: DateTime.now()),
                        ),
                        (route) => false,
                      );
                    } else {
                      // Show Error if email is already taken
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Registration failed. Email might already be in use.",
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brownColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UPDATED HELPER WIDGET ---
  Widget _buildRoleCard({
    required String label,
    required String imagePath,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        // Card Decoration
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : const Color(0xFF9E9E9E),
          borderRadius: BorderRadius.circular(16),
        ),
        // Use Stack to layer Text over Image
        child: Stack(
          children: [
            // 1. The Image (Bottom Right/Center aligned)
            Positioned(
              bottom: -35,
              right: -40,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(16),
                ),
                child: Image.asset(
                  imagePath,
                  height: 180, // Adjust this size to fit your card perfectly
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 2. The Text Label (Top Left)
            Positioned(
              top: 18,
              left: 18,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius(String goal) {
    if (goal == _goals.first) {
      return BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      );
    } else if (goal == _goals.last) {
      return BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      );
    }
    return BorderRadius.zero;
  }
}
