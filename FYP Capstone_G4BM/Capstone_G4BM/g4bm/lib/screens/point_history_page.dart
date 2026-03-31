import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:g4bm/main.dart'; // Ensure this points to your main.dart!

class PointHistoryPage extends StatelessWidget {
  const PointHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color creamBg = const Color(0xFFEBE5DE);
    final Color brownColor = const Color(0xFF5D4037);

    // ---> 1. GRAB THE LIVE DATA <---
    var appState = context.watch<MyAppState>();
    int currentPoints = appState.bzPoints;
    int expiringPoints = appState.getPointsExpiringThisYear();
    String currentYear = DateTime.now().year.toString();

    // ---> 2. SORT THE HISTORY (Newest First) <---
    // Read from the NEW pointHistoryLog!
    List<Map<String, dynamic>> sortedHistory = List.from(
      appState.pointHistoryLog,
    );
    sortedHistory.sort((a, b) {
      DateTime dateA = DateTime.parse(a['earnedAt']);
      DateTime dateB = DateTime.parse(b['earnedAt']);
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "BZ point History",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ---> 3. LIVE POINTS CARD <---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                  const SizedBox(width: 5),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "BZ Point",
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: brownColor,
                          ),
                        ),
                        Text(
                          "$currentPoints",
                          style: GoogleFonts.darumadropOne(
                            fontSize: 40,
                            color: brownColor,
                          ),
                        ),
                        Text(
                          "$expiringPoints points expiring on 31 Dec $currentYear",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Divider(color: Color(0xFFD7CCC8), thickness: 1.5),
            const SizedBox(height: 15),

            // ---> 4. LIVE HISTORY LIST <---
            Expanded(
              child: sortedHistory.isEmpty
                  ? Center(
                      child: Text(
                        "No point history yet.\nStart completing tasks!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      itemCount: sortedHistory.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 15),
                      itemBuilder: (context, index) {
                        final item = sortedHistory[index];

                        DateTime earnedDate = DateTime.parse(item['earnedAt']);
                        String formattedDate = DateFormat(
                          'dd-MM-yyyy HH:mm',
                        ).format(earnedDate);

                        // Handle Negative Numbers (Spending Points)
                        int amt = item['amount'];
                        String sign = amt >= 0
                            ? "+"
                            : ""; // Don't add a plus sign if it's already negative
                        Color amtColor = amt >= 0
                            ? Colors.grey
                            : Colors.redAccent;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFD7CCC8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Bonus Points',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/BZCoin.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$sign$amt", // Uses dynamic sign!
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          amtColor, // Turns red when spending!
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
