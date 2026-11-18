import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/trade_signal.dart';
import '../models/app_models.dart';
import '../services/market_data_service.dart';
import '../services/institutional_engine.dart';
import 'markets_screen.dart';
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
          unselectedItemColor: Colors.grey[600],
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
              icon: Icon(Icons.show_chart),
              activeIcon: Icon(Icons.show_chart),
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

// ═══════════════════════════════════════════════════════════
//  SIGNALS HOME SCREEN (Active Signals + History Dashboard)
// ═══════════════════════════════════════════════════════════

class SignalsHomeScreen extends StatefulWidget {
  const SignalsHomeScreen({super.key});

  @override
  State<SignalsHomeScreen> createState() => _SignalsHomeScreenState();
}

class _SignalsHomeScreenState extends State<SignalsHomeScreen> {
  final MarketDataService _dataService = MarketDataService();
  List<TradeSignal> _activeSignals = [];
  List<Map<String, dynamic>> _signalHistory = [];
  bool _isScanning = false;
  Timer? _scanTimer;
  String _historyFilter = 'ALL'; // ALL, WIN, LOSS

  final List<String> _targetSymbols = ['XAUUSD', 'EURUSD', 'GBPUSD', 'USDJPY', 'GBPJPY', 'BTC', 'USOIL'];

  @override
  void initState() {
    super.initState();
    _loadSignalHistory();
    _scanMarket();
    _scanTimer = Timer.periodic(const Duration(seconds: 15), (_) => _scanMarket());
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }

  // BD Time check: 7:00 AM to 12:00 AM (midnight)
  bool _isWithinTradingHours() {
    final nowUtc = DateTime.now().toUtc();
    final bdTime = nowUtc.add(const Duration(hours: 6));
    return bdTime.hour >= 7; // 7 AM to 11:59 PM (essentially 7 AM to midnight)
  }

  DateTime _getBDTime() {
    return DateTime.now().toUtc().add(const Duration(hours: 6));
  }

