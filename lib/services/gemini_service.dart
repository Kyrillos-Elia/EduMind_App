import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class GeminiService {
  static final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
  );

  // ✅ Chat + Summary
  static Future<String> sendMessage(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'لم يتم الرد';
  }

  // ✅ PDF Pick
  static Future<Map<String, dynamic>?> pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return null;
    final file = File(result.files.single.path!);
    final fileSizeBytes = await file.length();
    final fileSizeMB = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final text = await _extractTextFromPdf(file);
    return {
      'fileName': result.files.single.name,
      'fileSize': '$fileSizeMB MB',
      'text': text,
    };
  }

  // ✅ PDF Extract
  static Future<String> _extractTextFromPdf(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = List<String>.from(json['options']);
    final answer = json['answer'] as String;
    final correctIndex = options.indexOf(answer);
    return QuizQuestion(
      question: json['question'],
      options: options,
      correctIndex: correctIndex == -1 ? 0 : correctIndex,
    );
  }
}