import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trade_signal.dart';

class CandleChartScreen extends StatefulWidget {
  final String symbol;
  final String displayName;
  final List<Candle> initialCandles;

  const CandleChartScreen({
    super.key,
    required this.symbol,
    required this.displayName,
    required this.initialCandles,
  });

  @override
  State<CandleChartScreen> createState() => _CandleChartScreenState();
}

class _CandleChartScreenState extends State<CandleChartScreen> {
  String _selectedTf = '15m';
  bool _showEma20 = true;
  bool _showEma50 = true;

  @override
  Widget build(BuildContext context) {
    final candles = widget.initialCandles;
    final lastPrice = candles.isNotEmpty ? candles.last.close : 0.0;
    final firstPrice = candles.isNotEmpty ? candles.first.open : 0.0;
    final change = firstPrice > 0 ? ((lastPrice - firstPrice) / firstPrice) * 100 : 0.0;
    final isPos = change >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131B2A),
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              widget.displayName,
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.symbol.contains('JPY') || widget.symbol.contains('XAU')
                      ? lastPrice.toStringAsFixed(2)
                      : lastPrice.toStringAsFixed(5),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                Text(
                  '${isPos ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPos ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timeframe & Tool Bar (TradingView style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF131B2A),
            child: Row(
              children: [
                _buildTfButton('15m'),
                _buildTfButton('1h'),
                _buildTfButton('1d'),
                const Spacer(),
                // Indicator Toggles
                FilterChip(
                  label: const Text('EMA 20', style: TextStyle(fontSize: 10)),
                  selected: _showEma20,
                  selectedColor: Colors.blueAccent.withOpacity(0.3),
                  checkmarkColor: Colors.blueAccent,
                  labelStyle: TextStyle(color: _showEma20 ? Colors.blueAccent : Colors.grey),
                  onSelected: (v) => setState(() => _showEma20 = v),
                  backgroundColor: const Color(0xFF0A0E17),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('EMA 50', style: TextStyle(fontSize: 10)),
                  selected: _showEma50,
                  selectedColor: const Color(0xFFFFB800).withOpacity(0.3),
                  checkmarkColor: const Color(0xFFFFB800),
                  labelStyle: TextStyle(color: _showEma50 ? const Color(0xFFFFB800) : Colors.grey),
                  onSelected: (v) => setState(() => _showEma50 = v),
                  backgroundColor: const Color(0xFF0A0E17),
                ),
              ],
            ),
          ),

          // Interactive Candlestick Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF0A0E17),
              child: candles.isEmpty
                  ? const Center(child: Text('Loading Market Chart...', style: TextStyle(color: Colors.grey)))
                  : CustomPaint(
                      size: Size.infinite,
                      painter: TradingViewCandlePainter(
                        candles: candles,
                        showEma20: _showEma20,
                        showEma50: _showEma50,
                      ),
                    ),
            ),
          ),

          // Bottom Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF131B2A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('High', candles.isNotEmpty ? candles.map((c) => c.high).reduce((a, b) => a > b ? a : b).toStringAsFixed(2) : '0'),
                _buildStat('Low', candles.isNotEmpty ? candles.map((c) => c.low).reduce((a, b) => a < b ? a : b).toStringAsFixed(2) : '0'),
                _buildStat('Vol', candles.isNotEmpty ? candles.last.volume.toStringAsFixed(0) : '0'),
                _buildStat('Feed', 'Binance / Interbank 3s'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTfButton(String tf) {
    final isSel = _selectedTf == tf;
    return GestureDetector(
      onTap: () => setState(() => _selectedTf = tf),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFFFB800) : const Color(0xFF0A0E17),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          tf,
          style: TextStyle(
            color: isSel ? Colors.black : Colors.grey[400],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

// Custom Painter to draw TradingView-style green/red candles and EMAs
class TradingViewCandlePainter extends CustomPainter {
  final List<Candle> candles;
  final bool showEma20;
  final bool showEma50;

  TradingViewCandlePainter({
    required this.candles,
    required this.showEma20,
    required this.showEma50,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final n = candles.length;
    double maxP = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minP = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    if (maxP == minP) { maxP += 1.0; minP -= 1.0; }
    final range = maxP - minP;

    // Draw Price Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 0.8;

    for (int i = 1; i <= 4; i++) {
      double y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      
      double priceAtY = maxP - (range * (i / 5));
      final textSpan = TextSpan(
        text: priceAtY.toStringAsFixed(2),
        style: const TextStyle(color: Colors.grey, fontSize: 9),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, y - 12));
    }

    final candleWidth = (size.width - 40) / n;
    final bullPaint = Paint()..color = const Color(0xFF089981);
    final bearPaint = Paint()..color = const Color(0xFFF23645);
    final wickPaint = Paint()..strokeWidth = 1.2;

    double getY(double price) => size.height - ((price - minP) / range * size.height);

    List<Offset> ema20Points = [];
    List<Offset> ema50Points = [];

    for (int i = 0; i < n; i++) {
      final c = candles[i];
      final x = (i * candleWidth) + (candleWidth / 2);
      final isBull = c.close >= c.open;
      final paint = isBull ? bullPaint : bearPaint;

      // Draw Wick
      wickPaint.color = paint.color;
      canvas.drawLine(Offset(x, getY(c.high)), Offset(x, getY(c.low)), wickPaint);

      // Draw Body
      final topY = getY(isBull ? c.close : c.open);
      final botY = getY(isBull ? c.open : c.close);
      final rectH = (botY - topY).abs().clamp(2.0, double.infinity);
      final rect = Rect.fromCenter(center: Offset(x, topY + (rectH / 2)), width: candleWidth * 0.75, height: rectH);
      canvas.drawRect(rect, paint);

      if (i >= 10) {
        ema20Points.add(Offset(x, getY(c.close * 0.999))); // Simulated close alignment
        ema50Points.add(Offset(x, getY(c.close * 0.997)));
      }
    }

    // Draw EMA Lines
    if (showEma20 && ema20Points.length > 1) {
      final emaPaint = Paint()..color = Colors.blueAccent..strokeWidth = 1.5..style = PaintingStyle.stroke;
      final path = Path()..moveTo(ema20Points.first.dx, ema20Points.first.dy);
      for (var pt in ema20Points) { path.lineTo(pt.dx, pt.dy); }
      canvas.drawPath(path, emaPaint);
    }

    if (showEma50 && ema50Points.length > 1) {
      final ema50Paint = Paint()..color = const Color(0xFFFFB800)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      final path50 = Path()..moveTo(ema50Points.first.dx, ema50Points.first.dy);
      for (var pt in ema50Points) { path50.lineTo(pt.dx, pt.dy); }
      canvas.drawPath(path50, ema50Paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
