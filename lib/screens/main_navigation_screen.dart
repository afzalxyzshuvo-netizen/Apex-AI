import 'dart:async';
import 'package:flutter/material.dart';
import '../models/trade_signal.dart';
import '../services/market_data_service.dart';
import '../services/institutional_engine.dart';
import 'markets_screen.dart';
import 'history_analytics_screen.dart';
import 'news_screen.dart';
import 'capital_calculator_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainNavigationScreen({super.key, required this.onLogout});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const SignalsHomeScreen(),
      const MarketsScreen(),
      const NewsScreen(),
      const CapitalCalculatorScreen(),
      const HistoryAnalyticsScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131B2A),
          border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF131B2A),
          selectedItemColor: const Color(0xFFFFB800),
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 9),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Signals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.candlestick_chart_outlined),
              activeIcon: Icon(Icons.candlestick_chart),
              label: 'Markets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate),
              label: 'Capital',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class SignalsHomeScreen extends StatefulWidget {
  const SignalsHomeScreen({super.key});

  @override
  State<SignalsHomeScreen> createState() => _SignalsHomeScreenState();
}

class _SignalsHomeScreenState extends State<SignalsHomeScreen> {
  final MarketDataService _dataService = MarketDataService();
  List<TradeSignal> _activeSignals = [];
  bool _isScanning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scanMarket();
    // Ultra-fast 10-second scanner
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _scanMarket());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Check if current time is within BD Trading Window (8:00 AM to 11:00 PM)
  bool _isWithinBangladeshHours() {
    final nowUtc = DateTime.now().toUtc();
    final bdTime = nowUtc.add(const Duration(hours: 6)); // UTC+6
    return bdTime.hour >= 8 && bdTime.hour < 23;
  }

  Future<void> _scanMarket() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    // If outside 8 AM - 11 PM BD time, pause signals to protect sleep & low-liquidity slippage
    if (!_isWithinBangladeshHours()) {
      if (mounted) setState(() => _isScanning = false);
      return;
    }

    final targetSymbols = ['XAUUSD', 'EURUSD', 'GBPUSD', 'USDJPY', 'GBPJPY', 'USOIL', 'BTCUSD'];
    List<TradeSignal> foundSignals = [];

    for (final sym in targetSymbols) {
      try {
        final candles = await _dataService.fetchLiveCandles(sym, timeframe: '15m');
        if (candles.length >= 25) {
          final signal = InstitutionalEngine.evaluate(symbol: sym, candles: candles);
          if (signal.action != 'WAIT') {
            foundSignals.add(signal);
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _activeSignals = foundSignals;
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTradingWindow = _isWithinBangladeshHours();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.auto_graph, color: Color(0xFFFFB800), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ZAVRO AI',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB800)),
                  )
                : const Icon(Icons.refresh, color: Color(0xFFFFB800)),
            onPressed: _scanMarket,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Session & Window Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF131B2A)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTradingWindow ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTradingWindow ? 'ZAVRO LIVE SESSION ACTIVE' : 'MARKET REST HOURS (11:00 PM - 8:00 AM BD)',
                          style: const TextStyle(
                            color: Color(0xFFFFB800),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTradingWindow
                              ? 'Active Hours: 8:00 AM to 11:00 PM • Fast 2-3h Swings'
                              : 'Signals resume at 8:00 AM BD time to prevent low liquidity traps.',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            const Text(
              'INSTITUTIONAL HIGH-PROBABILITY SETUPS',
              style: TextStyle(
                color: Color(0xFFFFB800),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            if (!isTradingWindow)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.bedtime_outlined, size: 44, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      'Session Paused (Night Window)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Zavro AI is in overnight standby. All active charts & news are live.\nTrading signals reopen at 8:00 AM sharp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              )
            else if (_activeSignals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined, size: 44, color: Colors.grey[600]),
                    const SizedBox(height: 10),
                    const Text(
                      'Capital Protection Mode Active',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scanning 24/7 with 3s low latency.\nSignals trigger only when 85%+ confluences match for 2-3h target hits.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeSignals.length,
                itemBuilder: (context, index) {
                  final sig = _activeSignals[index];
                  final isBuy = sig.action.contains('BUY');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isBuy ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isBuy ? Colors.green : Colors.red).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sig.action,
                                    style: TextStyle(
                                      color: isBuy ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sig.symbol,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB800).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${sig.winRatio} WIN SCORE',
                                style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPriceCol('ENTRY ZONE', sig.entryZone),
                            _buildPriceCol('STOP LOSS', sig.stopLoss.toString(), isSl: true),
                            _buildPriceCol('TARGET (TP1)', sig.takeProfit1.toString(), isTp: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFF1E293B)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Holding: 2 - 3 Hours', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                            Text('RRR: ${sig.riskReward}', style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCol(String label, String value, {bool isSl = false, bool isTp = false}) {
    Color col = Colors.white;
    if (isSl) col = Colors.redAccent;
    if (isTp) col = Colors.greenAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }
}
