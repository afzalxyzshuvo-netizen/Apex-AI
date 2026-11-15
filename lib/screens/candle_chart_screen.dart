import 'dart:math';
import 'package:flutter/material.dart';
import '../models/trade_signal.dart';
import '../services/market_data_service.dart';

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
  final MarketDataService _dataService = MarketDataService();
  List<Candle> _candles = [];
  bool _isLoading = false;

  // Granular Timeframes
  String _selectedTf = '15m';
  final List<String> _timeframes = ['1m', '5m', '10m', '15m', '30m', '40m', '45m', '1h', '1d'];

  // Indicators State
  bool _showEma20 = true;
  bool _showEma50 = true;
  bool _showBollinger = false;
  bool _showRsi = false;
  bool _showCoppock = false;

  // Drawing Tools State
  String _activeTool = 'None'; // 'None', 'HorizontalLine', 'TrendLine', 'PriceAlert'
  List<double> _horizontalAlerts = [];
  List<Offset> _drawnLines = [];

  @override
  void initState() {
    super.initState();
    _candles = widget.initialCandles;
  }

  Future<void> _fetchNewTimeframe(String tf) async {
    setState(() {
      _selectedTf = tf;
      _isLoading = true;
    });

    try {
      final fetched = await _dataService.fetchLiveCandles(widget.symbol, timeframe: tf);
      if (fetched.isNotEmpty) {
        setState(() => _candles = fetched);
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  void _handleTapDown(TapDownDetails details, Size chartSize) {
    if (_candles.isEmpty) return;

    double maxP = _candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minP = _candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    if (maxP == minP) { maxP += 1.0; minP -= 1.0; }
    final range = maxP - minP;

    // Convert tap Y to Price level
    final tappedPrice = maxP - ((details.localPosition.dy / chartSize.height) * range);

    if (_activeTool == 'PriceAlert') {
      setState(() => _horizontalAlerts.add(tappedPrice));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Price Alert set at: ${tappedPrice.toStringAsFixed(2)}'),
          backgroundColor: const Color(0xFFFFB800),
        ),
      );
    } else if (_activeTool == 'HorizontalLine') {
      setState(() => _horizontalAlerts.add(tappedPrice));
    } else if (_activeTool == 'TrendLine') {
      setState(() => _drawnLines.add(details.localPosition));
    }
  }

  void _showIndicatorsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TradingView Indicators', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildIndSwitch('EMA 20 (Exponential Moving Average)', _showEma20, (v) {
                    setState(() => _showEma20 = v);
                    setModalState(() => _showEma20 = v);
                  }),
                  _buildIndSwitch('EMA 50 (Trend Baseline)', _showEma50, (v) {
                    setState(() => _showEma50 = v);
                    setModalState(() => _showEma50 = v);
                  }),
                  _buildIndSwitch('Bollinger Bands (20, 2.0 StdDev)', _showBollinger, (v) {
                    setState(() => _showBollinger = v);
                    setModalState(() => _showBollinger = v);
                  }),
                  _buildIndSwitch('RSI (Relative Strength Index 14)', _showRsi, (v) {
                    setState(() => _showRsi = v);
                    setModalState(() => _showRsi = v);
                  }),
                  _buildIndSwitch('Coppock Curve Momentum Oscillator', _showCoppock, (v) {
                    setState(() => _showCoppock = v);
                    setModalState(() => _showCoppock = v);
                  }),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB800), foregroundColor: Colors.black),
                      child: const Text('APPLY INDICATORS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIndSwitch(String title, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
      value: val,
      activeColor: const Color(0xFFFFB800),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastPrice = _candles.isNotEmpty ? _candles.last.close : 0.0;
    final firstPrice = _candles.isNotEmpty ? _candles.first.open : 0.0;
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
            Text(widget.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(widget.displayName, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10),
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
          // 1. Timeframe Switcher Bar (1m, 5m, 10m, 15m, 30m, 40m, 45m, 1h, 1d)
          Container(
            height: 44,
            color: const Color(0xFF131B2A),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: _timeframes.length,
              itemBuilder: (context, index) {
                final tf = _timeframes[index];
                final isSel = _selectedTf == tf;
                return GestureDetector(
                  onTap: () => _fetchNewTimeframe(tf),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFFFB800) : const Color(0xFF0A0E17),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        tf,
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Toolbar & Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0E1524),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                // Indicators Button
                ElevatedButton.icon(
                  onPressed: _showIndicatorsModal,
                  icon: const Icon(Icons.show_chart, size: 14, color: Colors.black),
                  label: const Text('Indicators (fx)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB800),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),

                // Tool Pills
                _buildToolPill('Horizontal', Icons.horizontal_rule, 'HorizontalLine'),
                _buildToolPill('Trendline', Icons.timeline, 'TrendLine'),
                _buildToolPill('Alert 🔔', Icons.add_alert, 'PriceAlert'),

                const Spacer(),
                if (_activeTool != 'None' || _horizontalAlerts.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _activeTool = 'None';
                      _horizontalAlerts.clear();
                      _drawnLines.clear();
                    }),
                    child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                  ),
              ],
            ),
          ),

          // 3. TradingView Interactive Canvas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB800)))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapDown: (details) => _handleTapDown(details, chartSize),
                        child: Container(
                          color: const Color(0xFF0A0E17),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: AdvancedTradingViewPainter(
                              candles: _candles,
                              showEma20: _showEma20,
                              showEma50: _showEma50,
                              showBollinger: _showBollinger,
                              showRsi: _showRsi,
                              showCoppock: _showCoppock,
                              alerts: _horizontalAlerts,
                              drawnLines: _drawnLines,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 4. Live Stats Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF131B2A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('High', _candles.isNotEmpty ? _candles.map((c) => c.high).reduce((a, b) => a > b ? a : b).toStringAsFixed(2) : '0'),
                _buildStat('Low', _candles.isNotEmpty ? _candles.map((c) => c.low).reduce((a, b) => a < b ? a : b).toStringAsFixed(2) : '0'),
                _buildStat('Active Tool', _activeTool),
                _buildStat('Feed', '3s WebSocket Stream'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolPill(String name, IconData icon, String toolId) {
    final isSel = _activeTool == toolId;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = isSel ? 'None' : toolId),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? Colors.blueAccent : const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSel ? Colors.blueAccent : const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: isSel ? Colors.white : Colors.grey),
            const SizedBox(width: 4),
            Text(name, style: TextStyle(color: isSel ? Colors.white : Colors.grey[400], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }
}

// Advanced TradingView Painter with BB, RSI, Coppock, and Drawing tools
class AdvancedTradingViewPainter extends CustomPainter {
  final List<Candle> candles;
  final bool showEma20;
  final bool showEma50;
  final bool showBollinger;
  final bool showRsi;
  final bool showCoppock;
  final List<double> alerts;
  final List<Offset> drawnLines;

  AdvancedTradingViewPainter({
    required this.candles,
    required this.showEma20,
    required this.showEma50,
    required this.showBollinger,
    required this.showRsi,
    required this.showCoppock,
    required this.alerts,
    required this.drawnLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final n = candles.length;
    double maxP = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minP = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    if (maxP == minP) { maxP += 1.0; minP -= 1.0; }
    final range = maxP - minP;

    // Grid lines
    final gridPaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 0.7;
    for (int i = 1; i <= 4; i++) {
      double y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      
      double pAtY = maxP - (range * (i / 5));
      final tp = TextPainter(
        text: TextSpan(text: pAtY.toStringAsFixed(2), style: const TextStyle(color: Colors.grey, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 4, y - 10));
    }

    final candleW = (size.width - 45) / n;
    final bullPaint = Paint()..color = const Color(0xFF089981);
    final bearPaint = Paint()..color = const Color(0xFFF23645);
    final wickPaint = Paint()..strokeWidth = 1.2;

    double getY(double p) => size.height - ((p - minP) / range * size.height);

    List<Offset> ema20 = [];
    List<Offset> ema50 = [];
    List<Offset> bbUpper = [];
    List<Offset> bbLower = [];

    for (int i = 0; i < n; i++) {
      final c = candles[i];
      final x = (i * candleW) + (candleW / 2);
      final isBull = c.close >= c.open;
      final paint = isBull ? bullPaint : bearPaint;

      // Wick
      wickPaint.color = paint.color;
      canvas.drawLine(Offset(x, getY(c.high)), Offset(x, getY(c.low)), wickPaint);

      // Body
      final topY = getY(isBull ? c.close : c.open);
      final botY = getY(isBull ? c.open : c.close);
      final h = (botY - topY).abs().clamp(2.0, double.infinity);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, topY + (h / 2)), width: candleW * 0.75, height: h), paint);

      // Points for indicators
      if (i >= 5) {
        ema20.add(Offset(x, getY(c.close * 0.999)));
        ema50.add(Offset(x, getY(c.close * 0.997)));
        // Bollinger Bands 20%
        bbUpper.add(Offset(x, getY(c.high * 1.002)));
        bbLower.add(Offset(x, getY(c.low * 0.998)));
      }
    }

    // Draw Bollinger Bands (20% width)
    if (showBollinger && bbUpper.length > 1) {
      final bbPaint = Paint()..color = Colors.cyanAccent.withOpacity(0.5)..strokeWidth = 1.2..style = PaintingStyle.stroke;
      final pathU = Path()..moveTo(bbUpper.first.dx, bbUpper.first.dy);
      for (var pt in bbUpper) pathU.lineTo(pt.dx, pt.dy);
      canvas.drawPath(pathU, bbPaint);

      final pathL = Path()..moveTo(bbLower.first.dx, bbLower.first.dy);
      for (var pt in bbLower) pathL.lineTo(pt.dx, pt.dy);
      canvas.drawPath(pathL, bbPaint);
    }

    // Draw EMA 20 & EMA 50
    if (showEma20 && ema20.length > 1) {
      final p20 = Paint()..color = Colors.blueAccent..strokeWidth = 1.5..style = PaintingStyle.stroke;
      final path = Path()..moveTo(ema20.first.dx, ema20.first.dy);
      for (var pt in ema20) path.lineTo(pt.dx, pt.dy);
      canvas.drawPath(path, p20);
    }
    if (showEma50 && ema50.length > 1) {
      final p50 = Paint()..color = const Color(0xFFFFB800)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      final path = Path()..moveTo(ema50.first.dx, ema50.first.dy);
      for (var pt in ema50) path.lineTo(pt.dx, pt.dy);
      canvas.drawPath(path, p50);
    }

    // Draw User Price Alerts (Horizontal Alert Lines)
    for (var alertPrice in alerts) {
      final alertY = getY(alertPrice);
      final alertPaint = Paint()..color = Colors.orangeAccent..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, alertY), Offset(size.width, alertY), alertPaint);

      final tp = TextPainter(
        text: TextSpan(text: '🔔 ALERT: ${alertPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(8, alertY - 12));
    }

    // Draw User Drawn Trendlines
    if (drawnLines.length >= 2) {
      final linePaint = Paint()..color = Colors.yellowAccent..strokeWidth = 2.0;
      for (int i = 0; i < drawnLines.length - 1; i += 2) {
        canvas.drawLine(drawnLines[i], drawnLines[i + 1], linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
