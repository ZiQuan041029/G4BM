import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart'; // Needed for scroll direction logic
import 'package:share_plus/share_plus.dart'; // For the share button
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:g4bm/main.dart';
import 'package:provider/provider.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  // --- STATE VARIABLES ---
  String _selectedCategory = "For you";
  bool _isPostButtonVisible = true;
  late ScrollController _scrollController;

  String _getTimeAgo(String? isoString) {
    if (isoString == null) return "Just now";
    try {
      DateTime postTime = DateTime.parse(isoString).toLocal();
      Duration diff = DateTime.now().difference(postTime);
      if (diff.inDays > 0) return "${diff.inDays} days ago";
      if (diff.inHours > 0) return "${diff.inHours} hrs ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes} mins ago";
      return "Just now";
    } catch (e) {
      return "Recently";
    }
  }

  // --- CATEGORIES ---
  final List<String> _categories = [
    "For you",
    "Childcare",
    "Maternity",
    "Me-Time",
    "Family",
    "Mental Health",
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    Future.microtask(() {
      if (mounted) {
        context.read<MyAppState>().loadCommunityPosts(
          category: _selectedCategory,
        );
      }
    });

    // --- SMART SCROLL LOGIC ---
    _scrollController.addListener(() {
      // If user scrolls UP, show button. If user scrolls DOWN, hide button.
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_isPostButtonVisible) setState(() => _isPostButtonVisible = false);
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_isPostButtonVisible) setState(() => _isPostButtonVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Always clean up controllers!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // Use the live database posts instead of mock data
    var displayPosts = appState.communityPosts;
    final creamBg = const Color(0xFFEBE5DE);
    final brownColor = const Color(0xFF5D4037);

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 30),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "Community",
          style: GoogleFonts.darumadropOne(color: Colors.black, fontSize: 28),
        ),
        actions: [
          const Icon(Icons.search, color: Colors.black, size: 30),
          const SizedBox(width: 15),
        ],
      ),
      // --- FLOATING POST BUTTON ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isPostButtonVisible ? 1.0 : 0.0,
        child: SizedBox(
          width: 130,
          height: 50,
          child: FloatingActionButton.extended(
            heroTag: 'community_post_btn',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const CreatePostDialog(),
              );
              if (context.mounted) {
                context.read<MyAppState>().loadCommunityPosts(
                  category: _selectedCategory,
                );
              }
            },
            backgroundColor: brownColor,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            label: Text(
              "Post",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- 1. CATEGORY PILLS (Horizontal) ---
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    appState.loadCommunityPosts(
                      category: category,
                    ); // Actually fetch from server!
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? brownColor : Colors.grey[400],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // --- 2. POSTS FEED (Vertical) ---
          Expanded(
            // Check the loading flag first!
            child: appState.isCommunityLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5D4037)),
                  )
                // If not loading, check if it's empty
                : displayPosts.isEmpty
                ? Center(
                    child: Text(
                      "No posts here yet. Be the first to share!",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                // Otherwise, draw the feed!
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: displayPosts.length,
                    itemBuilder: (context, index) {
                      final post = displayPosts[index];
                      return _buildPostCard(post, brownColor, appState);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- INDIVIDUAL POST CARD WIDGET ---
  Widget _buildPostCard(
    Map<String, dynamic> post,
    Color themeColor,
    MyAppState appState,
  ) {
    List likesArray = post['likes'] ?? [];
    bool isLiked = likesArray.contains(appState.currentUserId);
    int likesCount = likesArray.length;
    int commentsCount = post['comments'] is List
        ? (post['comments'] as List).length
        : 0;

    String timeDisplay = _getTimeAgo(post['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
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
          // A. User Info Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  // THE FIX: Use context.read<MyAppState>() directly
                  backgroundImage: context.read<MyAppState>().getProfileImage(
                    post['userImage'],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['userName'] ??
                          "User", // Reads the name from MongoDB!
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // B. Conditional Images Area
          // THE FIX: Check if it's not null AND is a List before checking isNotEmpty
          if (post['images'] != null &&
              post['images'] is List &&
              (post['images'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: (post['images'] as List).length > 2
                    ? 2
                    : (post['images'] as List).length,
                itemBuilder: (context, imgIndex) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      post['images'][imgIndex],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),

          // C. Caption
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              post['content'] ?? '',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
            ),
          ),

          const Divider(height: 1),

          // D. Interaction Bar (Likes, Comments, Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // LIKE
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        String? postId = post['_id'];
                        if (postId != null) {
                          // This tells your database AND refreshes the UI!
                          await appState.toggleLike(postId);
                          appState.markTaskComplete(
                            'hasInteractedWithCommunity',
                          );
                        }
                      },
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey[700],
                        size: 28,
                      ),
                    ),
                    Text(
                      "$likesCount",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                // COMMENT
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showCommentsPopup(context, post),
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey[700],
                        size: 28,
                      ),
                    ),
                    Text(
                      "$commentsCount",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                // SHARE
                IconButton(
                  onPressed: () {
                    // --- NATIVE SHARE LOGIC ---
                    Share.share(
                      "Check out this post from G4BM by ${post['userName']}: \"${post['caption']}\"",
                    );
                  },
                  icon: Icon(
                    Icons.ios_share,
                    color: Colors.grey[700],
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- COMMENTS POPUP WIDGET (Modal Bottom Sheet) ---
  void _showCommentsPopup(BuildContext context, Map<String, dynamic> post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // THE FIX 1: Wrap the whole sheet in a StatefulBuilder
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    "Comments",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),

                  // A. LIVE COMMENTS LIST
                  Expanded(
                    child:
                        (post['comments'] == null ||
                            (post['comments'] as List).isEmpty)
                        ? Center(
                            child: Text(
                              "No comments yet. Be the first!",
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: (post['comments'] as List).length,
                            itemBuilder: (context, index) {
                              var comment = (post['comments'] as List)[index];
                              return _buildCommentItem(
                                context, // Pass context to access getProfileImage
                                comment['userName'] ?? "Anonymous",
                                comment['userImage'] ??
                                    'assets/default_user_pp.png', // Pass the image
                                comment['text'] ?? "",
                                _getTimeAgo(comment['createdAt']),
                              );
                            },
                          ),
                  ),

                  // B. COMMENT INPUT FIELD
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: 10,
                      right: 10,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: "Add a comment...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        IconButton(
                          onPressed: () async {
                            String text = commentController.text.trim();
                            if (text.isEmpty) return;

                            var appState = context.read<MyAppState>();
                            String? postId = post['_id'];

                            // 1. Clear the text field immediately
                            commentController.clear();

                            if (postId != null) {
                              // 2. Call the database ONCE
                              bool success = await appState.addCommentToPost(
                                postId,
                                text,
                              );

                              if (success) {
                                // 3. Refresh the feed from the database
                                await appState.loadCommunityPosts(
                                  category: _selectedCategory,
                                );
                                // Update the popup UI
                                setModalState(() {});
                              }
                              appState.markTaskComplete(
                                'hasInteractedWithCommunity',
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    String user,
    String userImage,
    String text,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            radius: 18,
            // THE FIX: Use the global getProfileImage helper
            backgroundImage: context.read<MyAppState>().getProfileImage(
              userImage,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(color: Colors.black, fontSize: 13),
                    children: [
                      TextSpan(
                        text: "$user  ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: text),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePostDialog extends StatefulWidget {
  const CreatePostDialog({super.key});

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _topics = [
    "Childcare",
    "Maternity",
    "Me-Time",
    "Family",
    "Mental Health",
  ];
  List<String> _selectedTopics = []; // To support multiple tags
  List<File> _selectedImages = [];
  bool _isAnonymous = false;

  final Color brownColor = const Color(0xFF5D4037);

  // Pick image function
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF9F0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. TOP ROW: Cancel & Share ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_captionController.text.isEmpty ||
                          _selectedTopics.isEmpty) {
                        // Show a snackbar or alert: "Please add a caption and select at least one topic!"
                        return;
                      }
                      int status = await context.read<MyAppState>().sharePost(
                        _captionController.text,
                        _selectedTopics,
                        _isAnonymous,
                        _selectedImages,
                      );

                      if (status == 400) {
                        // ❌ BLOCKED
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "⚠️ Post blocked: Please keep the community safe and positive.",
                            ),
                            backgroundColor: Colors.redAccent,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      } else if (status == 500) {
                        // ❌ SERVER ERROR
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Connection error. Please try again later.",
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      } else {
                        Navigator.pop(context); // Close dialog after posting
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brownColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      "Share",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // --- 2. USER INFO PREVIEW ---
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _isAnonymous
                        ? const AssetImage(
                            'assets/default_user_pp.png',
                          ) // Make sure this asset exists!
                        : null, // Replace with actual user profile pic later
                    child: _isAnonymous
                        ? null
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    // THE FIX: Properly switches between Anonymous and Mama Bear
                    _isAnonymous ? "Anonymous" : "Mama Bear",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // --- 3. CAPTION TEXT FIELD ---
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _captionController,
                  maxLines: null, // Allows it to grow
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: "Caption ...",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Select Topics (Required)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _topics.map((topic) {
                  final isSelected = _selectedTopics.contains(topic);
                  return GestureDetector(
                    onTap: () => _toggleTopic(topic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? brownColor : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? brownColor : Colors.black12,
                        ),
                      ),
                      child: Text(
                        topic,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // --- 4. IMAGE PICKER ROW ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Camera Button
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.camera),
                      child: _buildImageActionBox(
                        Icons.camera_alt,
                        Colors.grey[400]!,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Selected Images
                    ..._selectedImages.asMap().entries.map((entry) {
                      int index = entry.key;
                      File imageFile = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                imageFile,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Small delete button
                            Positioned(
                              right: -5,
                              top: -5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    // Add from Gallery Button
                    GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: _buildImageActionBox(
                        Icons.add,
                        brownColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- 5. ANONYMOUS TOGGLE ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Post as Anonymous?",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      activeColor: brownColor,
                      onChanged: (value) {
                        setState(() {
                          _isAnonymous = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for the square Camera/Gallery buttons
  Widget _buildImageActionBox(IconData icon, Color iconColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Icon(icon, color: iconColor, size: 36)),
    );
  }
}
