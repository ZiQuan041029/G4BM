import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class CrisisSupportPage extends StatefulWidget {
  const CrisisSupportPage({super.key});

  @override
  State<CrisisSupportPage> createState() => _CrisisSupportPageState();
}

class _CrisisSupportPageState extends State<CrisisSupportPage> {
  // Constants for design and data
  final Color beigeBg = const Color(0xFFE5DECF); // Beige background color
  final Color darkGray = const Color(0xFF333333); // Dark gray text
  final Color lightGray = const Color(0xFF757575); // Light gray text
  final Color mmhaCardShadow = Colors.black.withOpacity(0.08); // Card shadow
  final Color sosRed = const Color(0xFFFF1A1A); // Red for SOS button

  // State variables for location
  final loc.Location _location = loc.Location();
  bool _isLiveLocationShared = false; // Is the switch ON or OFF
  bool _isLocationServiceEnabled = false; // Is GPS enabled on phone
  bool _isLocationPermissionGranted = false; // App has permission

  @override
  void initState() {
    super.initState();
    // Check the location status as soon as the page loads
    _checkLocationStatus();
  }

  // --- Logic for Location Checks ---

  Future<void> _checkLocationStatus() async {
    // 1. Check if location services (GPS) are enabled on the device
    final serviceEnabled = await _location.serviceEnabled();
    _isLocationServiceEnabled = serviceEnabled;

    // 2. Check and request location permission
    if (serviceEnabled) {
      // Use permission_handler to request permission
      final status = await Permission.location.request();
      if (status.isGranted) {
        _isLocationPermissionGranted = true;
      } else {
        _isLocationPermissionGranted = false;
        // Reset the switch if permission is denied
        if (_isLiveLocationShared) {
          setState(() => _isLiveLocationShared = false);
        }
      }
    } else {
      // If service is disabled, we cannot know or get permission.
      _isLocationPermissionGranted = false;
      if (_isLiveLocationShared) {
        setState(() => _isLiveLocationShared = false);
      }
    }

    // Refresh UI with new states
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onToggleLiveLocation(bool value) async {
    // If the user tries to turn it ON, we must re-check everything
    if (value) {
      // Check service and request permission combined
      var status = await Permission.location.request();
      if (!status.isGranted) {
        // Show a message or do nothing. We rely on standard OS prompt.
        await _checkLocationStatus(); // Re-sync states
        return;
      }
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        // Show message or prompt to enable. Standard OS behavior is better.
        await _checkLocationStatus(); // Re-sync states
        return;
      }

      // If all checks pass, allow turning it ON
      setState(() => _isLiveLocationShared = true);
    } else {
      // User is turning it OFF. Simple state change.
      setState(() => _isLiveLocationShared = false);
    }
  }

  // --- Logic for Making Calls ---

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Handle error: Could not dial number
      debugPrint('Could not launch call to $phoneNumber');
    }
  }

  // --- Dialogs with Confirmation ---

  void _showSOSConfirmationDialog(BuildContext context) {
    const String sosNumber = "+60 3-7627 2929"; // Befrienders Kuala Lumpur
    const String departmentName = "Befrienders Kuala Lumpur";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dial Befrienders?"),
        content: Text(
          "This will transfer you to a call with $sosNumber which is $departmentName.\n\nAre you sure to proceed?",
          style: TextStyle(color: Colors.black.withOpacity(0.8), height: 1.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close dialog
            child: Text("Discard", style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCBB7A9), // Taupe confirm button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _makePhoneCall(sosNumber); // Make the call
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMMHAConfirmationDialog(BuildContext context) {
    const String mmhaNumber = "+60 3-2780 6803";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Call MMHA?"),
        content: Text(
          "This will dial MMHA at $mmhaNumber.\n\nAre you sure to proceed?",
          style: TextStyle(color: Colors.black.withOpacity(0.8), height: 1.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Close dialog
            child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCBB7A9), // Taupe confirm button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _makePhoneCall(mmhaNumber); // Make the call
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI BUILD FUNCTION
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // A flag to decide if the live location switch should be enabled for interaction
    // It's only truly usable if both services are ON and permission is GRANTED.
    bool canUseLiveLocation =
        _isLocationServiceEnabled && _isLocationPermissionGranted;

    return Scaffold(
      backgroundColor: beigeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // The prompt image shows a centered title and search on right, standard back on left.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Emergency Helpline",
          style: GoogleFonts.darumadropOne(color: Colors.black87, fontSize: 26),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), // Page padding
        child: Column(
          children: [
            // --- 1. LIVE LOCATION CARD ---
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: const Text(
                    "Share live location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // The switch logic: only active if canUseLiveLocation is true
                  trailing: Switch(
                    value: _isLiveLocationShared,
                    onChanged: canUseLiveLocation
                        ? _onToggleLiveLocation
                        : null, // Disabled if checks fail
                    activeColor: const Color(0xFF4A3B32), // Dark brown ON color
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. EMERGENCY DESCRIPTION ---
            Text(
              "Are you in an emergency?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Press the button below and help will get to you fast",
                style: TextStyle(fontSize: 16, color: lightGray, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),

            // --- 3. LARGE SOS BUTTON ---
            _buildSOSButton(context),
            const SizedBox(height: 50), // Large spacing below SOS
            // --- 4. MMHA INFORMATION CARD ---
            _buildMMHACard(),
            const SizedBox(height: 20),

            // --- 5. "CALL NOW" TEXT BUTTON ---
            _buildCallNowLink(context),
            const SizedBox(height: 30), // Extra bottom padding
          ],
        ),
      ),
    );
  }

  // ==========================================
  // UI WIDGET COMPONENTS
  // ==========================================

  Widget _buildSOSButton(BuildContext context) {
    const double size = 180; // Size of the main button circle

    return GestureDetector(
      onTap: () => _showSOSConfirmationDialog(
        context,
      ), // Trigger the confirmation dialog
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sosRed, // Bright red
            boxShadow: [
              BoxShadow(
                color: sosRed.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Concentric "pulsing" rings
              Container(
                width: size * 1.25,
                height: size * 1.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: sosRed.withOpacity(0.4), width: 1),
                ),
              ),
              Container(
                width: size * 1.5,
                height: size * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: sosRed.withOpacity(0.3), width: 1),
                ),
              ),
              Container(
                width: size * 1.75,
                height: size * 1.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: sosRed.withOpacity(0.2), width: 1),
                ),
              ),

              // White "SOS" Text
              const Text(
                "SOS",
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMMHACard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: mmhaCardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logo Section
          _buildMMHALogo(),
          const SizedBox(width: 15),

          // 2. Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Malaysian Mental Health Association (MMHA)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Phone Number: +60 3-2780 6803",
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  "Operating Hours: Monday to Friday, 9:00 AM to 5:00 PM (excluding public holidays)",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for the logo (looks custom in image)
  Widget _buildMMHALogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDEC), // Off-white
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Icon(Icons.health_and_safety, color: lightGray, size: 30),
      ),
    );
  }

  Widget _buildCallNowLink(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => _showMMHAConfirmationDialog(
            context,
          ), // Trigger confirmation dialog
          child: Column(
            children: [
              Text(
                "Call Now",
                style: GoogleFonts.darumadropOne(
                  color: const Color(0xFFFF5252),
                  fontSize: 18,
                ), // Red Color
              ),
              const SizedBox(height: 2),
              Container(
                width: 60,
                height: 1.5,
                color: const Color(0xFFFF5252),
              ), // Red underline
            ],
          ),
        ),
      ],
    );
  }
}
