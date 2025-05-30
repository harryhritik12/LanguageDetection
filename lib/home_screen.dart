import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:country_flags/country_flags.dart' as cf;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'camera_text_extractor_screen.dart'; // Import your camera screen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  String _detectedLanguage = '';
  String _countryCode = '';
  bool _isLoading = false;

  final supportedLanguages = {
    'English': 'GB',
    'German': 'DE',
    'French': 'FR',
    'Spanish': 'ES',
    'Bulgarian': 'BG',
    'Danish': 'DK',
    'Finnish': 'FI',
    'Hungarian': 'HU',
    'Latvian': 'LV',
    'Polish': 'PL',
    'Portuguese': 'PT',
    'Romanian': 'RO',
    'Slovenian': 'SI',
  };

  Future<void> _detectLanguage(String text) async {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least 3 words for accurate detection'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _detectedLanguage = '';
      _countryCode = '';
    });

    try {
      final apiUrl = '${dotenv.env['API_BASE_URL']}/detect';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final detected = data['language'] ?? 'Unknown';

        setState(() {
          _detectedLanguage = detected;
          _countryCode = supportedLanguages[detected] ?? '';
        });
      } else {
        throw Exception('Failed to detect language');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSupportedLanguages() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: supportedLanguages.entries.map((entry) {
        return Chip(
          avatar: cf.CountryFlag.fromCountryCode(
            entry.value,
            height: 18,
            width: 22,
          ),
          label: Text(
            entry.key,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 1,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Language Detector',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.indigo.shade700,
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              shadowColor: Colors.indigo.shade100,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "Enter Text to Detect Language",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Please enter at least 3 words for accurate detection",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.indigo.shade400),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _detectLanguage(_textController.text),
                      icon: Icon(Icons.translate, size: 22),
                      label: Text(
                        "Detect Language",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shadowColor: Colors.indigo.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            if (_isLoading)
              Column(
                children: [
                  CircularProgressIndicator(
                    color: Colors.indigo.shade600,
                    strokeWidth: 2.5,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Detecting language...",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            else if (_detectedLanguage.isNotEmpty)
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Card(
                  key: ValueKey(_detectedLanguage),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.indigo.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Detected Language',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.indigo.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_countryCode.isNotEmpty)
                                cf.CountryFlag.fromCountryCode(
                                  _countryCode,
                                  height: 36,
                                  width: 44,
                                ),
                              SizedBox(width: 16),
                              Text(
                                _detectedLanguage,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: 30),
            Text(
              "Supported Languages",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "This app can detect the following languages:",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            _buildSupportedLanguages(),
            SizedBox(height: 20),
            Divider(color: Colors.grey.shade300, height: 1),
            SizedBox(height: 20),
            Text(
              "Tip: Try entering text in different languages to see how accurate the detection is!",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final extractedText = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CameraTextExtractorScreen(),
            ),
          );

          if (extractedText != null &&
              extractedText is String &&
              extractedText.trim().isNotEmpty) {
            _textController.text = extractedText.trim();
            _detectLanguage(extractedText.trim());
          }
        },
        icon: Icon(Icons.camera_alt),
        label: Text("Use Camera"),
        backgroundColor: Colors.indigo.shade600,
      ),
    );
  }
}
