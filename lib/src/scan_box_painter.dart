part of eid_scanner;




/// Custom painter to draw the scan box and its corners on the camera preview.
/// This class paints the scan box and darkens the areas outside the box for focus.
class ScanBoxPainter extends CustomPainter {
  final Rect? scanBox;

  /// Creates a [ScanBoxPainter] to paint the scan box.
  ScanBoxPainter(this.scanBox);

  @override
  void paint(Canvas canvas, Size size) {
    if (scanBox == null) return;

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    // Draw dark overlay outside the scan box
    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRect(scanBox!),
    );

    canvas.drawPath(path, overlayPaint);

    // Draw scan box
    canvas.drawRect(scanBox!, paint);

    // Draw the corners of the scan box
    canvas.drawLine(scanBox!.topLeft, Offset(scanBox!.left + 20, scanBox!.top), borderPaint);
    canvas.drawLine(scanBox!.topLeft, Offset(scanBox!.left, scanBox!.top + 20), borderPaint);

    canvas.drawLine(scanBox!.topRight, Offset(scanBox!.right - 20, scanBox!.top), borderPaint);
    canvas.drawLine(scanBox!.topRight, Offset(scanBox!.right, scanBox!.top + 20), borderPaint);

    canvas.drawLine(scanBox!.bottomLeft, Offset(scanBox!.left + 20, scanBox!.bottom), borderPaint);
    canvas.drawLine(scanBox!.bottomLeft, Offset(scanBox!.left, scanBox!.bottom - 20), borderPaint);

    canvas.drawLine(scanBox!.bottomRight, Offset(scanBox!.right - 20, scanBox!.bottom), borderPaint);
    canvas.drawLine(scanBox!.bottomRight, Offset(scanBox!.right, scanBox!.bottom - 20), borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
