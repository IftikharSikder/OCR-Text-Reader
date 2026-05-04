part of 'ocr_bloc.dart';

abstract class OcrState {}

class OcrInitial extends OcrState {}

class OcrLoading extends OcrState {}

class OcrSuccess extends OcrState {
  final String text;
  final String imagePath;

  OcrSuccess({required this.text, required this.imagePath});
}

class OcrEmpty extends OcrState {
  final String imagePath;
  OcrEmpty({required this.imagePath});
}

class OcrFailure extends OcrState {
  final String message;
  OcrFailure(this.message);
}
