import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import to access MyAppState
import 'dart:convert';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final Color brownColor = const Color(0xFF5D4037);

  // Image Picker Logic
  // Image Picker Logic (Upgraded to Base64!)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      imageQuality: 50,
    );

    if (image != null) {
      // 1. Read the image file as bytes
      final bytes = await File(image.path).readAsBytes();

      // 2. Convert those bytes into a Base64 string
      final base64String = base64Encode(bytes);

      if (mounted) {
        // 3. Save the string to the correct 'profileImage' field!
        context.read<MyAppState>().updateUserProfile(
          'profileImage', // <--- Changed from profileImagePath!
          base64String,
        );
      }
    }
  }

  // 1. Text Field Editor Dialog
  void _editTextDetail(
    String dbKey,
    String title,
    String currentValue, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    TextEditingController controller = TextEditingController(
      text: currentValue == "Not provided" ? "" : currentValue,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit $title",
          style: TextStyle(color: brownColor, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: "Enter your $title",
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: brownColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              String newValue = controller.text.trim();
              if (title == "Phone No." && newValue.isEmpty) {
                newValue = "Not provided";
              } else if (newValue.isEmpty && title != "Phone No.") {
                return;
              }

              // Push the new value to our central database state
              context.read<MyAppState>().updateUserProfile(dbKey, newValue);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: brownColor),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. Date Picker for D.O.B
  Future<void> _editDob() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: brownColor),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      String formattedDate =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      if (mounted) {
        context.read<MyAppState>().updateUserProfile('dob', formattedDate);
      }
    }
  }

  // 3. Bottom Sheet for Gender
  void _editGender() {
    final List<String> genders = ["Female", "Male", "Prefer not to say"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Gender",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...genders.map(
              (gender) => ListTile(
                title: Text(gender, textAlign: TextAlign.center),
                onTap: () {
                  context.read<MyAppState>().updateUserProfile(
                    'gender',
                    gender,
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. iOS-Style Cupertino Picker for Location
  void _editLocation(String currentLocation) {
    final List<String> countries = [
      "Australia",
      "Canada",
      "China",
      "India",
      "Indonesia",
      "Japan",
      "Malaysia",
      "Philippines",
      "Singapore",
      "South Korea",
      "Thailand",
      "United Kingdom",
      "United States",
      "Vietnam",
    ];

    int selectedIndex = countries.indexOf(currentLocation);
    if (selectedIndex == -1) selectedIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SizedBox(
        height: 300,
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<MyAppState>().updateUserProfile(
                        'location',
                        countries[selectedIndex],
                      );
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Done",
                      style: TextStyle(
                        color: brownColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedIndex = index;
                },
                children: countries
                    .map(
                      (country) => Center(
                        child: Text(
                          country,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen to the global database state
    var appState = context.watch<MyAppState>();
    var profile = appState.userProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Account details",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Image Section
            Center(
              child: Column(
                children: [
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
                      radius: 45,
                      backgroundColor: const Color(0xFFE0E0E0),
                      // Use the central helper from MyAppState
                      backgroundImage: appState.getProfileImage(
                        profile['profileImage'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: const Text(
                      "Edit profile image",
                      style: TextStyle(
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Form Fields (Pass the database key, title, and current value)
            _buildDetailRow(
              "Name",
              profile['name'],
              () => _editTextDetail('name', "Name", profile['name']),
            ),
            _buildDetailRow(
              "Username",
              profile['username'],
              () =>
                  _editTextDetail('username', "Username", profile['username']),
            ),
            _buildDetailRow(
              "Email",
              profile['email'],
              () => _editTextDetail(
                'email',
                "Email",
                profile['email'],
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            _buildDetailRow(
              "Phone No.",
              profile['phone'],
              () => _editTextDetail(
                'phone',
                "Phone No.",
                profile['phone'],
                keyboardType: TextInputType.phone,
              ),
            ),
            _buildDetailRow("D.O.B", profile['dob'], _editDob),
            _buildDetailRow("Gender", profile['gender'], _editGender),
            _buildDetailRow(
              "Location",
              profile['location'],
              () => _editLocation(profile['location']),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // UI Builder
  Widget _buildDetailRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: value == "Not provided" || value == "Not specified"
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
