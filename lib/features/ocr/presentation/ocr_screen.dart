import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/ocr_bloc.dart';

class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _ImageSourceSheet(
        onCameraTap: () {
          Navigator.pop(sheetContext);
          context.read<OcrBloc>().add(PickImageEvent(ImageSource.camera));
        },
        onGalleryTap: () {
          Navigator.pop(sheetContext);
          context.read<OcrBloc>().add(PickImageEvent(ImageSource.gallery));
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.green.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(context, 'Text copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OcrBloc(),
      child: BlocConsumer<OcrBloc, OcrState>(
        listener: (context, state) {
          if (state is OcrSuccess) {
            _showSnackBar(context, 'Text extracted successfully!');
          } else if (state is OcrEmpty) {
            _showSnackBar(context, 'No text found. Try better lighting and focus.', isError: true);
          } else if (state is OcrFailure) {
            _showSnackBar(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          final bool isProcessing = state is OcrLoading;
          final bool hasResult = state is OcrSuccess;

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              title: const Text(
                'Scan Text',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: Colors.blue.shade600,
              elevation: 0,
              actions: [
                if (hasResult)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () => context.read<OcrBloc>().add(ClearOcrEvent()),
                  ),
              ],
            ),
            body: Column(
              children: [
                _Header(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CaptureButton(
                          isProcessing: isProcessing,
                          onPressed: () => _showImageSourceDialog(context),
                        ),
                        const SizedBox(height: 24),
                        if (state is OcrSuccess || state is OcrEmpty) ...[
                          _ImagePreview(
                            imagePath: state is OcrSuccess
                                ? state.imagePath
                                : (state as OcrEmpty).imagePath,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _ExtractedTextHeader(
                          hasText: hasResult,
                          onCopy: hasResult ? () => _copyToClipboard(context, (state).text) : null,
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _ExtractedTextBody(state: state)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.document_scanner, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Scan & Extract Text',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture prescriptions and medical documents',
            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;

  const _CaptureButton({required this.isProcessing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : onPressed,
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.camera_alt, size: 24),
        label: Text(
          isProcessing ? 'Processing...' : 'Capture Document',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imagePath;

  const _ImagePreview({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(imagePath), fit: BoxFit.cover),
      ),
    );
  }
}

class _ExtractedTextHeader extends StatelessWidget {
  final bool hasText;
  final VoidCallback? onCopy;

  const _ExtractedTextHeader({required this.hasText, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Extracted Text',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
        ),
        if (hasText)
          IconButton(
            icon: Icon(Icons.copy, color: Colors.blue.shade600),
            onPressed: onCopy,
            tooltip: 'Copy text',
          ),
      ],
    );
  }
}

class _ExtractedTextBody extends StatelessWidget {
  final OcrState state;

  const _ExtractedTextBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: state is OcrSuccess
          ? SingleChildScrollView(
              child: SelectableText(
                (state as OcrSuccess).text,
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey[800]),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.text_fields, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No text extracted yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture a document to extract text',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const _ImageSourceSheet({required this.onCameraTap, required this.onGalleryTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 20),
          const Text(
            'Select Image Source',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'For best results: Use good lighting, ensure text is clear and focused',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SourceOption(icon: Icons.camera_alt, label: 'Camera', onTap: onCameraTap),
              _SourceOption(icon: Icons.photo_library, label: 'Gallery', onTap: onGalleryTap),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue.shade600),
            const SizedBox(height: 8),
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
}
