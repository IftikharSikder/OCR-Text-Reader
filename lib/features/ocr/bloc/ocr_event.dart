part of 'ocr_bloc.dart';

abstract class OcrEvent {}

class PickImageEvent extends OcrEvent {
  final ImageSource source;
  PickImageEvent(this.source);
}

class ClearOcrEvent extends OcrEvent {}
