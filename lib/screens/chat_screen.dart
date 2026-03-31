import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../services/claude_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ClaudeService _claudeService = ClaudeService();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _messages.add(Message(
      text: 'नमस्कार दादा! 🙏\nमी सानप AI — तुमचा AI सोबती!\nसांगा, आज काय करायचं आहे?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('mr-IN');
    await _flutterTts.setSpeechRate(0.5);
  }

  void _startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) => setState(() => _controller.text = result.recognizedWords),
        localeId: 'mr_IN',
      );
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(Message(text: text.trim(), isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    final response = await _claudeService.sendMessage(_messages);
    setState(() {
      _messages.add(Message(text: response, isUser: false, timestamp: DateTime.now()));
      _isLoading = false;
    });
    _scrollToBottom();
    await _flutterTts.speak(response.replaceAll(RegExp(r'[^\w\s।,?.!]', unicode: true), ''));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1321),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FBE)]),
            ),
            child: const Center(child: Text('स', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('सानप AI', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('ऑनलाईन', style: GoogleFonts.poppins(color: const Color(0xFF00FF88), fontSize: 11)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            onPressed: () => setState(() {
              _messages.clear();
              _messages.add(Message(text: 'नमस्कार दादा! 🙏\nपुन्हा सुरुवात करूया!', isUser: false, timestamp: DateTime.now()));
            }),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(children: [
                    SizedBox(width: 40),
                    CircularProgressIndicator(color: Color(0xFF00D4FF), strokeWidth: 2),
                  ]),
                );
              }
              final msg = _messages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!msg.isUser) Container(
                      width: 32, height: 32, margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF7B2FBE)])),
                      child: const Center(child: Text('स', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: msg.isUser ? const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF00D4FF)]) : null,
                          color: msg.isUser ? null : const Color(0xFF1A2035),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg.text, style: GoogleFonts.notoSansDevanagari(color: Colors.white, fontSize: 14, height: 1.5)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          color: const Color(0xFF0D1321),
          child: Row(children: [
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: _isListening ? [Colors.red, Colors.redAccent] : [const Color(0xFF00D4FF), const Color(0xFF7B2FBE)]),
                ),
                child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2035),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.notoSansDevanagari(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'सानप AI ला विचारा...',
                    hintStyle: GoogleFonts.notoSansDevanagari(color: Colors.white30),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF00D4FF)]),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
