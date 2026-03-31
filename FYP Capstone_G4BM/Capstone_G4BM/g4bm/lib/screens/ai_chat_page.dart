import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'crisis_support_page.dart';
import 'ai_voice_chat_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatPage extends StatefulWidget {
  final String currentUserId;
  const AIChatPage({super.key, required this.currentUserId});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? recommendation;
  ChatMessage({required this.text, required this.isUser, this.recommendation});
}

class _AIChatPageState extends State<AIChatPage> {
  final Color creamBg = const Color(0xFFEBE5DE);
  final Color userBubbleColor = const Color(0xFFBDE076);

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _isAiLoading = false;

  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();

    // Listen to text input changes
    _textController.addListener(() {
      if (!mounted) return;
      setState(() {
        _isTyping = _textController.text.isNotEmpty;
      });
    });

    // Show initial AI greeting after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Hey there! 🌼 I'm Mama, your gentle little emotional buddy.\nHow are you feeling right now?\nYou can tell me anything.",
            isUser: false,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ADD THIS INSIDE _AIChatPageState
  void _handleEmergencyResponse(Map<String, dynamic> data) {
    // Check if 'emergency' exists and if the action is 'trigger_sos'
    if (data['emergency'] != null &&
        data['emergency']['action'] == "trigger_sos") {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false, // User must acknowledge
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1A1A)),
              SizedBox(width: 10),
              Text("We're here for you"),
            ],
          ),
          content: Text(
            data['emergency']['message'] ??
                "It seems like you're going through a tough time. Would you like to see support options?",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "I'm okay",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1A1A), // Red SOS color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to your CrisisSupportPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrisisSupportPage(),
                  ),
                );
              },
              child: const Text("Get Help Now"),
            ),
          ],
        ),
      );
    }
  }

  // -----------------------------
  // SEND USER MESSAGE TO AI
  // -----------------------------
  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    if (!mounted) return;

    setState(() {
      // Add user message and start loading
      _messages.add(ChatMessage(text: text, isUser: true));
      _isAiLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Note: Use 10.0.2.2 instead of localhost if using Android Emulator
      final response = await http.post(
        Uri.parse("http://localhost:5001/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": widget.currentUserId, "message": text}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // FIX: Match the PowerShell keys exactly!
        final String aiReply = data["reply"] ?? "I'm here for you.";
        final String? rec = data["recommendation"];

        setState(() {
          _isAiLoading =
              false; // This MUST be false to hide the "Thinking" bubble
          _messages.add(
            ChatMessage(
              text: aiReply,
              isUser: false,
              recommendation: rec, // Store recommendation
            ),
          );
        });
        _handleEmergencyResponse(data);
      } else {
        throw Exception("Failed to load");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAiLoading = false;
        _messages.add(
          ChatMessage(
            text: "Mama Bear is taking a quick nap. Please try again! 🐻",
            isUser: false,
          ),
        );
      });
    }
    _scrollToBottom();
  }

  Widget _buildRecommendationCard(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 50, bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E7), // Warm cream/yellow
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Mama's Suggestion",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, color: Color(0xFFFFD54F)),
            ),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: Colors.brown[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Optional: Add a small icon or avatar here if you want
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF5D4037),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Mama Bear is thinking...",
                  style: GoogleFonts.inter(
                    fontStyle: FontStyle.italic,
                    color: Colors.brown[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // SCROLL TO BOTTOM
  // -----------------------------
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // -----------------------------
  // BUILD UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: creamBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/G4BM_logo.png',
                width: 35,
                height: 35,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mama Bear",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "@YourAITherapist",
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isAiLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAiLoading && index == _messages.length) {
                  return _buildThinkingBubble();
                }

                final msg = _messages[index];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedChatBubble(message: msg),
                    // If the AI sent a recommendation, show it in a pretty card
                    if (msg.recommendation != null &&
                        msg.recommendation!.isNotEmpty)
                      _buildRecommendationCard(msg.recommendation!),
                  ],
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // -----------------------------
  // INPUT AREA
  // -----------------------------
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 10),
      color: creamBg,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration(
                  hintText: "Message here...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: () {
              if (_isTyping) {
                _handleSubmitted(_textController.text);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIVoiceChatPage()),
                );
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isTyping ? Icons.send : Icons.mic_none,
                color: const Color(0xFF5D4037),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CHAT BUBBLE WIDGET
// ==========================================
class AnimatedChatBubble extends StatefulWidget {
  final ChatMessage message;
  const AnimatedChatBubble({super.key, required this.message});

  @override
  State<AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isUser = widget.message.isUser;

    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.70,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFFBDE076) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isUser
                        ? const Radius.circular(20)
                        : const Radius.circular(5),
                    bottomRight: isUser
                        ? const Radius.circular(5)
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.message.text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                  // unlimited lines
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
            if (isUser)
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                backgroundImage: AssetImage('assets/default_user_pp.png'),
              ),
          ],
        ),
      ),
    );
  }
}
