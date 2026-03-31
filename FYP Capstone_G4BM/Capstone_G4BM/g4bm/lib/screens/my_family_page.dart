import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:g4bm/main.dart';
import 'package:provider/provider.dart';

class MyFamilyPage extends StatefulWidget {
  final String initialFilter;
  const MyFamilyPage({super.key, this.initialFilter = 'All'});

  @override
  State<MyFamilyPage> createState() => _MyFamilyPageState();
}

class _MyFamilyPageState extends State<MyFamilyPage> {
  final Color creamBg = const Color(0xFFEBE5DE);
  final Color darkBrown = const Color(0xFF4A3B32);
  final Color lightBrown = const Color(0xFFAFA296);

  final Color taupeCard = const Color(0xFFCBB7A9);
  final Color healthTaupe = const Color(0xFFCEB8A7);
  final Color devTaupe = const Color(0xFFA09388);
  final Color reminderGreen = const Color(0xFF758C65);

  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var familyMembers = appState.familyMembers;
    print("UI is rendering ${familyMembers.length} members");
    bool isAllSelected = _selectedFilter == 'All';
    List<Map<String, dynamic>> displayedMembers = isAllSelected
        ? familyMembers
        : familyMembers.where((m) => m['name'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Family",
          style: GoogleFonts.darumadropOne(color: Colors.black87, fontSize: 28),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildProfileSelector(familyMembers),
            const SizedBox(height: 25),

            Expanded(
              child: displayedMembers.isEmpty
                  ? Center(
                      child: Text(
                        "No family members found.",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : isAllSelected
                  ? _buildSimplifiedListView(displayedMembers)
                  : _buildDetailedProfileView(displayedMembers.first),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () {
            if (isAllSelected) {
              _openMemberForm(); // ADD MODE
            } else {
              _openMemberForm(member: displayedMembers.first); // EDIT MODE
            }
          },
          backgroundColor: darkBrown,
          shape: const CircleBorder(),
          child: Icon(
            isAllSelected ? Icons.add : Icons.edit,
            color: Colors.white,
            size: 35,
          ),
        ),
      ),
    );
  }

  // --- SHEET TRIGGER ---
  void _openMemberForm({Map<String, dynamic>? member}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FamilyMemberFormSheet(
        existingMember: member,
        onSave: (updatedMember) {
          context.read<MyAppState>().saveFamilyMember(updatedMember);

          setState(() {
            if (_selectedFilter != 'All')
              _selectedFilter = updatedMember['name'];
          });
        },
        onDelete: (deletedId) {
          context.read<MyAppState>().deleteFamilyMember(deletedId);
          setState(() {
            _selectedFilter = 'All'; // Kick them back to the "All" tab!
          });
        },
      ),
    );
  }

