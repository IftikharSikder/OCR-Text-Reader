import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRScreen extends StatefulWidget {
  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  String recognizedText = '';
  bool isProcessing = false;
  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  Future<void> pickAndRecognizeText(ImageSource source) async {
    try {
      setState(() {
        isProcessing = true;
      });

      final XFile? imageFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (imageFile == null) {
        setState(() {
          isProcessing = false;
        });
        return;
      }

      setState(() {
        selectedImage = File(imageFile.path);
      });

      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText result = await textRecognizer.processImage(
        inputImage,
      );

      String processedText = _processRecognizedText(result);

      await textRecognizer.close();

      setState(() {
        recognizedText = processedText;
        isProcessing = false;
      });

      if (processedText.isEmpty) {
        _showSnackBar(
          'No text found in the image. Please try again with better lighting and focus.',
        );
      } else {
        _showSnackBar('Text extracted successfully!');
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      _showSnackBar('Error processing image: ${e.toString()}');
    }
  }

  String _processRecognizedText(RecognizedText recognizedText) {
    StringBuffer processedText = StringBuffer();

    for (TextBlock block in recognizedText.blocks) {
      if (block.cornerPoints.length >= 4) {
        StringBuffer blockText = StringBuffer();

        for (TextLine line in block.lines) {
          String lineText = line.text.trim();

          if (lineText.length > 1) {
            lineText = _cleanOCRText(lineText);
            blockText.writeln(lineText);
          }
        }

        if (blockText.isNotEmpty) {
          processedText.write(blockText.toString());
          processedText.writeln();
        }
      }
    }

    return processedText.toString().trim();
  }

  String _cleanOCRText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[|]'), 'I')
        .replaceAll(RegExp(r'[0](?=[A-Za-z])'), 'O')
        .replaceAll(RegExp(r'(?<=[A-Za-z])[0]'), 'O')
        .replaceAll(RegExp(r'\b1(?=[A-Za-z])'), 'l')
        .trim();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'For best results: Use good lighting, ensure text is clear and focused',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        pickAndRecognizeText(ImageSource.camera);
                      },
                    ),
                    _buildSourceOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        pickAndRecognizeText(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue.shade600),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearResults() {
    setState(() {
      recognizedText = '';
      selectedImage = null;
    });
  }

  void _copyToClipboard() {
    if (recognizedText.isNotEmpty) {
      _showSnackBar('Text copied to clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Text Recognition',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          if (recognizedText.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: _clearResults,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.document_scanner, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Scan & Extract Text',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Capture prescriptions and medical documents',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : _showImageSourceDialog,
                      icon:
                          isProcessing
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Icon(Icons.camera_alt, size: 24),
                      label: Text(
                        isProcessing ? 'Processing...' : 'Capture Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  if (selectedImage != null) ...[
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extracted Text',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (recognizedText.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.copy, color: Colors.blue.shade600),
                          onPressed: _copyToClipboard,
                          tooltip: 'Copy text',
                        ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child:
                          recognizedText.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.text_fields,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No text extracted yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Capture a document to extract text',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SingleChildScrollView(
                                child: SelectableText(
                                  recognizedText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
