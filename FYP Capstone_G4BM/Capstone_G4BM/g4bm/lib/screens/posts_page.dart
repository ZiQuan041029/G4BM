import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:g4bm/main.dart';
import 'package:provider/provider.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  String _selectedTab = "My Post";

  @override
  void initState() {
    super.initState();
    // Fetch fresh data from MongoDB when the page opens
    Future.microtask(() {
      context.read<MyAppState>().loadMyPosts();
      context.read<MyAppState>().loadLikedPosts();
    });
  }

  void _confirmDeletePost(String? postId) {
    if (postId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF9F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Post?"),
        content: const Text(
          "This action cannot be undone and will remove it from the community feed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<MyAppState>().deletePost(postId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Post deleted successfully.")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creamBg = const Color(0xFFEBE5DE);
    final brownColor = const Color(0xFF5D4037);
    var appState = context.watch<MyAppState>();

    // Use the real lists from your appState
    List<Map<String, dynamic>> displayList = _selectedTab == "My Post"
        ? appState.myPosts
        : appState.likedPosts;

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Posts",
          style: GoogleFonts.darumadropOne(color: Colors.black, fontSize: 28),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. TAB TOGGLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildTabButton("My Post", left: true),
                _buildTabButton("Liked", left: false),
              ],
            ),
          ),

          // 2. LIST VIEW
          Expanded(
            child: displayList.isEmpty
                ? Center(child: Text("No posts found in this category."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(displayList[index], appState);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, MyAppState appState) {
    List likesArray = post['likes'] ?? [];
    bool isLiked = likesArray.contains(appState.currentUserId);
    int likesCount = likesArray.length;
    // Handle comment count dynamically
    int commentsCount = post['comments'] is List
        ? (post['comments'] as List).length
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- A. HEADER (Profile, Name, Trash) ---
          ListTile(
            leading: CircleAvatar(
              backgroundImage: appState.getProfileImage(post['userImage']),
            ),
            title: Text(
              post['userName'] ?? "User",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              appState.getTimeAgo(post['createdAt']),
            ), // Uses helper from main
            trailing: _selectedTab == "My Post"
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmDeletePost(post['_id']),
                  )
                : null,
          ),

          // --- B. IMAGES AREA (Real Data) ---
          if (post['images'] != null && (post['images'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: (post['images'] as List).length > 2
                      ? 2
                      : (post['images'] as List).length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      post['images'][index],
                      fit: BoxFit.cover,
                      // Error handling if a URL is broken
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // --- C. CONTENT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(post['content'] ?? ""),
          ),

          const Divider(height: 1),

          // --- D. INTERACTION BAR (Like & Comment) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Like Button
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey[700],
                      ),
                      onPressed: () => appState.toggleLike(post['_id']),
                    ),
                    Text("$likesCount"),
                  ],
                ),

                // THE MISSING COMMENT BUTTON
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey[700],
                      ),
                      onPressed: () => _showCommentsPopup(context, post),
                    ),
                    Text("$commentsCount"),
                  ],
                ),

                IconButton(
                  icon: Icon(Icons.ios_share, color: Colors.grey[700]),
                  onPressed: () => Share.share(post['content'] ?? ""),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A. The Tab Button Helper
  Widget _buildTabButton(String label, {required bool left}) {
    final bool isSelected = _selectedTab == label;
    final brownColor = const Color(0xFF5D4037);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? brownColor : Colors.grey[300],
            borderRadius: left
                ? const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // B. The Comment Item Helper
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
            radius: 18,
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
                        text: "$user ",
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

  // C. The Local Time Ago Helper (points to the Global one in main.dart)
  String _getTimeAgo(String? isoString) {
    return Provider.of<MyAppState>(
      context,
      listen: false,
    ).getTimeAgo(isoString);
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

                            // 1. Local UI Update
                            setModalState(() {
                              post['comments'] =
                                  (post['comments'] as List?) ?? [];
                              (post['comments'] as List).add({
                                'userName': appState.userProfile['name'],
                                'userImage':
                                    appState.userProfile['profileImage'],
                                'text': text,
                                'createdAt': DateTime.now().toIso8601String(),
                              });
                            });

                            setState(() {});
                            commentController.clear();

                            // 2. Database Sync
                            if (postId != null) {
                              bool success = await appState.addCommentToPost(
                                postId,
                                text,
                              );
                              if (success) {
                                // Here we refresh MY posts or LIKED posts specifically
                                await appState.loadMyPosts();
                                await appState.loadLikedPosts();
                              }
                            }
                            appState.markTaskComplete(
                              'hasInteractedWithCommunity',
                            );
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
}
