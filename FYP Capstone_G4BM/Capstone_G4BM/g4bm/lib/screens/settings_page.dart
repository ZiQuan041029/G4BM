import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final Color topBgColor = const Color(0xFFC0B6AF); // Greyish beige top
  final Color creamBg = const Color(0xFFEBE5DE); // App background
  final Color brownColor = const Color(0xFF5D4037);

  // Local state for toggles
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: Stack(
        children: [
          // 1. BACKGROUND CURVED LAYER
          Container(
            height: 200, // Shorter curve since there's no profile picture
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.settings, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        "Settings",
                        style: GoogleFonts.darumadropOne(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Settings Card Box (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // --- ACCOUNT SETTINGS SECTION ---
                          _buildSectionHeader("Account Settings"),

                          _buildClickableItem(
                            "Change password",
                            onTap: () => _showChangePasswordDialog(context),
                          ),
                          _buildDivider(),

                          _buildClickableItem(
                            "Linked Accounts",
                            // Example of showing connected Google Account info later
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("No account linked yet."),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),

                          // Notification Toggle
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Notifications",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Switch(
                                  value: _notificationsEnabled,
                                  activeColor: Colors.black,
                                  onChanged: (value) {
                                    setState(() {
                                      _notificationsEnabled = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),
                          const Divider(
                            thickness: 8,
                            color: Color(0xFFF5F5F5),
                          ), // Thick divider between sections
                          const SizedBox(height: 10),

                          // --- MORE SECTION ---
                          _buildSectionHeader("More"),

                          _buildClickableItem("About us", onTap: () {}),
                          _buildDivider(),
                          _buildClickableItem("Privacy policy", onTap: () {}),
                          _buildDivider(),
                          _buildClickableItem(
                            "Terms and conditions",
                            onTap: () {},
                          ),
                          _buildDivider(),
                          _buildClickableItem("FAQ", onTap: () {}),

                          const SizedBox(height: 20),
                        ],
                      ),
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

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildClickableItem(String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
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

  // --- LOGIC: CHANGE PASSWORD DIALOG ---

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows it to move up with the keyboard
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(
                  context,
                ).viewInsets.bottom, // Moves up with keyboard
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Old Password Field
                    _buildPasswordField(
                      "Current Password",
                      oldPasswordController,
                      obscureOld,
                      () {
                        setModalState(() => obscureOld = !obscureOld);
                      },
                    ),
                    const SizedBox(height: 16),

                    // New Password Field
                    _buildPasswordField(
                      "New Password",
                      newPasswordController,
                      obscureNew,
                      () {
                        setModalState(() => obscureNew = !obscureNew);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm New Password Field
                    _buildPasswordField(
                      "Confirm New Password",
                      confirmPasswordController,
                      obscureConfirm,
                      () {
                        setModalState(() => obscureConfirm = !obscureConfirm);
                      },
                      validator: (value) {
                        if (value != newPasswordController.text)
                          return "Passwords do not match";
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            // Show Loading Spinner
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

                            // Call Database Logic
                            bool success = await appState.changeUserPassword(
                              oldPasswordController.text,
                              newPasswordController.text,
                            );

                            // Hide Loading Spinner
                            Navigator.pop(context);

                            if (success) {
                              Navigator.pop(context); // Close Bottom Sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Password updated successfully!",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Incorrect current password.",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brownColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Update Password",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper for password text fields
  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback onToggleVisibility, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return "Field cannot be empty";
            if (value.length < 6)
              return "Password must be at least 6 characters";
            return null;
          },
    );
  }
}
