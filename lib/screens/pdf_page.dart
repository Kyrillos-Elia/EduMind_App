import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';
import 'package:ai_study_app/services/gemini_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ai_study_app/screens/ai_chat.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:ai_study_app/services/user_servise.dart';
import 'package:ai_study_app/services/stats_service.dart';
import '../localization_helper.dart';

class PdfPage extends StatefulWidget {
  const PdfPage({super.key});

  @override
  State<PdfPage> createState() => _PdfPageState();
}

class _PdfPageState extends State<PdfPage> with TickerProviderStateMixin {
  final Random random = Random();

  bool _isLoading = false;
  String _loadingMessage = '';
  String? _pdfName;
  String? _pdfSize;
  String? _summary;
  List<QuizQuestion>? _quiz;
  bool _showQuiz = false;
  Uint8List? _pdfBytes;
  String? _extractedText;

  late final AnimationController _orbController;
  late final AnimationController _pulseController;
  late final Animation<double> _orbAnimationY;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _orbAnimationY = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _orbController, curve: Curves.easeInOut),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _resetState() {
    setState(() {
      _summary = null;
      _quiz = null;
      _showQuiz = false;
      _pdfBytes = null;
      _extractedText = null;
    });
  }

  Future<void> _handleUpload() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = CustomLocalizations.of(context).get('uploadingFile');
      _summary = null;
      _quiz = null;
      _pdfName = null;
      _showQuiz = false;
      _pdfBytes = null;
      _extractedText = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
  withData: true,
);

