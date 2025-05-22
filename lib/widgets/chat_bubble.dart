import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatBubble({required this.text, this.isMe = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: CustomPaint(
        painter: BubblePainter(isMe: isMe),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  final bool isMe;
  BubblePainter({required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height - 10),
      const Radius.circular(32),
    );

    // Kuyruk (balonun çıkıntısı)
    final path = Path()
      ..addRRect(rrect)
      ..moveTo(isMe ? size.width - 28 : 28, size.height - 10)
      ..lineTo(isMe ? size.width - 18 : 18, size.height)
      ..lineTo(isMe ? size.width - 38 : 38, size.height - 10)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 