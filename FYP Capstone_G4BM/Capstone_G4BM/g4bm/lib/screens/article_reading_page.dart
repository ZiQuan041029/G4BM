import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SimpleArticleReadingPage extends StatefulWidget {
  final String title;
  final String url;

  const SimpleArticleReadingPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<SimpleArticleReadingPage> createState() =>
      _SimpleArticleReadingPageState();
}

class _SimpleArticleReadingPageState extends State<SimpleArticleReadingPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBE5DE),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
