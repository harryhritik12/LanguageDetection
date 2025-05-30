import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class CameraTextExtractorScreen extends StatefulWidget {
  const CameraTextExtractorScreen({Key? key}) : super(key: key);

  @override
  State<CameraTextExtractorScreen> createState() => _CameraTextExtractorScreenState();
}

class _CameraTextExtractorScreenState extends State<CameraTextExtractorScreen> {
  File? _imageFile;
  String _extractedText = '';
  bool _isProcessing = false;
  bool _hasError = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        await _processImage(File(pickedFile.path));
      } else {
        // User canceled the camera
        Navigator.maybePop(context);
      }
    } catch (e) {
      _handleError('Failed to capture image: ${e.toString()}');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _imageFile = imageFile;
      _isProcessing = true;
      _extractedText = '';
      _hasError = false;
    });

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _extractedText = recognizedText.text;
        _isProcessing = false;
      });
    } catch (e) {
      _handleError('Failed to process text: ${e.toString()}');
    }
  }

  void _handleError(String errorMessage) {
    setState(() {
      _isProcessing = false;
      _hasError = true;
      _extractedText = errorMessage;
    });
  }

  void _retryCapture() {
    _pickImage();
  }

  void _submitText() {
    if (_extractedText.trim().isNotEmpty && !_hasError) {
      Navigator.pop(context, _extractedText.trim());
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extract Text from Image"),
        backgroundColor: Colors.indigo.shade700,
        actions: [
          if (_imageFile != null && !_isProcessing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retryCapture,
              tooltip: 'Retry',
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _imageFile != null && !_isProcessing && !_hasError
          ? FloatingActionButton.extended(
              onPressed: _submitText,
              icon: const Icon(Icons.check),
              label: const Text("Use Text"),
              backgroundColor: Colors.indigo,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 16),
            Text('Processing image...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_imageFile != null) ...[
            _buildImagePreview(),
            const SizedBox(height: 24),
          ],
          _buildTextResults(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 3/4,
          child: Stack(
            children: [
              Image.file(_imageFile!, fit: BoxFit.cover),
              if (_hasError)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextResults() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, size: 20, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  "Extracted Text",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_extractedText.isEmpty && !_hasError)
              const Text(
                "No text was recognized in the image.",
                style: TextStyle(color: Colors.grey),
              )
            else
              SelectableText(
                _extractedText,
                style: TextStyle(
                  color: _hasError ? Colors.red : Colors.black87,
                  fontSize: 14,
                ),
              ),
            if (_hasError) ...[
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _retryCapture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}