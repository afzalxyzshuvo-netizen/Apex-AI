import 'dart:async';
import 'package:flutter/material.dart';
import '../models/trade_signal.dart';
import '../services/market_data_service.dart';
import '../services/institutional_engine.dart';
import 'markets_screen.dart';
import 'history_analytics_screen.dart';
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'AI Signals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'Markets',
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
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _scanMarket());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _scanMarket() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    final symbols = ['XAUUSD', 'EURUSD', 'GBPUSD', 'USDJPY'];
    List<TradeSignal> foundSignals = [];

    for (final sym in symbols) {
      try {
        final candles = await _dataService.fetchLiveCandles(sym, timeframe: '15m');
        if (candles.length >= 25) {
          final signal = InstitutionalEngine.analyzeSignal(candles, sym);
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
              'Apex AI Signals',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.8),
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
            // Header Banner
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INSTITUTIONAL AI SCANNER ACTIVE',
                          style: TextStyle(
                            color: Color(0xFFFFB800),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SMC • ICT • Order Blocks • FVG • Liquidity Pools',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'HIGH CONFLUENCE LIVE OPPORTUNITIES',
              style: TextStyle(
                color: Color(0xFFFFB800),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            if (_activeSignals.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.shield_outlined, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 12),
                    const Text(
                      'Capital Protection Mode Active',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No trades match the 85%+ institutional confluence filter right now.\nScanning 24/7 every 45s for high-probability setups.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.4),
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
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isBuy ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isBuy ? Colors.green : Colors.red).withOpacity(0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isBuy ? Colors.green : Colors.red).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sig.action,
                                    style: TextStyle(
                                      color: isBuy ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sig.symbol == 'XAUUSD' ? 'XAU/USD (Gold)' : sig.symbol,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB800).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${sig.winRatio} WIN SCORE',
                                style: const TextStyle(
                                  color: Color(0xFFFFB800),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPriceCol('ENTRY ZONE', sig.entryZone),
                            _buildPriceCol('STOP LOSS', sig.stopLoss.toString(), isSl: true),
                            _buildPriceCol('TARGET (TP1)', sig.takeProfit1.toString(), isTp: true),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFF1E293B)),
                        const SizedBox(height: 6),
                        Text(
                          'Confluences: ${sig.reasons.join(" • ")}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
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
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}
