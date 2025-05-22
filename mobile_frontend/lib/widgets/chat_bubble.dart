import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime? time;

  const ChatBubble({
    required this.text,
    this.isMe = false,
    this.time,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? const LinearGradient(colors: [Color(0xFFF8BBD0), Color(0xFFE1BEE7)])
        : const LinearGradient(colors: [Color(0xFFE1BEE7), Color(0xFFF3E5F5)]);
    final textColor = Colors.black87;
    final avatarBg = isMe ? const Color(0xFFF8BBD0) : const Color(0xFFE1BEE7);
    final avatarIcon = isMe ? Icons.person : Icons.smart_toy;
    final timeStr = time != null ? DateFormat.Hm().format(time!) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: avatarBg,
                child: Icon(avatarIcon, color: Color(0xFF7B1FA2)),
                radius: 18,
              ),
            ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 270),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                gradient: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(isMe ? 20 : 8),
                  bottomRight: Radius.circular(isMe ? 8 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (time != null)
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: avatarBg,
                child: Icon(avatarIcon, color: Colors.white),
                radius: 18,
              ),
            ),
        ],
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