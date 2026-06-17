import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../services/assistant_service.dart';
import '../controllers/theme_controller.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AssistantScreen extends StatefulWidget {
  AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late final List<Message> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      Message(
        text: 'toni_welcome_msg'.tr,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AssistantService _assistantService = AssistantService();
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _assistantService.askToni(text);
      setState(() {
        _messages.add(Message(text: response, isUser: false, timestamp: DateTime.now()));
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(
          text: 'toni_error_msg'.tr,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final _ = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textHeader),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'assistant_toni'.tr,
                      style: TextStyle(color: AppColors.textHeader, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'academic_engineer_eetac'.tr,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingBubble();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
   });
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accent : AppColors.containerBg,
          border: isUser ? null : Border.all(color: AppColors.border.withOpacity(0.5)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormattedText(message.text, isUser),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isUser ? Colors.white60 : AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.containerBg,
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'toni_thinking'.tr,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.containerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _inputController,
                style: TextStyle(color: AppColors.textHeader, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ask_toni_hint'.tr,
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          SizedBox(width: 12),
          InkWell(
            onTap: _handleSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    // Limpiar títulos de tipo "### Título"
    String cleanedText = text.replaceAll(RegExp(r'^(#{1,6})\s+', multiLine: true), '');
    
    // Parseo rápido de negrita **texto**
    final List<InlineSpan> spans = [];
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in boldPattern.allMatches(cleanedText)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: cleanedText.substring(start, match.start),
          style: TextStyle(color: isUser ? Colors.white : AppColors.textHeader, fontSize: 14),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: isUser ? Colors.white : AppColors.textHeader,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }

    if (start < cleanedText.length) {
      spans.add(TextSpan(
        text: cleanedText.substring(start),
        style: TextStyle(color: isUser ? Colors.white : AppColors.textHeader, fontSize: 14),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