if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _pdfName = result.files.first.name;
        _pdfSize =
            "${(result.files.first.size / 1024).toStringAsFixed(1)} KB";
        _pdfBytes = result.files.first.bytes;
        _loadingMessage =
            CustomLocalizations.of(context).get('generatingSummary');
      });
      final pdfDoc = PdfDocument(inputBytes: _pdfBytes!);
      final extractor = PdfTextExtractor(pdfDoc);
      _extractedText = extractor.extractText();
      pdfDoc.dispose();

      await StatsService.incrementPdfCount();
      setState(() => _isLoading = false);

      final prompt = """
      Summarize this document clearly and simply:

      $_extractedText
      """;

      final summary = await GeminiService.sendMessage(prompt);

      setState(() {
        _summary = summary;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${CustomLocalizations.of(context).get('errorOccurred')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGenerateQuiz() async {
  if (_extractedText == null) return;

  try {
    final prompt = """
      Generate 5 MCQ questions from this text.

      Return JSON ONLY like:
      [
      { "question": "...", "options": ["a","b","c","d"], "answer": "a" }
      ]

      TEXT:
      $_extractedText
      """;

          final result = await GeminiService.sendMessage(prompt);

          final cleaned = result
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();

          setState(() {
            _quiz = (jsonDecode(cleaned) as List)
                .map((e) => QuizQuestion.fromJson(e))
                .toList();
            _showQuiz = true;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
}
  Widget _floatingParticles(Color particleColor) {
    return Stack(
      children: List.generate(
        20,
        (i) => Positioned(
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          top: random.nextDouble() * MediaQuery.of(context).size.height,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: particleColor.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bgBottom,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.bgTop, palette.bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _floatingParticles(palette.primarySoft),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: palette.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.border),
                            boxShadow: [
                              BoxShadow(
                                color: palette.primary.withOpacity(0.18),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_ios_new,
                              color: palette.textPrimary, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CustomLocalizations.of(context).get('aiSummarizerTitle'),
                              style: TextStyle(
                                  color: palette.textPrimary, fontSize: 22),
                            ),
                            Text(
                              CustomLocalizations.of(context).get('uploadPdfSubtitle'),
                              style: TextStyle(color: palette.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? _buildLoading()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _summary == null
                                ? _uploadScreen(palette)
                                : _showQuiz && _quiz != null
                                    ? _QuizView(
                                        questions: _quiz!,
                                        palette: palette,
                                        onQuizCompleted: (score, total) async {
                                          await UserService.incrementQuizCount();
                                          await StatsService.saveQuizResult(score, total);
                                        },
                                        onUploadNew: _resetState,
                                      )
                                    : _summaryScreen(palette),
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

  Widget _buildLoading() {
    final palette = AppPalette.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: palette.primary),
          const SizedBox(height: 20),
          Text(_loadingMessage,
              style: TextStyle(color: palette.textPrimary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _uploadScreen(AppPalette palette) {
    return GestureDetector(
      key: const ValueKey('upload'),
      onTap: _handleUpload,
      child: Container(
        width: double.infinity,
        height: 350,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: palette.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(0.12),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _orbAnimationY,
              builder: (_, _) => Transform.translate(
                offset: Offset(0, _orbAnimationY.value),
                child: Icon(Icons.file_present, color: palette.primary, size: 60),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              CustomLocalizations.of(context).get('clickToUploadPdf'),
              style: TextStyle(color: palette.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              CustomLocalizations.of(context).get('maxFileSizeLabel'),
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryScreen(AppPalette palette) {
    return SingleChildScrollView(
      key: const ValueKey('summary'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File card
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pdfName ?? CustomLocalizations.of(context).get('pdfFile'),
                          style: TextStyle(color: palette.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(_pdfSize ?? '',
                            style: TextStyle(color: palette.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          CustomLocalizations.of(context).get('uploadedSuccessfully'),
                          style: TextStyle(
                              color: Colors.green.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CustomLocalizations.of(context).get('summaryTitle'),
                    style: TextStyle(color: palette.primary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _summary!,
                    style: TextStyle(
                        color: palette.textSecondary, fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 20),

                  // Ask AI button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(pdfContext: _summary),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.primary.withOpacity(0.85),
                            palette.primary.withOpacity(0.5),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: palette.primary.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: palette.primary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Ask AI about this',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.white, size: 13),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Upload new
                  ElevatedButton(
                    onPressed: _resetState,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.surface,
                      foregroundColor: palette.textPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: palette.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      CustomLocalizations.of(context).get('uploadNew'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Generate quiz
                  ElevatedButton(
                    onPressed: _handleGenerateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      CustomLocalizations.of(context).get('generateQuiz'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Quiz Question Model
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
// Quiz View
// ─────────────────────────────────────────────
class _QuizView extends StatefulWidget {
  final List<QuizQuestion> questions;
  final AppPalette palette;
  final VoidCallback onUploadNew;
  final Future<void> Function(int score, int total)? onQuizCompleted;

  const _QuizView({
    required this.questions,
    required this.palette,
    this.onQuizCompleted,
    required this.onUploadNew,
  });

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  final Map<int, int> _answers = {};
  bool _submitted = false;
  bool _hasRecordedCompletion = false;

  int get _score => _answers.entries
      .where((e) => e.value == widget.questions[e.key].correctIndex)
      .length;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CustomLocalizations.of(context).get('quizSectionTitle'),
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${q.question}',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...q.options.asMap().entries.map((opt) {
                      final isSelected = _answers[i] == opt.key;
                      final isCorrect = opt.key == q.correctIndex;

                      Color borderColor = palette.border;
                      Color bgColor = Colors.transparent;

                      if (_submitted) {
                        if (isCorrect) {
                          borderColor = Colors.green;
                          bgColor = Colors.green.withOpacity(0.15);
                        } else if (isSelected) {
                          borderColor = Colors.red;
                          bgColor = Colors.red.withOpacity(0.15);
                        }
                      } else if (isSelected) {
                        borderColor = palette.primary;
                        bgColor = palette.primary.withOpacity(0.12);
                      }

                      return GestureDetector(
                        onTap: _submitted
                            ? null
                            : () => setState(() => _answers[i] = opt.key),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(opt.value,
                                    style: TextStyle(
                                        color: palette.textPrimary)),
                              ),
                              if (_submitted && isCorrect)
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 18),
                              if (_submitted && isSelected && !isCorrect)
                                const Icon(Icons.cancel,
                                    color: Colors.red, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            if (!_submitted)
              ElevatedButton(
                onPressed: _answers.length == widget.questions.length
                    ? () async {
                        setState(() => _submitted = true);
                        if (!_hasRecordedCompletion) {
                          _hasRecordedCompletion = true;
                          await widget.onQuizCompleted?.call(
                              _score, widget.questions.length);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: palette.border,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  CustomLocalizations.of(context).get('submitAnswers'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            if (_submitted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  '${CustomLocalizations.of(context).get('yourScore')}: $_score / ${widget.questions.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: widget.onUploadNew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  CustomLocalizations.of(context).get('uploadNew'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
