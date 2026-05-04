import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

part 'ocr_event.dart';
part 'ocr_state.dart';

class OcrBloc extends Bloc<OcrEvent, OcrState> {
  final ImagePicker _picker = ImagePicker();

  OcrBloc() : super(OcrInitial()) {
    on<PickImageEvent>(_onPickImage);
    on<ClearOcrEvent>(_onClear);
  }

  Future<void> _onPickImage(PickImageEvent event, Emitter<OcrState> emit) async {
    emit(OcrLoading());

    try {
      final XFile? imageFile = await _picker.pickImage(
        source: event.source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (imageFile == null) {
        emit(OcrInitial());
        return;
      }

      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText result = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final String processedText = _processRecognizedText(result);

      if (processedText.isEmpty) {
        emit(OcrEmpty(imagePath: imageFile.path));
      } else {
        emit(OcrSuccess(text: processedText, imagePath: imageFile.path));
      }
    } catch (e) {
      emit(OcrFailure('Error processing image: ${e.toString()}'));
    }
  }

  void _onClear(ClearOcrEvent event, Emitter<OcrState> emit) {
    emit(OcrInitial());
  }

  String _processRecognizedText(RecognizedText recognizedText) {
    final StringBuffer processedText = StringBuffer();

    for (final TextBlock block in recognizedText.blocks) {
      if (block.cornerPoints.length >= 4) {
        final StringBuffer blockText = StringBuffer();

        for (final TextLine line in block.lines) {
          final String lineText = _cleanOCRText(line.text.trim());
          if (lineText.length > 1) {
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
}
