import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mood_entry.dart';
import '../models/sleep_entry.dart';
import 'package:http_parser/http_parser.dart'; // Required for MediaType
import 'package:flutter/material.dart';
import 'dart:io';

class ApiService {
  // IMPORTANT:
  // If testing on an iOS Simulator, use 'http://127.0.0.1:3000/api' or 'localhost'
  // If testing on an Android Emulator, you MUST use 'http://10.0.2.2:3000/api'
  // If testing on a real physical phone, you need your Mac's actual Wi-Fi IP address!
  final String baseUrl = "http://localhost:3000/api";

  // --- POST: User Registration ---
  Future<String?> registerNewUser(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['userId']; // Return the new ID
      } else {
        print("Registration failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Registration Error: $e");
      return null;
    }
  }

  // --- POST: User Login ---
  // Changed return type from String? to Map<String, dynamic>?
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        // Return the ENTIRE user data package!
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // ==========================================
  // GET REQUESTS (For the Progress Dashboard)
  // ==========================================

  // --- GET: Fetch Today's Mood ---
  Future<MoodEntry?> getTodaysMood(String userId, String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/moods/$userId'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List && decoded.isNotEmpty) {
          // Wrap it in Map<String, dynamic>.from() to satisfy Dart's strict typing!
          return MoodEntry.fromJson(Map<String, dynamic>.from(decoded.last));
        } else if (decoded is Map && !decoded.containsKey('data')) {
          return MoodEntry.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      return null;
    } catch (e) {
      print("Error fetching mood: $e");
      return null;
    }
  }

  // --- GET: Fetch Today's Sleep ---
  Future<SleepEntry?> getTodaysSleep(String userId, String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sleep/$userId'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List && decoded.isNotEmpty) {
          // Wrap it in Map<String, dynamic>.from() here too!
          return SleepEntry.fromJson(Map<String, dynamic>.from(decoded.last));
        } else if (decoded is Map && !decoded.containsKey('data')) {
          return SleepEntry.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      return null;
    } catch (e) {
      print("Error fetching sleep: $e");
      return null;
    }
  }

  // ==========================================
  // POST REQUESTS (For the Submit Buttons)
  // ==========================================

  // --- POST: Save a new Mood Entry ---
  Future<bool> createMoodEntry(MoodEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/moods'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(entry.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error saving mood: $e");
      return false;
    }
  }

  // --- POST: Save a new Sleep Entry ---
  Future<bool> createSleepEntry(SleepEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sleep'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(entry.toJson()),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error saving sleep: $e");
      return false;
    }
  }

  // 1. Request the OTP
  Future<String?> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/users/forgot-password',
        ), // Ensure this matches your server.js mount!
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}), // Trim spaces here too
      );

      // --- ADD THIS DEBUG PRINT ---
      print(
        "Forgot Password Response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['devCode'];
      }
      return null;
    } catch (e) {
      print("Forgot Password Catch Error: $e");
      return null;
    }
  }

  // 2. Submit the new password
  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Reset Password Error: $e");
      return false;
    }
  }

  // ---> BULLETPROOF: FETCH MOODS <---
  Future<List<dynamic>> fetchUserMoods(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/moods/$userId'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Check what shape the data is in and handle it safely!
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'] is List ? decoded['data'] : [];
        } else if (decoded is Map) {
          return [decoded]; // Wraps a single object in a list just in case
        }
      }
      return [];
    } catch (e) {
      print("Error fetching moods: $e");
      return [];
    }
  }

  // ---> BULLETPROOF: FETCH SLEEP <---
  Future<List<dynamic>> fetchUserSleep(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/sleep/$userId'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Check what shape the data is in and handle it safely!
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'] is List ? decoded['data'] : [];
        } else if (decoded is Map) {
          return [decoded];
        }
      }
      return [];
    } catch (e) {
      print("Error fetching sleep: $e");
      return [];
    }
  }

  // 1. SAVE or UPDATE a routine
  Future<bool> saveRoutine(Map<String, dynamic> routineData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/routines'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(routineData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error saving routine: $e");
      return false;
    }
  }

  // 2. FETCH routines for a user
  Future<List<dynamic>> fetchUserRoutines(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/routines/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching routines: $e");
      return [];
    }
  }

  // 3. DELETE a routine
  Future<bool> deleteRoutine(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/routines/$taskId'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting routine: $e");
      return false;
    }
  }

  // ==========================================
  // PROGRESS & BZPOINTS API CALLS
  // ==========================================

  // 1. Fetch Today's Progress & Total Points
  Future<Map<String, dynamic>?> fetchTodayProgress(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/today/$userId'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Make sure bzPoints comes from Progress, not User
        return {
          'bzPoints': decoded['bzPoints'],
          'dailyProgress': decoded['dailyProgress'],
          'alreadyClaimedToday': decoded['alreadyClaimedToday'] ?? false,
        };
      } else {
        print("Failed to load progress: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching progress: $e");
      return null;
    }
  }

  // 2. Update a specific task (e.g., "hasInteractedWithCommunity")
  Future<bool> updateDailyTask(String userId, String taskType) async {
    try {
      final response = await http.patch(
        // MAKE SURE THIS ENDS IN /progress/update-task/
        Uri.parse('$baseUrl/progress/update-task/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'taskType': taskType}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 3. Claim the 5 BZPoints!
  Future<dynamic> claimBzPoints(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/progress/claim/$userId'),
      );

      print(
        "🚀 CLAIM API RESPONSE: ${response.statusCode} - ${response.body}",
      ); // <-- ADD THIS

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Return the Map!
      }
      return null;
    } catch (e) {
      print("Claim API Error: $e");
      return null;
    }
  }

  // Fetch permanent point history
  // 1. Fetch permanent point history from MongoDB
  Future<List<dynamic>> fetchPointHistory(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/points/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching point history: $e");
      return [];
    }
  }

  // 2. Save a new point transaction (Welcome, Daily Task, etc.)
  Future<bool> savePointTransaction(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/points/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error saving point transaction: $e");
      return false;
    }
  }

  // 1. Fetch the family list
  Future<List<dynamic>> fetchFamilyMembers(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/family/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching family: $e");
      return [];
    }
  }

  // 2. Save or Update a member
  Future<Map<String, dynamic>?> saveFamilyMember(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/family/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // ADD THESE TWO LINES TO SEE THE ERROR
      print("Family Save Response: ${response.statusCode}");
      print("Family Save Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Network Error in Family Save: $e");
      return null;
    }
  }

  // 3. Delete a member
  Future<bool> deleteFamilyMember(String id) async {
    try {
      // This 'id' must be the 24-character string from MongoDB
      final response = await http.delete(Uri.parse('$baseUrl/family/$id'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 1. Fetch posts with optional category filtering
  Future<List<dynamic>> fetchPosts([String category = 'For you']) async {
    try {
      // If the category is "For you", we fetch everything
      final url = category == 'For you'
          ? '$baseUrl/posts'
          : '$baseUrl/posts?category=$category';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }

  Future<bool> createPost(Map<String, dynamic> data) async {
    try {
      print("Sending post to: $baseUrl/create"); // Check the URL
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // THESE TWO LINES WILL REVEAL THE PROBLEM:
      print("Post Response Code: ${response.statusCode}");
      print("Post Response Body: ${response.body}");

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Network Error while posting: $e");
      return false;
    }
  }

  Future<bool> addComment(
    String postId,
    Map<String, dynamic> commentData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(commentData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error adding comment: $e");
      return false;
    }
  }

  Future<int> createPostWithImages({
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    required List<String> categories,
    required List<File> images,
  }) async {
    try {
      // 1. Setup the Multipart Request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/posts/create'),
      );

      // 2. Attach Text Fields
      request.fields['userId'] = userId;
      request.fields['userName'] = userName;
      request.fields['userImage'] = userImage;
      request.fields['content'] = content;
      request.fields['categories'] = categories.join(',');

      // 3. Attach Image Files
      for (var image in images) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images', // Must match upload.array('images') in your Node.js
            image.path,
          ),
        );
      }

      // 4. Send and receive response
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Upload Response: ${response.statusCode} - ${response.body}");

      // 5. Return status codes to the UI
      if (response.statusCode == 200 || response.statusCode == 201) {
        return 201; // Success
      } else if (response.statusCode == 400) {
        return 400; // Blocked by Gemini AI
      }
      return 500; // General Server Error
    } catch (e) {
      print("Error uploading post: $e");
      return 500;
    }
  }

  // --- TOGGLE LIKE ---
  Future<bool> toggleLike(String postId, String userId) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '$baseUrl/posts/$postId/like',
        ), // Ensure this matches your Node.js route
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error toggling like: $e");
      return false;
    }
  }

  // --- DELETE POST ---
  Future<bool> deletePost(String postId) async {
    print("Attempting to delete post with ID: $postId"); // ADD THIS
    try {
      final response = await http.delete(Uri.parse('$baseUrl/posts/$postId'));
      print("Delete Response Status: ${response.statusCode}"); // ADD THIS
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting post: $e");
      return false;
    }
  }
}