  // ==========================================
  // TOP PROFILE SELECTOR
  // ==========================================
  Widget _buildProfileSelector(List<Map<String, dynamic>> familyMembers) {
    List<String> filters = ['All'];
    filters.addAll(familyMembers.map((m) => m['name'] as String));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? darkBrown : lightBrown.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // LIST VIEW ("All")
  // ==========================================
  Widget _buildSimplifiedListView(List<Map<String, dynamic>> members) {
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildFamilyCard(members[index]),
        );
      },
    );
  }

  Widget _buildFamilyCard(Map<String, dynamic> member) {
    List<dynamic> reminders = member['reminders'] ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: taupeCard,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(member['image'], 90),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: GoogleFonts.darumadropOne(
                        fontSize: 28,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        member['relationship'],
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Reminder",
            style: GoogleFonts.darumadropOne(fontSize: 22, color: Colors.white),
          ),
          const SizedBox(height: 10),
          if (reminders.isEmpty)
            const Text(
              "No reminders set.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            )
          else
            ...reminders.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildSimpleReminderRow(r["title"], r["isDone"]),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // DETAILED VIEW (Specific Person)
  // ==========================================
  Widget _buildDetailedProfileView(Map<String, dynamic> member) {
    // Format presentation data
    String heightWeight = "${member['height']} cm / ${member['weight']} kg";
    String dobDisplay = "-";
    if (member['dob'] != null && member['dob'].toString().isNotEmpty) {
      DateTime? parsed = DateTime.tryParse(member['dob']);
      if (parsed != null) dobDisplay = DateFormat('dd MMM yyyy').format(parsed);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(member['image'], 140, isSquare: true),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            member['name'],
                            style: GoogleFonts.darumadropOne(
                              fontSize: 30,
                              color: darkBrown,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: taupeCard.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            member['relationship'],
                            style: TextStyle(
                              color: darkBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow("Age", "${member['age'] ?? 0} years"),
                          _buildDetailRow("Gender", member['gender'] ?? "-"),
                          _buildDetailRow("D.O.B", dobDisplay),
                          _buildDetailRow(
                            "Education",
                            member['education'] ?? "-",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Health Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: healthTaupe,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Health Overview",
                        style: GoogleFonts.darumadropOne(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildStatColumn("Height & Weight", heightWeight),
                      const SizedBox(height: 10),
                      _buildStatColumn(
                        "Sleep Quality",
                        member['sleepQuality']?.toString() ?? "-",
                      ),
                      const SizedBox(height: 10),
                      _buildStatColumn(
                        "Physical Active Level",
                        member['physicalLevel']?.toString() ?? "-",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Health Notes",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member['healthNotes'] ?? "-",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Development & Routine Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: devTaupe,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Development",
                          style: GoogleFonts.darumadropOne(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStatColumn(
                          "Emotional State",
                          member['emotionalState']?.toString() ?? "-",
                        ),
                        const SizedBox(height: 10),
                        _buildStatColumn(
                          "Social Interaction",
                          member['socialInteraction']?.toString() ?? "-",
                        ),
                        const SizedBox(height: 10),
                        _buildStatColumn(
                          "Learning / Focus Level",
                          member['learningFocus']?.toString() ?? "-",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 10,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: devTaupe,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Routine",
                          style: GoogleFonts.darumadropOne(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStatColumn(
                          "Screen Time",
                          member['screenTime']?.toString() ?? "-",
                        ),
                        const SizedBox(height: 10),
                        _buildStatColumn(
                          "Outdoor Activity",
                          member['outdoorActivity']?.toString() ?? "-",
                        ),
                        const SizedBox(height: 10),
                        _buildStatColumn(
                          "Eating Habits",
                          member['eatingHabits']?.toString() ?? "-",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reminders
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: reminderGreen,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reminder",
                  style: GoogleFonts.darumadropOne(
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ...(member['reminders'] as List).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildSimpleReminderRow(r["title"], r["isDone"]),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _buildAvatar(String imagePath, double size, {bool isSquare = false}) {
    bool isFile = imagePath.startsWith('/');
    return Container(
      width: size,
      height: isSquare ? size + 20 : size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSquare ? 25 : size / 2),
        image: DecorationImage(
          image: isFile
              ? FileImage(File(imagePath)) as ImageProvider
              : AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleReminderRow(String text, bool isDone) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// ADD & EDIT BOTTOM SHEET
// ==========================================
class FamilyMemberFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existingMember;
  final Function(Map<String, dynamic>) onSave;
  final Function(String)? onDelete;

  const FamilyMemberFormSheet({
    super.key,
    this.existingMember,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<FamilyMemberFormSheet> createState() => _FamilyMemberFormSheetState();
}

class _FamilyMemberFormSheetState extends State<FamilyMemberFormSheet> {
  final Color darkSheet = const Color(0xFF433D38);

  // Form State
  String imagePath = 'assets/default_user_pp.png';
  TextEditingController nameController = TextEditingController();
  TextEditingController newReminderController = TextEditingController();
  TextEditingController healthNotesController = TextEditingController();

  String role = 'Child';
  String gender = 'Female';
  int age = 0;
  DateTime? dob;
  String education = 'None';

  int height = 0;
  double weight = 0;
  String sleepQuality = 'Moderate';
  String physicalLevel = 'Active';
  String emotionalState = 'Calm';
  String socialInteraction = 'Moderate';
  String learningFocus = 'Moderate';

  String screenTime = 'Moderate';
  String outdoorActivity = 'Yes';
  String eatingHabits = '-';

  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();

    if (widget.existingMember != null) {
      final m = widget.existingMember!;
      imagePath = m['image'] ?? 'assets/default_user_pp.png';
      nameController.text = m['name'] ?? '';
      healthNotesController.text =
          (m['healthNotes'] == null || m['healthNotes'] == "-")
          ? ''
          : m['healthNotes'];
      role = m['relationship'] ?? 'Child';
      gender = m['gender'] ?? 'Female';
      age = (m['age'] ?? 0) as int;
      if (m['dob'] != null && m['dob'].toString().isNotEmpty) {
        dob = DateTime.tryParse(m['dob'].toString());
      }
      education = m['education'] ?? 'None';
      height = (m['height'] ?? 80) as int;
      weight = (m['weight'] ?? 10.0).toDouble();
      sleepQuality = m['sleepQuality'] ?? 'Moderate';
      physicalLevel = m['physicalLevel'] ?? 'Active';
      emotionalState = m['emotionalState'] ?? 'Calm';
      socialInteraction = m['socialInteraction'] ?? 'Moderate';
      learningFocus = m['learningFocus'] ?? 'Moderate';
      screenTime = m['screenTime'] ?? 'Moderate';
      outdoorActivity = m['outdoorActivity'] ?? 'Yes';
      eatingHabits = m['eatingHabits'] ?? 'Normal';
      reminders = List<Map<String, dynamic>>.from(m['reminders'] ?? []);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => imagePath = pickedFile.path);
    }
  }

  void _save() {
    if (nameController.text.trim().isEmpty) return;

    // We create a CLEAN copy of the reminders to send to the server
    List<Map<String, dynamic>> finalReminders = List<Map<String, dynamic>>.from(
      reminders,
    );

    Map<String, dynamic> newMember = {
      "id": widget.existingMember?['id'],
      "name": nameController.text.trim(),
      "relationship": role,
      "image": imagePath,
      "age": age,
      "gender": gender,
      "dob": dob != null ? DateFormat('yyyy-MM-dd').format(dob!) : "",
      "education": education,
      "height": height,
      "weight": weight,
      "healthNotes": healthNotesController.text.trim().isEmpty
          ? "-"
          : healthNotesController.text.trim(),
      // THIS LINE MUST BE EXACT
      "reminders": finalReminders,
      "sleepQuality": sleepQuality,
      "physicalLevel": physicalLevel,
      "emotionalState": emotionalState,
      "socialInteraction": socialInteraction,
      "learningFocus": learningFocus,
      "screenTime": screenTime,
      "outdoorActivity": outdoorActivity,
      "eatingHabits": eatingHabits,
    };

    widget.onSave(newMember);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: darkSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Header (Cancel / Save)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFCBB7A9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image Picker
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            image: DecorationImage(
                              image: imagePath.startsWith('/')
                                  ? FileImage(File(imagePath)) as ImageProvider
                                  : AssetImage(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Basic Info Group
                  _buildFormGroup([
                    _buildTextInputRow("Name", nameController, "Required"),
                    _buildPickerRow("Role", role, [
                      'Child',
                      'Partner',
                    ], (v) => setState(() => role = v)),
                    _buildPickerRow("Gender", gender, [
                      'Female',
                      'Male',
                    ], (v) => setState(() => gender = v)),
                    _buildScrollerRow("Age", "$age", () => _showAgeScroller()),
                    _buildDateRow("D.O.B", dob, () => _showDatePicker()),
                    _buildPickerRow("Education", education, [
                      'None',
                      'Preschool',
                      'Primary',
                      'Secondary',
                      'Higher Education',
                    ], (v) => setState(() => education = v)),
                  ]),
                  const SizedBox(height: 20),

                  // Health Overview Group
                  const Text(
                    "Health Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFormGroup([
                    _buildScrollerRow(
                      "Height & Weight",
                      "$height cm / $weight kg",
                      () => _showHeightWeightScroller(),
                    ),
                    _buildPickerRow(
                      "Sleep Quality",
                      sleepQuality,
                      ['Low', 'Moderate', 'Good'],
                      (v) => setState(() => sleepQuality = v),
                    ),
                    _buildPickerRow(
                      "Physical Active Level",
                      physicalLevel,
                      [
                        'Not Active',
                        'Needs Attention',
                        'Active',
                        'Hyper-active',
                      ],
                      (v) => setState(() => physicalLevel = v),
                    ),
                    _buildTextInputRow(
                      "Health Notes",
                      healthNotesController,
                      "Optional",
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Development Group
                  const Text(
                    "Development",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFormGroup([
                    _buildPickerRow(
                      "Emotional State",
                      emotionalState,
                      ['Calm', 'Moody'],
                      (v) => setState(() => emotionalState = v),
                    ),
                    _buildPickerRow(
                      "Social Interaction",
                      socialInteraction,
                      ['Low', 'Moderate', 'Good'],
                      (v) => setState(() => socialInteraction = v),
                    ),
                    _buildPickerRow(
                      "Learning / Focus",
                      learningFocus,
                      [
                        'Needs Attention',
                        'Moderate',
                        'Responsive',
                        'Highly Focused',
                        '-',
                      ],
                      (v) => setState(() => learningFocus = v),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Routine Group
                  const Text(
                    "Routine & Habits",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFormGroup([
                    _buildPickerRow("Screen Time", screenTime, [
                      'No screen time',
                      'Moderate',
                      'Too much screen time',
                    ], (v) => setState(() => screenTime = v)),
                    _buildPickerRow(
                      "Outdoor Activity",
                      outdoorActivity,
                      ['Yes', 'No'],
                      (v) => setState(() => outdoorActivity = v),
                    ),
                    _buildPickerRow(
                      "Eating Habits",
                      eatingHabits,
                      [
                        'Picky Eater',
                        'Normal',
                        'Good Appetite',
                        'Overeating',
                        '-',
                      ],
                      (v) => setState(() => eatingHabits = v),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Reminders Editor
                  const Text(
                    "Reminders",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF758C65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        ...reminders.asMap().entries.map((entry) {
                          int idx = entry.key;
                          Map<String, dynamic> r = entry.value;
                          return Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    r['isDone'] = !r['isDone'];
                                  });
                                },
                                child: Icon(
                                  r['isDone']
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r['title'],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => reminders.removeAt(idx)),
                              ),
                            ],
                          );
                        }),
                        const Divider(color: Colors.white54),
                        Row(
                          children: [
                            const Icon(Icons.add, color: Colors.white54),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: newReminderController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Add reminder...",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    setState(() {
                                      // Use a Map that matches your Backend Model
                                      reminders.add({
                                        "title": val.trim(),
                                        "isDone": false,
                                      });
                                    });
                                    newReminderController.clear();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.existingMember != null) ...[
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text(
                          "Delete Family Profile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          // 1. Get the ID safely
                          final memberId = widget.existingMember?['id'];

                          if (memberId == null) {
                            // If there's no ID, just close the sheet (it's an unsaved draft)
                            Navigator.pop(context);
                            return;
                          }
                          // POP-UP CONFIRMATION DIALOG
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Profile?"),
                              content: Text(
                                "Are you sure you want to delete ${nameController.text}'s profile? This cannot be undone.",
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx); // Close Dialog
                                    Navigator.pop(
                                      context,
                                    ); // Close Bottom Sheet
                                    context
                                        .read<MyAppState>()
                                        .deleteFamilyMember(memberId);

                                    if (widget.onDelete != null) {
                                      widget.onDelete!(
                                        widget.existingMember!['id'],
                                      );
                                    }
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FORM ROW HELPERS ---
  Widget _buildFormGroup(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget row = entry.value;
          return Column(
            children: [
              row,
              if (idx < rows.length - 1)
                const Divider(
                  height: 1,
                  indent: 15,
                  endIndent: 15,
                  color: Colors.black12,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextInputRow(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerRow(
    String label,
    String value,
    List<String> options,
    Function(String) onSelect,
  ) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SizedBox(
            height: 250,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController: FixedExtentScrollController(
                initialItem: options.indexOf(value),
              ),
              onSelectedItemChanged: (idx) => onSelect(options[idx]),
              children: options.map((o) => Center(child: Text(o))).toList(),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollerRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime? date, VoidCallback onTap) {
    String valStr = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : "Select Date";
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Text(
                  valStr,
                  style: TextStyle(
                    color: date != null ? Colors.blue : Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SPECIFIC PICKERS ---
  void _showAgeScroller() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 250,
        child: CupertinoPicker(
          itemExtent: 40,
          scrollController: FixedExtentScrollController(initialItem: age),
          onSelectedItemChanged: (idx) => setState(() => age = idx),
          children: List.generate(100, (i) => Center(child: Text("$i years"))),
        ),
      ),
    );
  }

  void _showHeightWeightScroller() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 250,
        child: Row(
          children: [
            // Height Scroller (30 to 200 cm)
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: height - 30,
                ),
                onSelectedItemChanged: (idx) =>
                    setState(() => height = idx + 30),
                children: List.generate(
                  171,
                  (i) => Center(child: Text("${i + 30} cm")),
                ),
              ),
            ),
            // Weight Scroller (1.0 to 150.0 kg)
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: (weight * 10).toInt() - 10,
                ),
                onSelectedItemChanged: (idx) =>
                    setState(() => weight = (idx + 10) / 10.0),
                children: List.generate(
                  1491,
                  (i) => Center(child: Text("${(i + 10) / 10.0} kg")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => dob = picked);
  }
}
