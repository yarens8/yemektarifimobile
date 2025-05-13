import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class Message {
  final String text;
  final String sender; // 'user' veya 'ai'
  final DateTime time;
  Message({required this.text, required this.sender, required this.time});
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _showWelcome = true;
      });
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(Message(text: text, sender: 'user', time: DateTime.now()));
      isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();
    final aiReply = await fetchAIReply(text);
    setState(() {
      messages.add(Message(text: aiReply, sender: 'ai', time: DateTime.now()));
      isLoading = false;
    });
    _scrollToBottom();
  }

  Future<String> fetchAIReply(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/ai-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Yanıt alınamadı.';
      } else {
        return 'Bir hata oluştu: ${response.body}';
      }
    } catch (e) {
      return 'Bir hata oluştu: $e';
    }
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFFF8F9FB), // soft açık gri
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [Color(0xFFF06292), Color(0xFFE040FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFFE91E63), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Malzeme Asistanı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Malzeme alternatifleri için bana yazabilirsin!',
                                style: TextStyle(
                                  color: Color(0xFFF8BBD0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: messages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => ChatBubble(message: messages[index]),
                  ),
                ),
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE91E63),
                          child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
                          radius: 14,
                        ),
                        const SizedBox(width: 8),
                        const Text('Yanıt yazılıyor...', style: TextStyle(color: Color(0xFFE91E63))),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE91E63)),
                        ),
                      ],
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Mesaj yaz...'
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFFE91E63), size: 28),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showWelcome)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CustomPaint(
                        painter: WelcomeRobotPainter(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Merhaba! Ben Malzeme Asistanı',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE040FB),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Mutfakta eksik malzeme için bana sor, sana alternatif önereyim! Sohbete başlamak için aşağıdaki butona tıkla.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE91E63),
                        shape: StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        elevation: 2,
                      ),
                      onPressed: () {
                        setState(() {
                          _showWelcome = false;
                        });
                      },
                      child: const Text(
                        'Sohbete Başla',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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

class ChatBubble extends StatelessWidget {
  final Message message;
  const ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    final bgColor = isUser ? const Color(0xFFF06292) : Colors.white;
    final textColor = isUser ? Colors.white : const Color(0xFFE91E63);
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isUser ? 22 : 6),
      bottomRight: Radius.circular(isUser ? 6 : 22),
    );
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 40 : 12,
        right: isUser ? 12 : 40,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE040FB), Color(0xFFF06292)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.18),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: align,
              children: [
                Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        left: !isUser ? 8 : 0,
                        right: isUser ? 8 : 0,
                        bottom: 6,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                    // Kuyruk
                    Positioned(
                      bottom: 0,
                      left: isUser ? null : 18,
                      right: isUser ? 18 : null,
                      child: CustomPaint(
                        painter: SoftTailPainter(
                          color: bgColor,
                          isUser: isUser,
                        ),
                        size: const Size(18, 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF06292), Color(0xFFE040FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.12),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class SoftTailPainter extends CustomPainter {
  final Color color;
  final bool isUser;
  SoftTailPainter({required this.color, required this.isUser});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isUser) {
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(size.width * 0.7, size.height * 0.7, size.width * 0.2, size.height);
      path.lineTo(size.width * 0.2, size.height - 4);
      path.quadraticBezierTo(size.width * 0.7, size.height * 0.5, size.width, 0);
    } else {
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width * 0.3, size.height * 0.7, size.width * 0.8, size.height);
      path.lineTo(size.width * 0.8, size.height - 4);
      path.quadraticBezierTo(size.width * 0.3, size.height * 0.5, 0, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WelcomeRobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [Color(0xFFF06292), Color(0xFFE040FB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final bodyPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = Colors.black87;
    final pinkPaint = Paint()..color = Color(0xFFE040FB);

    // Maskotu daha büyük yapmak için scale ve yukarı taşımak için translate
    final double scale = 1.6;
    final double yOffset = -size.height * 0.10;
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.54 + yOffset);
    canvas.scale(scale, scale);
    canvas.translate(-size.width * 0.5, -size.height * 0.54);

    // Spring shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFFE0B3F7).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.93),
        width: size.width * 0.38,
        height: size.height * 0.05,
      ),
      shadowPaint,
    );

    // Spring
    final springPaint = Paint()
      ..color = Color(0xFFE040FB)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final springY = size.height * 0.87;
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.38, springY + i * 7, size.width * 0.24, 7),
        0,
        math.pi,
        false,
        springPaint,
      );
    }

    // Body (dikey, büyük oval)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.62),
      width: size.width * 0.44,
      height: size.height * 0.48,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(size.width * 0.22)),
      bodyPaint,
    );

    // Sol kol (gövdeden ayrı, yukarıya doğru kavisli ve ince, ucu yuvarlatılmış)
    final armPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final armWidth = size.width * 0.10;
    final armStart = Offset(size.width * 0.40, size.height * 0.60);
    final armEnd = Offset(size.width * 0.20, size.height * 0.05);
    final control = Offset(size.width * 0.24, size.height * 0.15);

    final armPath = Path();
    armPath.moveTo(armStart.dx, armStart.dy);
    armPath.quadraticBezierTo(
      control.dx, control.dy,
      armEnd.dx, armEnd.dy,
    );
    // Kolun kalınlığı için paralel bir yol
    armPath.arcToPoint(
      Offset(armEnd.dx + armWidth, armEnd.dy + armWidth * 0.2),
      radius: Radius.circular(armWidth),
      clockwise: false,
    );
    armPath.quadraticBezierTo(
      control.dx + armWidth, control.dy + armWidth * 0.2,
      armStart.dx + armWidth, armStart.dy + armWidth * 0.2,
    );
    armPath.close();
    canvas.drawPath(armPath, armPaint);
    // Kolun ucunu daha oval ve küçük göstermek için küçük bir el/oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(armEnd.dx + armWidth * 0.5, armEnd.dy + armWidth * 0.2),
        width: armWidth * 0.9,
        height: armWidth * 0.9,
      ),
      armPaint,
    );

    // Sağ kol (kısa ve vücuda yakın, belirgin, istersen kaldırabilirsin)
    final rightArmPath = Path();
    rightArmPath.moveTo(size.width * 0.62, size.height * 0.72);
    rightArmPath.quadraticBezierTo(
      size.width * 0.80, size.height * 0.80,
      size.width * 0.62, size.height * 0.60,
    );
    rightArmPath.quadraticBezierTo(
      size.width * 0.66, size.height * 0.68,
      size.width * 0.62, size.height * 0.72,
    );
    rightArmPath.close();
    canvas.drawPath(rightArmPath, bodyPaint);

    // Saç/şerit detayı (sol üst)
    final hairPath = Path();
    hairPath.moveTo(size.width * 0.39, size.height * 0.22);
    hairPath.quadraticBezierTo(
      size.width * 0.28, size.height * 0.13,
      size.width * 0.36, size.height * 0.32,
    );
    hairPath.quadraticBezierTo(
      size.width * 0.39, size.height * 0.28,
      size.width * 0.39, size.height * 0.22,
    );
    hairPath.close();
    canvas.drawPath(hairPath, pinkPaint);

    // Head (daha büyük daire)
    final headCenter = Offset(size.width * 0.5, size.height * 0.32);
    final headRadius = size.width * 0.23;
    canvas.drawCircle(headCenter, headRadius, bodyPaint);

    // Face (beyaz daire)
    canvas.drawCircle(headCenter, size.width * 0.14, whitePaint);

    // Eyes
    canvas.drawCircle(Offset(size.width * 0.47, size.height * 0.31), size.width * 0.025, blackPaint);
    canvas.drawCircle(Offset(size.width * 0.53, size.height * 0.31), size.width * 0.025, blackPaint);

    // Smile
    final smileRect = Rect.fromLTWH(size.width * 0.48, size.height * 0.34, size.width * 0.06, size.height * 0.025);
    canvas.drawArc(smileRect, 0, math.pi, false, blackPaint..strokeWidth = 2..style = PaintingStyle.stroke);

    // Anten (daha ince, uzun, düz çizgi ve sade top)
    final antennaPaint = Paint()
      ..color = Color(0xFFE040FB)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final antennaStart = Offset(size.width * 0.5, size.height * 0.19);
    final antennaEnd = Offset(size.width * 0.5, size.height * 0.01);
    canvas.drawLine(antennaStart, antennaEnd, antennaPaint..strokeWidth = 3);
    // Anten topu (sade, düz renk ve hafif gölge)
    final antennaBallCenter = Offset(size.width * 0.5, size.height * 0.01);
    final antennaBallRadius = size.width * 0.03;
    canvas.drawCircle(antennaBallCenter, antennaBallRadius, pinkPaint);
    // Hafif gölge
    canvas.drawCircle(
      Offset(antennaBallCenter.dx + antennaBallRadius * 0.3, antennaBallCenter.dy + antennaBallRadius * 0.3),
      antennaBallRadius * 0.5,
      Paint()..color = Colors.black12,
    );

    // Gövdeye küçük gülümseme
    final bodySmileRect = Rect.fromLTWH(size.width * 0.58, size.height * 0.75, size.width * 0.08, size.height * 0.025);
    canvas.drawArc(bodySmileRect, 0, math.pi * 0.7, false, whitePaint..strokeWidth = 2..style = PaintingStyle.stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 