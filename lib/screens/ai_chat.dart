import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';
import 'package:ai_study_app/screens/main_navigation.dart';
import '../localization_helper.dart';
import 'package:ai_study_app/services/gemini_service.dart';

class Message {
  final String id;
  final String text;
  final bool isAI;

  Message({
    required this.id,
    required this.text,
    required this.isAI,
  });
}

class ChatPage extends StatefulWidget {
  final String? pdfContext;

  const ChatPage({super.key, this.pdfContext});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Message> messages = [];
  bool _isTyping = false;

  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final greeting = widget.pdfContext != null
        ? "Hello! I've read the document summary. Ask me anything about it!"
        : "Hello! I'm your AI study assistant. Ask me anything!";

    messages.add(Message(id: '0', text: greeting, isAI: true));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = Message(
      id: DateTime.now().toString(),
      text: text,
      isAI: false,
    );

    setState(() {
      messages.add(userMsg);
      _isTyping = true;
    });

    controller.clear();
    _scrollToBottom();

    try {
      // 🧠 Gemini Prompt
      String prompt = "You are an AI study assistant. Be helpful and clear.\n\n";

      if (widget.pdfContext != null) {
        prompt += "Document:\n${widget.pdfContext}\n\n";
      }

      prompt += "User: $text\nAI:";

      final reply = await GeminiService.sendMessage(prompt);

      setState(() {
        _isTyping = false;
        messages.add(Message(
          id: DateTime.now().toString(),
          text: reply.trim(),
          isAI: true,
        ));
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        messages.add(Message(
          id: DateTime.now().toString(),
          text: "Error: $e",
          isAI: true,
        ));
      });
    }
  }

  void goBackHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
      (route) => false,
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
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: palette.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: palette.border),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new,
                                color: palette.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                          if (widget.pdfContext != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: palette.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: palette.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf,
                                      color: palette.primary, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PDF Context',
                                    style: TextStyle(
                                      color: palette.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: palette.primary),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Study Chat',
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                widget.pdfContext != null
                                    ? 'Asking about your document'
                                    : 'Always here to help',
                                style:
                                    TextStyle(color: palette.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: LinearProgressIndicator(
                                    color: palette.primary,
                                    backgroundColor:
                                        palette.primary.withOpacity(0.2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Thinking...',
                                  style: TextStyle(
                                    color: palette.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = messages[index];

                      return Align(
                        alignment: msg.isAI
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints:
                              const BoxConstraints(maxWidth: 270),
                          decoration: BoxDecoration(
                            color: msg.isAI
                                ? palette.surface
                                : palette.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: msg.isAI
                                ? Border.all(color: palette.border)
                                : null,
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isAI
                                  ? palette.textPrimary
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Input
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          style:
                              TextStyle(color: palette.textPrimary),
                          onSubmitted: handleSendMessage,
                          decoration: InputDecoration(
                            hintText: CustomLocalizations.of(context)
                                .get('typeAMessage'),
                            hintStyle: TextStyle(
                                color: palette.textSecondary),
                            filled: true,
                            fillColor: palette.surface,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: palette.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () =>
                            handleSendMessage(controller.text),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
