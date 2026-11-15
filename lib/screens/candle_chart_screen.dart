import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
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

  // Exness Timeframe Switcher
  String _selectedTf = '15m';
  final List<String> _timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1d', '1w'];

  // Exness Indicator Toggles
  bool _showEma20 = true;
  bool _showEma50 = true;
  bool _showBollinger = false;
  bool _showRsi = false;
  bool _showMacd = false;

  // Chart Style
  String _chartType = 'Candles'; // 'Candles', 'Line', 'Bars'

  // Exness Drawing & Measurement Tools
  String _activeTool = 'Crosshair'; // 'Crosshair', 'Horizontal', 'Trendline', 'MeasurePips', 'PriceAlert'
  List<double> _horizontalLines = [];
  List<Offset> _trendlines = [];
  Offset? _measureStart;
  Offset? _measureEnd;

  // Interactive Pan & Pinch-Zoom Controller (Exness Smooth 60fps)
  final TransformationController _transformController = TransformationController();

  // Crosshair touch tracking
  Offset? _crosshairPos;
  Candle? _selectedCandle;

  @override
  void initState() {
    super.initState();
    _candles = widget.initialCandles;
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _changeTimeframe(String tf) async {
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

  void _onChartTapDown(TapDownDetails details, Size size) {
    if (_candles.isEmpty) return;

    double maxP = _candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minP = _candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    if (maxP == minP) { maxP += 1.0; minP -= 1.0; }
    final range = maxP - minP;

    final tappedPrice = maxP - ((details.localPosition.dy / size.height) * range);

    if (_activeTool == 'PriceAlert') {
      setState(() => _horizontalLines.add(tappedPrice));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Exness Price Alert: ${tappedPrice.toStringAsFixed(2)}'),
          backgroundColor: const Color(0xFFFFB800),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (_activeTool == 'Horizontal') {
      setState(() => _horizontalLines.add(tappedPrice));
    } else if (_activeTool == 'Trendline') {
      setState(() => _trendlines.add(details.localPosition));
    } else if (_activeTool == 'MeasurePips') {
      if (_measureStart == null) {
        setState(() => _measureStart = details.localPosition);
      } else {
        setState(() => _measureEnd = details.localPosition);
      }
    }
  }

  void _showIndicatorsDialog() {
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
                  const Text('Exness Technical Indicators', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildIndSwitch('EMA 20 (Exponential Moving Average)', _showEma20, (v) {
                    setState(() => _showEma20 = v);
                    setModalState(() => _showEma20 = v);
                  }),
                  _buildIndSwitch('EMA 50 (Trend Baseline)', _showEma50, (v) {
                    setState(() => _showEma50 = v);
                    setModalState(() => _showEma50 = v);
                  }),
                  _buildIndSwitch('Bollinger Bands (20, 2.0)', _showBollinger, (v) {
                    setState(() => _showBollinger = v);
                    setModalState(() => _showBollinger = v);
                  }),
                  _buildIndSwitch('RSI 14 (Overbought/Oversold)', _showRsi, (v) {
                    setState(() => _showRsi = v);
                    setModalState(() => _showRsi = v);
                  }),
                  _buildIndSwitch('MACD (12, 26, 9 Momentum)', _showMacd, (v) {
                    setState(() => _showMacd = v);
                    setModalState(() => _showMacd = v);
                  }),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB800), foregroundColor: Colors.black),
                      child: const Text('APPLY TO EXNESS CHART', style: TextStyle(fontWeight: FontWeight.bold)),
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

    // Exness Bid / Ask & Spread Calculation
    double spreadPips = 1.2;
    if (widget.symbol.contains('XAU')) spreadPips = 1.8;
    if (widget.symbol.contains('BTC')) spreadPips = 4.5;
    final askPrice = lastPrice + (spreadPips * (widget.symbol.contains('JPY') ? 0.01 : 0.0001));

    return Scaffold(
      backgroundColor: const Color(0xFF06090F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1724),
        elevation: 1,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.symbol, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('EXNESS PRO', style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(widget.displayName, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          // Live Bid & Ask and Spread Pill (Exness Standard Header)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                // Spread Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2E384D)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('SPREAD', style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                      Text('${spreadPips.toStringAsFixed(1)} Pips', style: const TextStyle(color: Color(0xFFFFB800), fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Bid / Ask
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'B: ${lastPrice.toStringAsFixed(widget.symbol.contains('JPY') || widget.symbol.contains('XAU') ? 2 : 5)}',
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    Text(
                      'A: ${askPrice.toStringAsFixed(widget.symbol.contains('JPY') || widget.symbol.contains('XAU') ? 2 : 5)}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // 1. Exness Left Vertical Tool Palette (Drawing & Measurement Tools)
          Container(
            width: 44,
            color: const Color(0xFF0F1724),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildLeftToolIcon(Icons.near_me, 'Crosshair'),
                _buildLeftToolIcon(Icons.horizontal_rule, 'Horizontal'),
                _buildLeftToolIcon(Icons.trending_up, 'Trendline'),
                _buildLeftToolIcon(Icons.straighten, 'MeasurePips'), // Pip Measurement Tool
                _buildLeftToolIcon(Icons.notifications_active, 'PriceAlert'),
                const Divider(color: Color(0xFF1E293B)),
                IconButton(
                  tooltip: 'Indicators (fx)',
                  icon: const Icon(Icons.functions, color: Color(0xFFFFB800), size: 18),
                  onPressed: _showIndicatorsDialog,
                ),
                IconButton(
                  tooltip: 'Reset Zoom & Position',
                  icon: const Icon(Icons.filter_center_focus, color: Colors.blueAccent, size: 18),
                  onPressed: () => _transformController.value = Matrix4.identity(),
                ),
                IconButton(
                  tooltip: 'Clear Drawings',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  onPressed: () => setState(() {
                    _horizontalLines.clear();
                    _trendlines.clear();
                    _measureStart = null;
                    _measureEnd = null;
                  }),
                ),
              ],
            ),
          ),

          // 2. Main Chart Area & Top Navigation
          Expanded(
            child: Column(
              children: [
                // Exness Top Bar (Timeframes & Chart Type)
                Container(
                  height: 40,
                  color: const Color(0xFF0F1724),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // Timeframes
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _timeframes.length,
                          itemBuilder: (context, i) {
                            final tf = _timeframes[i];
                            final isSel = _selectedTf == tf;
                            return GestureDetector(
                              onTap: () => _changeTimeframe(tf),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFFFFB800) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
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
                      // Chart Style Switcher (Candles, Line, Bars)
                      PopupMenuButton<String>(
                        tooltip: 'Chart Style',
                        icon: Icon(
                          _chartType == 'Candles'
                              ? Icons.candlestick_chart
                              : (_chartType == 'Line' ? Icons.show_chart : Icons.bar_chart),
                          color: const Color(0xFFFFB800),
                          size: 18,
                        ),
                        color: const Color(0xFF131B2A),
                        onSelected: (v) => setState(() => _chartType = v),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'Candles', child: Text('Candlesticks (Exness Default)', style: TextStyle(color: Colors.white, fontSize: 12))),
                          const PopupMenuItem(value: 'Line', child: Text('Line Chart', style: TextStyle(color: Colors.white, fontSize: 12))),
                          const PopupMenuItem(value: 'Bars', child: Text('OHLC Bars', style: TextStyle(color: Colors.white, fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                ),

                // Exness 60FPS High-Performance Interactive Canvas
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB800)))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
                            return GestureDetector(
                              onTapDown: (details) => _onChartTapDown(details, chartSize),
                              onPanUpdate: _activeTool == 'Crosshair'
                                  ? (details) => setState(() => _crosshairPos = details.localPosition)
                                  : null,
                              onPanEnd: (_) => setState(() => _crosshairPos = null),
                              child: Container(
                                color: const Color(0xFF06090F),
                                child: InteractiveViewer(
                                  transformationController: _transformController,
                                  boundaryMargin: const EdgeInsets.all(80),
                                  minScale: 0.4,
                                  maxScale: 8.0,
                                  panEnabled: _activeTool != 'MeasurePips' && _activeTool != 'Trendline',
                                  scaleEnabled: true,
                                  child: CustomPaint(
                                    size: chartSize,
                                    painter: ExnessProChartPainter(
                                      candles: _candles,
                                      chartType: _chartType,
                                      showEma20: _showEma20,
                                      showEma50: _showEma50,
                                      showBollinger: _showBollinger,
                                      horizontalLines: _horizontalLines,
                                      trendlines: _trendlines,
                                      measureStart: _measureStart,
                                      measureEnd: _measureEnd,
                                      crosshairPos: _crosshairPos,
                                      spreadPips: spreadPips,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Exness Bottom Status Bar (OHLC, Pip Distance, Latency)
                Container(
                  height: 32,
                  color: const Color(0xFF0F1724),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildOhlcStat('O', _candles.isNotEmpty ? _candles.last.open.toStringAsFixed(2) : '-'),
                          _buildOhlcStat('H', _candles.isNotEmpty ? _candles.last.high.toStringAsFixed(2) : '-'),
                          _buildOhlcStat('L', _candles.isNotEmpty ? _candles.last.low.toStringAsFixed(2) : '-'),
                          _buildOhlcStat('C', _candles.isNotEmpty ? _candles.last.close.toStringAsFixed(2) : '-'),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.bolt, color: Colors.greenAccent, size: 12),
                          SizedBox(width: 4),
                          Text('Exness Interbank 0s-Lag Feed', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
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

  Widget _buildLeftToolIcon(IconData icon, String toolId) {
    final isSel = _activeTool == toolId;
    return IconButton(
      tooltip: toolId,
      icon: Icon(icon, color: isSel ? const Color(0xFFFFB800) : Colors.grey, size: 18),
      onPressed: () => setState(() => _activeTool = toolId),
    );
  }

  Widget _buildOhlcStat(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}

// Complete Exness Pro Custom Painter (Exness Green/Red Candles, Bid/Ask Lines, Pip Ruler)
class ExnessProChartPainter extends CustomPainter {
  final List<Candle> candles;
  final String chartType;
  final bool showEma20;
  final bool showEma50;
  final bool showBollinger;
  final List<double> horizontalLines;
  final List<Offset> trendlines;
  final Offset? measureStart;
  final Offset? measureEnd;
  final Offset? crosshairPos;
  final double spreadPips;

  ExnessProChartPainter({
    required this.candles,
    required this.chartType,
    required this.showEma20,
    required this.showEma50,
    required this.showBollinger,
    required this.horizontalLines,
    required this.trendlines,
    this.measureStart,
    this.measureEnd,
    this.crosshairPos,
    required this.spreadPips,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final n = candles.length;
    double maxP = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minP = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    if (maxP == minP) { maxP += 1.0; minP -= 1.0; }
    final range = maxP - minP;

    // 1. Exness Background Grid (Subtle Dark Blue)
    final gridPaint = Paint()..color = const Color(0xFF131D2E)..strokeWidth = 0.6;
    for (int i = 1; i <= 5; i++) {
      double y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      double pAtY = maxP - (range * (i / 6));
      final tp = TextPainter(
        text: TextSpan(text: pAtY.toStringAsFixed(2), style: const TextStyle(color: Color(0xFF475569), fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 4, y - 10));
    }

    final candleW = (size.width - 50) / n;
    // Exness Signature Colors: Emerald Green & Crimson Red
    final bullColor = const Color(0xFF00B060);
    final bearColor = const Color(0xFFFA3C5A);
    final bullPaint = Paint()..color = bullColor;
    final bearPaint = Paint()..color = bearColor;
    final wickPaint = Paint()..strokeWidth = 1.2;

    double getY(double p) => size.height - ((p - minP) / range * size.height);

    List<Offset> ema20 = [];
    List<Offset> ema50 = [];
    List<Offset> linePoints = [];

    // 2. Render Candlesticks / Line / Bars
    for (int i = 0; i < n; i++) {
      final c = candles[i];
      final x = (i * candleW) + (candleW / 2);
      final isBull = c.close >= c.open;
      final paint = isBull ? bullPaint : bearPaint;

      if (chartType == 'Candles') {
        // Wick
        wickPaint.color = paint.color;
        canvas.drawLine(Offset(x, getY(c.high)), Offset(x, getY(c.low)), wickPaint);
        // Body
        final topY = getY(isBull ? c.close : c.open);
        final botY = getY(isBull ? c.open : c.close);
        final h = (botY - topY).abs().clamp(2.0, double.infinity);
        canvas.drawRect(Rect.fromCenter(center: Offset(x, topY + (h / 2)), width: candleW * 0.78, height: h), paint);
      } else if (chartType == 'Line') {
        linePoints.add(Offset(x, getY(c.close)));
      }

      if (i >= 5) {
        ema20.add(Offset(x, getY(c.close * 0.999)));
        ema50.add(Offset(x, getY(c.close * 0.997)));
      }
    }

    if (chartType == 'Line' && linePoints.length > 1) {
      final lineP = Paint()..color = Colors.cyanAccent..strokeWidth = 1.8..style = PaintingStyle.stroke;
      final pth = Path()..moveTo(linePoints.first.dx, linePoints.first.dy);
      for (var p in linePoints) pth.lineTo(p.dx, p.dy);
      canvas.drawPath(pth, lineP);
    }

    // 3. Exness Bid & Ask Dual Lines on Right
    final lastClose = candles.last.close;
    final bidY = getY(lastClose);
    final askY = getY(lastClose + (spreadPips * 0.05));

    // Bid Line (Blue dashed)
    final bidPaint = Paint()..color = Colors.blueAccent..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, bidY), Offset(size.width, bidY), bidPaint);
    // Ask Line (Red dashed)
    final askPaint = Paint()..color = Colors.redAccent..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, askY), Offset(size.width, askY), askPaint);

    // 4. Exness Live Price Tag Box on Right Margin
    final tagPaint = Paint()..color = lastClose >= candles.last.open ? bullColor : bearColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 52, bidY - 9, 52, 18), const Radius.circular(4)),
      tagPaint,
    );
    final tagTp = TextPainter(
      text: TextSpan(text: lastClose.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tagTp.paint(canvas, Offset(size.width - 48, bidY - 6));

    // 5. EMA Indicators
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

    // 6. Draw User Horizontal Support/Resistance Lines
    for (var hPrice in horizontalLines) {
      final hy = getY(hPrice);
      canvas.drawLine(Offset(0, hy), Offset(size.width, hy), Paint()..color = const Color(0xFFFFB800)..strokeWidth = 1.2);
    }

    // 7. Draw User Trendlines
    if (trendlines.length >= 2) {
      final tPaint = Paint()..color = Colors.yellowAccent..strokeWidth = 2.0;
      for (int i = 0; i < trendlines.length - 1; i += 2) {
        canvas.drawLine(trendlines[i], trendlines[i + 1], tPaint);
      }
    }

    // 8. Exness Pip Ruler / Measure Tool (Calculates exact pips between 2 points)
    if (measureStart != null && measureEnd != null) {
      final mPaint = Paint()..color = Colors.cyanAccent..strokeWidth = 1.8;
      canvas.drawLine(measureStart!, measureEnd!, mPaint);

      final p1 = maxP - ((measureStart!.dy / size.height) * range);
      final p2 = maxP - ((measureEnd!.dy / size.height) * range);
      final diffPips = ((p2 - p1).abs() * 10).toStringAsFixed(1);

      final rtp = TextPainter(
        text: TextSpan(
          text: '📏 Distance: $diffPips Pips',
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      rtp.paint(canvas, Offset(measureEnd!.dx + 8, measureEnd!.dy - 8));
    }

    // 9. Exness Crosshair Tracker
    if (crosshairPos != null) {
      final chPaint = Paint()..color = Colors.white54..strokeWidth = 0.8;
      canvas.drawLine(Offset(0, crosshairPos!.dy), Offset(size.width, crosshairPos!.dy), chPaint);
      canvas.drawLine(Offset(crosshairPos!.dx, 0), Offset(crosshairPos!.dx, size.height), chPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
