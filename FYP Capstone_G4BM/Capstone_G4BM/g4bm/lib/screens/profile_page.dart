import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'login_page.dart';

// Import all the pages we connect to
import 'account_details_page.dart';
import 'mood_insights_page.dart';
import 'posts_page.dart';
import 'my_family_page.dart';
import 'reward_page.dart';
import 'crisis_support_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color topBgColor = const Color(0xFFC0B6AF); // Greyish beige top
    final Color creamBg = const Color(0xFFEBE5DE); // App background

    // 1. Listen to the global database state
    var appState = context.watch<MyAppState>();
    var profile = appState.userProfile;

    return Scaffold(
      backgroundColor: creamBg,
      body: Stack(
        children: [
          // 1. BACKGROUND CURVED LAYER
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            decoration: BoxDecoration(
              color: topBgColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(50),
              ),
            ),
          ),

          // 2. FOREGROUND CONTENT LAYER
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  "Profile",
                  style: GoogleFonts.darumadropOne(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Picture (Dynamically loaded)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: appState.getProfileImage(
                      appState.userProfile['profileImage'],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // User Name & Username (Dynamically loaded)
                Text(
                  profile['name'] ?? "Mama Bear",
                  style: GoogleFonts.darumadropOne(
                    color: Colors.black87,
                    fontSize: 24,
                  ),
                ),
                Text(
                  profile['username'] ?? "@mamabear_01",
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),

                const SizedBox(
                  height: 20,
                ), // Spacing between text and the white box
                // Menu List Box & Sign Out Button (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // The White Selection Box
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                "Account details",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AccountDetailsPage(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                "My Mood Insights",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MoodInsightsPage(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                "Posts",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PostsPage(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                "Family",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyFamilyPage(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                "Rewards",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RewardPage(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                "Crisis Support",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CrisisSupportPage(),
                                  ),
                                ),
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                "Settings",
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SIGN OUT BUTTON
                        TextButton(
                          onPressed: () {
                            _showSignOutDialog(context);
                          },
                          child: const Text(
                            "Sign Out",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.red,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Sign Out",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to sign out of this account?",
          ),
          actions: [
            // CANCEL BUTTON
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Just close the dialog
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            // CONFIRM SIGN OUT BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // 1. Close the dialog
                Navigator.pop(dialogContext);

                // 2. Clear data from AppState
                Provider.of<MyAppState>(context, listen: false).logout();

                // 3. Navigate to Login AND destroy the navigation history
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ), // Replace with your actual Login Page widget name
                  (Route<dynamic> route) =>
                      false, // This returns false for all old routes, deleting them
                );
              },
              child: const Text(
                "Sign Out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helpers for building the menu items smoothly
  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
      indent: 20,
      endIndent: 20,
    );
  }
}
