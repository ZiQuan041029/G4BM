import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'article_reading_page.dart';

class ResourceLibraryPage extends StatefulWidget {
  const ResourceLibraryPage({super.key});

  @override
  State<ResourceLibraryPage> createState() => _ResourceLibraryPageState();
}

class _ResourceLibraryPageState extends State<ResourceLibraryPage> {
  // --- STATE VARIABLES ---
  String _selectedCategory = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // --- CATEGORIES ---
  final List<String> _categories = [
    "All",
    "Sleep",
    "Self-Care",
    "Family",
    "Time Management",
    "Maternity",
    "Mental",
  ];

  // --- MOCK DATA FOR ARTICLES ---
  final List<Map<String, dynamic>> _allArticles = [
    {
      "title": "Always feeling overwhelming?",
      "description":
          "An article about how to fix your brain with all these noisy thoughts. A busy, noisy mind can feel overwhelming, but you can learn to quiet the chatter and find more peace. This article explores strategies to manage...",
      "category": "Mental",
      "color": const Color(0xFFB0BEC5), // Blue Grey
      "icon": Icons.psychology,
      "link":
          "https://www.verywellmind.com/feeling-overwhelmed-symptoms-causes-and-coping-5425548",
    },
    {
      "title": "Mutual Impact of Relationship & Mental Health",
      "description":
          "Relationships are a fundamental aspect of human existence, shaping our experiences and influencing our emotional and mental well-being. Whether they are familial, platonic, romantic[1], or professional, our connections with others play a crucial role in determining our overall life satisfaction.",
      "category": "Family",
      "color": const Color(0xFFCE93D8), // Purple/Pink
      "icon": Icons.favorite,
      "link":
          "https://sweetinstitute.com/the-impact-of-relationships-on-emotional-well-being-mental-health-and-life-satisfaction/",
    },
    {
      "title": "Family-Focused Treatment for Childhood Depression",
      "description":
          "Family-Focused Treatment for Childhood Depression (FFT-CD) is an evidence-based approach that helps families develop skills to manage and recover from depression in children and adolescents...",
      "category": "Family",
      "color": const Color(0xFF90CAF9), // Light Blue
      "icon": Icons.family_restroom,
      "link":
          "https://www.nationalelfservice.net/populations-and-settings/family-carers/family-support-youth-anxiety-depression/",
    },
    {
      "title": "Child Care Is More Than Just Watching Children",
      "description":
          "It’s not just about watching children; it’s about supporting their development, nurturing their emotional well-being, and creating a safe environment where they can thrive.",
      "category": "Child-Care",
      "color": const Color(0xFF90CAF9), // Light Blue
      "icon": Icons.child_care,
      "link":
          "https://www.zocalopublicsquare.org/child-care-job-more-than-just-watching-children/",
    },
    {
      "title": "Recovery Practices to Foster Resilience & Prevent Burnout",
      "description":
          "Recovery practices could be taking a day just to be outside in nature, carving out time to reconnect with friends, or even going on a long walk or run to shed the stress of a tough day. Taking some time out for your mental health is critically important.",
      "category": "Mental",
      "color": const Color(0xFFF48FB1), // Pink
      "icon": Icons.battery_charging_full,
      "link":
          "https://www.ccl.org/articles/leading-effectively-articles/improve-performance-foster-resilience-prevent-burnout-recovery-practices/",
    },
    {
      "title": "What Makes a Good Night’s Sleep",
      "description":
          "Sleep is a time for the brain and body to engage in vital growth and repair. It’s an essential part of a healthy lifestyle, yet our demanding work schedules, family responsibilities, and busy social lives mean that many people are going short on sleep.",
      "category": "Sleep",
      "color": const Color.fromARGB(255, 134, 128, 255),
      "icon": Icons.bedtime,
      "link":
          "https://www.sleepfoundation.org/how-sleep-works/what-makes-good-night-sleep",
    },
    {
      "title": "Sleep and Mental Health",
      "description":
          "Getting enough sleep is crucial for your mental health. Among other benefits, it can help with your mood, your memory and your ability to manage stress. Equally, poor sleep can have a negative impact. This page provides practical tips to improve sleep such as managing caffeine intake, exercise, and maintaining a healthy sleep environment.",
      "category": "Sleep",
      "color": const Color(0xFFFFCC80), // Orange
      "icon": Icons.bed,
      "link":
          "https://www.beyondblue.org.au/mental-health/wellbeing/sleep#benefits-of-sleep",
    },
    {
      "title": "Pregnancy and Mental Health",
      "description":
          "Being pregnant is a big life event and it is natural to feel a lot of different emotions. But if you’re feeling sad and it’s starting to affect your life, there are things you can try that may help.",
      "category": "Maternity",
      "color": const Color(0xFFFFCC80), // Orange
      "icon": Icons.pregnant_woman,
      "link":
          "https://www.nhs.uk/pregnancy/mental-health-in-pregnancy-and-after-the-birth/mental-health/",
    },
    {
      "title": "Postpartum Self-Care: How Physical, Emotional Changes",
      "description":
          "After childbirth, it is time for a mother to start a new journey with her baby. During the first weeks, things may seem overwhelming. It is the time to adjust to another phase of life and to recover from delivery.",
      "category": "Maternity",
      "color": const Color(0xFF69C670),
      "icon": Icons.child_friendly,
      "link":
          "https://www.medparkhospital.com/en-US/lifestyles/postpartum-self-care",
    },
    {
      "title": "The Mental Health Benefits of Better Time Management",
      "description":
          "Time management sounds so adult. But the reality is that in today’s society, being busy can be seen as a badge of honor, and too many of us place value on cramming “just one more thing” into our already jam-packed schedules.",
      "category": "Time Management",
      "color": const Color.fromARGB(255, 247, 164, 151), // Pink
      "icon": Icons.lock_clock,
      "link": "https://deconstructingstigma.org/guides/time-management",
    },
    {
      "title": "Self-Care Resource Guide",
      "description":
          "Self-care can play a significant role in maintaining your mental health and help support your treatment and recovery if you have a mental illness. This article explains self-care strategies and provides tools for managing stress, improving wellbeing, and seeking mental health support when needed.",
      "category": "Self-Care",
      "color": const Color.fromARGB(255, 152, 215, 239), // Pink
      "icon": Icons.present_to_all,
      "link": "https://activeminds.org/resource/self-care/",
    },
    {
      "title": "Meditation Basics",
      "description":
          "Meditation is something anyone can do, anytime, anywhere - even someplace loud. It's easy to learn and involves some pretty basic techniques. Like anything new, the more you meditate, the more comfortable you'll get spending time with your mind.",
      "category": "Self-Care",
      "color": const Color.fromARGB(255, 143, 219, 197),
      "icon": Icons.self_improvement,
      "link": "https://www.headspace.com/meditation/meditation-for-beginners",
    },
    {
      "title": "Game-Changing Time Management Tips for Busy Working Moms",
      "description":
          "These time management tips are going to be a game-changer for you or any mom out working or running her own business. I view these habits as the four cornerstones that really allow me to stay productive with the very limited time that I have to work. They also prevent me from trying to do 20 different things all at the same time (which I’m sure you know all about!). ",
      "category": "Time Management",
      "color": const Color.fromARGB(255, 228, 145, 229),
      "icon": Icons.share_arrival_time,
      "link":
          "https://www.megansumrell.com/blog/Time-Management-Tips-for-Busy-Working-Moms",
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brownColor = const Color(0xFF5D4037);
    final creamBg = const Color(0xFFEBE5DE); // Matches your mockup background

    // --- FILTER LOGIC (Combines Category & Search) ---
    List<Map<String, dynamic>> filteredArticles = _allArticles.where((article) {
      // 1. Check Category
      bool matchesCategory =
          _selectedCategory == "All" ||
          article["category"] == _selectedCategory;

      // 2. Check Search Query (Case-insensitive)
      bool matchesSearch = article["title"].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      return matchesCategory && matchesSearch;
    }).toList();

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
          "Articles & Blogs",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  // Updates the list every time the user types a letter!
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // --- 2. CATEGORY PILLS ---
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? brownColor : Colors.grey[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 15),

          // --- 3. ARTICLES LIST ---
          Expanded(
            child: filteredArticles.isEmpty
                ? Center(
                    child: Text(
                      "No articles found.",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: filteredArticles.length,
                    itemBuilder: (context, index) {
                      final item = filteredArticles[index];
                      return _buildArticleCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- INDIVIDUAL ARTICLE CARD ---
  Widget _buildArticleCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleArticleReadingPage(
              title: item['title'],
              url: item['link'],
            ),
          ),
        );
      },
      child: Container(
        height: 140, // Fixed height to match mockup proportions
        margin: const EdgeInsets.only(bottom: 20),
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
        child: Row(
          children: [
            // Left Side: Colored Image/Icon Block
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: item['color'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Icon(
                  item['icon'],
                  size: 60,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),

            // Right Side: Text & Arrow
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 10, 15),
                child: Row(
                  children: [
                    // Text Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              item['description'],
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize:
                                    8, // Very small text matching the mockup
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // The Arrow Icon
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
