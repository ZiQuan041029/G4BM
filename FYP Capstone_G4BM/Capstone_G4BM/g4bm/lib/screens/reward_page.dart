import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:g4bm/main.dart'; // Make sure this path points to your main.dart!
import 'point_history_page.dart';

class RewardPage extends StatefulWidget {
  const RewardPage({super.key});

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  final Color creamBg = const Color(0xFFEBE5DE);
  final Color brownColor = const Color(0xFF5D4037);

  String _selectedCategory = "All";
  final List<String> _categories = [
    "All",
    "Maternity",
    "Voucher",
    "Groceries",
    "Limited Merch",
  ];

  // Mock Product Data
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'RM3 OFF Shopee Voucher',
      'company': 'Shopee',
      'points': 300,
      'category': 'Voucher',
      'color': Colors.red,
    },
    {
      'name': 'RM5 OFF Shopee Voucher',
      'company': 'Shopee',
      'points': 500,
      'category': 'Voucher',
      'color': Colors.deepOrange,
    },
    {
      'name': 'RM10 GrabFood Voucher',
      'company': 'Grab',
      'points': 1000,
      'category': 'Voucher',
      'color': Colors.green,
    },
    {
      'name': 'Libresse Maternity Pads',
      'company': 'Libresse',
      'points': 500,
      'category': 'Maternity',
      'color': Colors.purple[200],
    },
    {
      'name': 'Philips AVENT Baby Bottle',
      'company': 'Philips AVENT',
      'points': 5000,
      'category': 'Maternity',
      'color': Colors.blue[100],
    },
    {
      'name': 'Silicone Breast Pump',
      'company': 'Haakaa',
      'points': 2500,
      'category': 'Maternity',
      'color': Colors.pink[100],
    },
    {
      'name': 'RM3 Jaya Grocer Voucher',
      'company': 'Jaya Grocer',
      'points': 300,
      'category': 'Groceries',
      'color': Colors.green[200],
    },
    {
      'name': 'RM5 Jaya Grocer Voucher',
      'company': 'Jaya Grocer',
      'points': 500,
      'category': 'Groceries',
      'color': Colors.orange[300],
    },
    {
      'name': 'G4BM Exclusive Totebag',
      'company': 'G4BM',
      'points': 1000,
      'category': 'Limited Merch',
      'color': Colors.brown[300],
    },
    {
      'name': 'G4BM Baby Onesie',
      'company': 'G4BM',
      'points': 1500,
      'category': 'Limited Merch',
      'color': Colors.yellow[600],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // ---> GRAB LIVE DATA FROM APP STATE <---
    var appState = context.watch<MyAppState>();
    int currentPoints = appState.bzPoints;
    int expiringPoints = appState.getPointsExpiringThisYear();
    String currentYear = DateTime.now().year.toString();

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
          "Reward",
          style: GoogleFonts.darumadropOne(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. BZ POINTS CARD (NOW LIVE!)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 10.0,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PointHistoryPage(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4F0),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Image.asset('assets/BZCoin.png', width: 80, height: 80),
                    const SizedBox(width: 1),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "BZ Point",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: brownColor,
                            ),
                          ),
                          Text(
                            "$currentPoints", // LIVE POINTS HERE!
                            style: GoogleFonts.darumadropOne(
                              fontSize: 40,
                              color: brownColor,
                            ),
                          ),
                          Text(
                            "$expiringPoints points expiring on 31 Dec $currentYear",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: brownColor, size: 24),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. CATEGORY SELECTOR
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                String category = _categories[index];
                bool isSelected = _selectedCategory == category;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? brownColor : Colors.grey[400],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // 3. PRODUCT LIST AREA
          Expanded(child: _buildProductContent(appState)),
        ],
      ),
    );
  }

  Widget _buildProductContent(MyAppState appState) {
    if (_selectedCategory == "All") {
      return ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: _categories.where((c) => c != "All").map((category) {
          return _buildCategoryRow(category, appState);
        }).toList(),
      );
    } else {
      return ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [_buildCategoryRow(_selectedCategory, appState)],
      );
    }
  }

  Widget _buildCategoryRow(String category, MyAppState appState) {
    List<Map<String, dynamic>> categoryProducts = _products
        .where((p) => p['category'] == category)
        .toList();

    if (categoryProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categoryProducts.length,
            itemBuilder: (context, index) {
              final product = categoryProducts[index];
              return _buildProductCard(product, appState);
            },
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, MyAppState appState) {
    return GestureDetector(
      onTap: () =>
          _showRedeemConfirmation(product, appState), // Trigger the flow!
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: product['color'],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, color: Colors.white, size: 40),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      product['company'],
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    Text(
                      "${product['points']} BZpoints",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brownColor,
                        fontSize: 13,
                      ),
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

  // ==========================================
  // DIALOG FLOW LOGIC
  // ==========================================

  void _showRedeemConfirmation(
    Map<String, dynamic> product,
    MyAppState appState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Redeem This?",
            style: GoogleFonts.darumadropOne(fontSize: 24, color: brownColor),
            textAlign: TextAlign.center,
          ),
          content: Text(
            product['name'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close confirmation
                _processRedemption(product, appState); // Check points
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brownColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _processRedemption(Map<String, dynamic> product, MyAppState appState) {
    int cost = product['points'];

    if (appState.bzPoints >= cost) {
      // 1. Deduct points
      appState.spendPoints(cost);

      // 2. Show Success
      _showSuccessDialog();
    } else {
      // 3. Show Failure
      _showInsufficientPointsDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 15),
              Text(
                "Redeem Successful!",
                style: GoogleFonts.darumadropOne(
                  fontSize: 22,
                  color: brownColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Check your email for the voucher link or discount code.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brownColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Awesome!",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInsufficientPointsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel, color: Colors.redAccent, size: 60),
              const SizedBox(height: 15),
              Text(
                "Insufficient BZ Points",
                style: GoogleFonts.darumadropOne(
                  fontSize: 22,
                  color: brownColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Complete more tasks to earn more points.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