  // ── Load signal history from storage ──
  Future<void> _loadSignalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('signal_history_v4');
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        if (mounted) {
          setState(() {
            _signalHistory = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
        }
      } catch (_) {}
    }
  }

  // ── Save signal history ──
  Future<void> _saveSignalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep only last 100 signals
    if (_signalHistory.length > 100) {
      _signalHistory = _signalHistory.sublist(_signalHistory.length - 100);
    }
    await prefs.setString('signal_history_v4', jsonEncode(_signalHistory));
  }

  // ── Track signal outcome ──
  void _trackSignalOutcome(TradeSignal signal) {
    // Check if this signal is already in history
    final exists = _signalHistory.any((h) =>
        h['symbol'] == signal.symbol &&
        h['signalTime'] == signal.signalTime);
    if (exists) return;

    // Add to history as ACTIVE
    _signalHistory.insert(0, {
      'symbol': signal.symbol,
      'action': signal.action,
      'winRatio': signal.winRatio,
      'entryPrice': signal.currentPrice,
      'stopLoss': signal.stopLoss,
      'takeProfit1': signal.takeProfit1,
      'takeProfit2': signal.takeProfit2,
      'riskReward': signal.riskReward,
      'signalTime': signal.signalTime,
      'outcome': 'ACTIVE',
      'pnlPips': 0.0,
      'exitPrice': null,
      'closeTime': null,
      'reasons': signal.reasons,
    });
    _saveSignalHistory();
  }

  // ── Check and update active signals in history ──
  Future<void> _updateActiveSignalOutcomes() async {
    bool changed = false;
    for (int i = 0; i < _signalHistory.length; i++) {
      final h = _signalHistory[i];
      if (h['outcome'] != 'ACTIVE') continue;

      // Check if signal is older than 3 hours → auto-close
      try {
        final signalTime = DateTime.parse(h['signalTime'] as String);
        final bdNow = _getBDTime();
        if (bdNow.difference(signalTime).inHours >= 3) {
          // Auto close — fetch current price
          final currentPrice = await _dataService.fetchInstantPrice(h['symbol'] as String);
          if (currentPrice != null) {
            double entry = (h['entryPrice'] as num).toDouble();
            double sl = (h['stopLoss'] as num).toDouble();
            double tp1 = (h['takeProfit1'] as num).toDouble();
            bool isBuy = (h['action'] as String).contains('BUY');
            double pnl = _calculatePnlPips(h['symbol'] as String, entry, currentPrice, isBuy);

            _signalHistory[i] = Map<String, dynamic>.from(h);
            _signalHistory[i]['exitPrice'] = currentPrice;
            _signalHistory[i]['closeTime'] = bdNow.toString().split('.').first;
            _signalHistory[i]['pnlPips'] = pnl;
            _signalHistory[i]['outcome'] = pnl >= 0 ? 'PROFIT (Auto-Close)' : 'LOSS (Auto-Close)';
            changed = true;
          }
          continue;
        }
      } catch (_) {}

      // Check TP/SL hit
      try {
        final currentPrice = await _dataService.fetchInstantPrice(h['symbol'] as String);
        if (currentPrice != null) {
          double entry = (h['entryPrice'] as num).toDouble();
          double sl = (h['stopLoss'] as num).toDouble();
          double tp1 = (h['takeProfit1'] as num).toDouble();
          bool isBuy = (h['action'] as String).contains('BUY');

          if (isBuy) {
            if (currentPrice >= tp1) {
              double pnl = _calculatePnlPips(h['symbol'] as String, entry, tp1, true);
              _signalHistory[i] = Map<String, dynamic>.from(h);
              _signalHistory[i]['exitPrice'] = tp1;
              _signalHistory[i]['closeTime'] = _getBDTime().toString().split('.').first;
              _signalHistory[i]['pnlPips'] = pnl;
              _signalHistory[i]['outcome'] = 'PROFIT (TP1)';
              changed = true;
            } else if (currentPrice <= sl) {
              double pnl = _calculatePnlPips(h['symbol'] as String, entry, sl, true);
              _signalHistory[i] = Map<String, dynamic>.from(h);
              _signalHistory[i]['exitPrice'] = sl;
              _signalHistory[i]['closeTime'] = _getBDTime().toString().split('.').first;
              _signalHistory[i]['pnlPips'] = pnl;
              _signalHistory[i]['outcome'] = 'LOSS (SL)';
              changed = true;
            }
          } else {
            if (currentPrice <= tp1) {
              double pnl = _calculatePnlPips(h['symbol'] as String, entry, tp1, false);
              _signalHistory[i] = Map<String, dynamic>.from(h);
              _signalHistory[i]['exitPrice'] = tp1;
              _signalHistory[i]['closeTime'] = _getBDTime().toString().split('.').first;
              _signalHistory[i]['pnlPips'] = pnl;
              _signalHistory[i]['outcome'] = 'PROFIT (TP1)';
              changed = true;
            } else if (currentPrice >= sl) {
              double pnl = _calculatePnlPips(h['symbol'] as String, entry, sl, false);
              _signalHistory[i] = Map<String, dynamic>.from(h);
              _signalHistory[i]['exitPrice'] = sl;
              _signalHistory[i]['closeTime'] = _getBDTime().toString().split('.').first;
              _signalHistory[i]['pnlPips'] = pnl;
              _signalHistory[i]['outcome'] = 'LOSS (SL)';
              changed = true;
            }
          }
        }
      } catch (_) {}
    }

    if (changed) {
      _saveSignalHistory();
      if (mounted) setState(() {});
    }
  }

  double _calculatePnlPips(String symbol, double entry, double exit, bool isBuy) {
    double diff = isBuy ? (exit - entry) : (entry - exit);
    if (symbol.contains('XAU')) return diff * 10;
    if (symbol.contains('JPY')) return diff * 100;
    if (symbol.contains('BTC') || symbol.contains('ETH')) return diff;
    if (symbol.contains('OIL')) return diff * 100;
    return diff * 10000; // Standard forex
  }

  // ── Scan Market for Signals ──
  Future<void> _scanMarket() async {
    if (_isScanning) return;
    if (mounted) setState(() => _isScanning = true);

    if (!_isWithinTradingHours()) {
      if (mounted) setState(() => _isScanning = false);
      return;
    }

    List<TradeSignal> foundSignals = [];

    for (final sym in _targetSymbols) {
      try {
        final candles = await _dataService.fetchLiveCandles(sym, timeframe: '15m');
        if (candles.length >= 20) {
          final signal = InstitutionalEngine.evaluate(symbol: sym, candles: candles);
          if (signal.action != 'WAIT') {
            foundSignals.add(signal);
            _trackSignalOutcome(signal);
          }
        }
      } catch (_) {}
    }

    // Also update outcomes of previously active signals
    await _updateActiveSignalOutcomes();

    if (mounted) {
      setState(() {
        _activeSignals = foundSignals;
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTradingWindow = _isWithinTradingHours();

    // Filter history
    List<Map<String, dynamic>> filteredHistory;
    if (_historyFilter == 'WIN') {
      filteredHistory = _signalHistory.where((h) => (h['outcome'] as String).contains('PROFIT')).toList();
    } else if (_historyFilter == 'LOSS') {
      filteredHistory = _signalHistory.where((h) => (h['outcome'] as String).contains('LOSS')).toList();
    } else {
      filteredHistory = _signalHistory;
    }

    // Stats
    int totalSignals = _signalHistory.where((h) => h['outcome'] != 'ACTIVE').length;
    int winSignals = _signalHistory.where((h) => (h['outcome'] as String).contains('PROFIT')).length;
    int lossSignals = _signalHistory.where((h) => (h['outcome'] as String).contains('LOSS')).length;
    String winRate = totalSignals > 0 ? '${((winSignals / totalSignals) * 100).toStringAsFixed(0)}%' : '-';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.auto_graph, color: Color(0xFFFFB800), size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ZAVRO AI',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 1.0),
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
            // ── Trading Session Banner ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF131B2A)]),
                borderRadius: BorderRadius.circular(14),
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
                          isTradingWindow ? 'ZAVRO LIVE SESSION ACTIVE' : 'MARKET REST (12:00 AM - 7:00 AM BD)',
                          style: const TextStyle(color: Color(0xFFFFB800), fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTradingWindow
                              ? 'সকাল ৭:০০ AM - রাত ১২:০০ AM • স্কাল্পিং ২-৩ ঘণ্টা'
                              : 'সিগন্যাল সকাল ৭:০০ AM BD সময়ে শুরু হবে।',
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'ACTIVE SIGNALS',
              style: TextStyle(color: Color(0xFFFFB800), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),

            // ── Active Signals or Empty State ──
            if (!isTradingWindow)
              _buildEmptyCard(
                Icons.bedtime_outlined,
                Colors.amber,
                'Session Paused (Night)',
                'Zavro AI রাত ১২:০০ AM থেকে সকাল ৭:০০ AM পর্যন্ত বিশ্রামে।\nসিগন্যাল সকাল ৭:০০ AM BD সময়ে শুরু হবে।',
              )
            else if (_activeSignals.isEmpty)
              _buildEmptyCard(
                Icons.radar,
                Colors.grey.shade400,
                'Scanning Market...',
                'মার্কেট স্ক্যান করা হচ্ছে। ৮৫%+ কনফ্লুয়েন্স ম্যাচ হলে সিগন্যাল আসবে।\nপ্রতি ১৫ সেকেন্ডে স্ক্যান হয়।',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _activeSignals.length,
                itemBuilder: (context, index) => _buildSignalCard(_activeSignals[index]),
              ),

            const SizedBox(height: 24),
            // ══════════════════════════════════════════
            //  SIGNAL HISTORY DASHBOARD
            // ══════════════════════════════════════════
            const Divider(color: Color(0xFF1E293B)),
            const SizedBox(height: 10),

            // Stats Summary Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF131B2A)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  _buildStatBox('Total', '$totalSignals', Colors.white),
                  Container(height: 30, width: 1, color: const Color(0xFF2E384D)),
                  _buildStatBox('Win', '$winSignals', Colors.greenAccent),
                  Container(height: 30, width: 1, color: const Color(0xFF2E384D)),
                  _buildStatBox('Loss', '$lossSignals', Colors.redAccent),
                  Container(height: 30, width: 1, color: const Color(0xFF2E384D)),
                  _buildStatBox('Win Rate', winRate, const Color(0xFFFFB800)),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // Filter Tabs
            Row(
              children: [
                _buildFilterTab('📊 All', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterTab('✅ Win', 'WIN'),
                const SizedBox(width: 8),
                _buildFilterTab('❌ Loss', 'LOSS'),
              ],
            ),

            const SizedBox(height: 12),

            if (filteredHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.history_toggle_off, color: Colors.grey, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _historyFilter == 'ALL' ? 'এখনো কোনো সিগন্যাল রেকর্ড নেই' : 'এই ক্যাটাগরিতে কোনো সিগন্যাল নেই',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredHistory.length > 20 ? 20 : filteredHistory.length,
                itemBuilder: (context, index) => _buildHistoryCard(filteredHistory[index]),
              ),
          ],
        ),
      ),
    );
  }

  // ── Signal Card Widget ──
  Widget _buildSignalCard(TradeSignal sig) {
    final isBuy = sig.action.contains('BUY');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBuy ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4),
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
                  Text(sig.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${sig.winRatio} WIN',
                  style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceCol('ENTRY', sig.entryZone, Colors.white),
              _buildPriceCol('STOP LOSS', sig.stopLoss.toString(), Colors.redAccent),
              _buildPriceCol('TARGET', sig.takeProfit1.toString(), Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1E293B)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⏱ ${sig.holdingTime}', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              Text('RRR: ${sig.riskReward}', style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          if (sig.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sig.reasons.take(2).join(' • '),
              style: TextStyle(color: Colors.grey[500], fontSize: 9, fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── History Card Widget ──
  Widget _buildHistoryCard(Map<String, dynamic> h) {
    String outcome = h['outcome'] ?? 'ACTIVE';
    bool isProfit = outcome.contains('PROFIT');
    bool isActive = outcome == 'ACTIVE';
    bool isBuy = (h['action'] as String? ?? '').contains('BUY');
    double pnl = (h['pnlPips'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFFB800).withOpacity(0.3)
              : isProfit
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isBuy ? Colors.green : Colors.red).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      h['action'] ?? '',
                      style: TextStyle(
                        color: isBuy ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    h['symbol'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFFB800).withOpacity(0.2)
                      : (isProfit ? Colors.green : Colors.red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive
                      ? '⏳ ACTIVE'
                      : '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(1)} pips',
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFFFB800)
                        : isProfit ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Entry: ${h['entryPrice']}  •  ${h['signalTime'] ?? ''}',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
          if (h['exitPrice'] != null)
            Text(
              'Exit: ${h['exitPrice']}  •  ${h['closeTime'] ?? ''}  •  $outcome',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(IconData icon, Color iconColor, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPriceCol(String label, String value, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String filter) {
    final isSel = _historyFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _historyFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFFFB800) : const Color(0xFF131B2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? const Color(0xFFFFB800) : const Color(0xFF1E293B)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.black : Colors.grey[400],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
