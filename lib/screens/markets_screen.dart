import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../models/trade_signal.dart';
import '../services/market_data_service.dart';
import 'candle_chart_screen.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final MarketDataService _dataService = MarketDataService();
  bool _isLoading = true;
  String _selectedCategory = 'ALL';
  List<MarketPairInfo> _pairs = [];
  Map<String, List<Candle>> _cachedCandles = {};
  Timer? _refreshTimer;

  final List<Map<String, dynamic>> _allSymbols = [
    // 1. Direct Crypto 24/7 (BTC, ETH, SOL) - Top Priority
    {'sym': 'BTC', 'name': 'Bitcoin (Spot 24/7 Live)', 'cat': 'Crypto', 'forex': false},
    {'sym': 'ETH', 'name': 'Ethereum (Spot 24/7 Live)', 'cat': 'Crypto', 'forex': false},
    {'sym': 'SOL', 'name': 'Solana (Spot 24/7 Live)', 'cat': 'Crypto', 'forex': false},

    // 2. Commodities & Spot Gold 24/7
    {'sym': 'XAUUSD', 'name': 'Spot Gold (PAXG 1:1 Live)', 'cat': 'Commodity', 'forex': false},
    {'sym': 'USOIL', 'name': 'Crude Oil (WTI)', 'cat': 'Commodity', 'forex': true},
    {'sym': 'UKOIL', 'name': 'Brent Crude Oil', 'cat': 'Commodity', 'forex': true},
    {'sym': 'NGUSD', 'name': 'Natural Gas (NG)', 'cat': 'Commodity', 'forex': true},

    // 3. Forex Majors & Crosses
    {'sym': 'EURUSD', 'name': 'Euro / US Dollar', 'cat': 'Forex', 'forex': true},
    {'sym': 'GBPUSD', 'name': 'British Pound / US Dollar', 'cat': 'Forex', 'forex': true},
    {'sym': 'USDJPY', 'name': 'US Dollar / Japanese Yen', 'cat': 'Forex', 'forex': true},
    {'sym': 'GBPJPY', 'name': 'British Pound / Japanese Yen', 'cat': 'Forex', 'forex': true},
    {'sym': 'EURJPY', 'name': 'Euro / Japanese Yen', 'cat': 'Forex', 'forex': true},
    {'sym': 'AUDUSD', 'name': 'Australian Dollar / USD', 'cat': 'Forex', 'forex': true},
    {'sym': 'USDCAD', 'name': 'US Dollar / Canadian Dollar', 'cat': 'Forex', 'forex': true},

    // 4. Global Indices
    {'sym': 'US30', 'name': 'Dow Jones Industrial 30', 'cat': 'Indices', 'forex': true},
    {'sym': 'US500', 'name': 'S&P 500 Index', 'cat': 'Indices', 'forex': true},
    {'sym': 'US100', 'name': 'Nasdaq 100 Index', 'cat': 'Indices', 'forex': true},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMarketOverview();
    // 2-second rapid live tick for Crypto & Gold
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fastPriceSync());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isForexWeekend() {
    final now = DateTime.now().toUtc();
    if (now.weekday == DateTime.saturday) return true;
    if (now.weekday == DateTime.friday && now.hour >= 21) return true;
    if (now.weekday == DateTime.sunday && now.hour < 21) return true;
    return false;
  }

  Future<void> _fetchMarketOverview() async {
    setState(() => _isLoading = true);
    final isForexOpen = !_isForexWeekend();

    List<MarketPairInfo> updated = [];
    for (var s in _allSymbols) {
      final sym = s['sym'] as String;
      final name = s['name'] as String;
      final cat = s['cat'] as String;
      final isForex = s['forex'] as bool;
      final isOpen = isForex ? isForexOpen : true;

      try {
        final candles = await _dataService.fetchLiveCandles(sym, timeframe: '15m');
        if (candles.isNotEmpty) {
          _cachedCandles[sym] = candles;
          final current = candles.last.close;
          final first = candles.first.open;
          final changePct = first > 0 ? ((current - first) / first) * 100 : 0.0;
          double high = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
          double low = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);

          updated.add(MarketPairInfo(
            symbol: sym,
            displayName: name,
            category: cat,
            currentPrice: current,
            change24h: changePct,
            high24h: high,
            low24h: low,
            isMarketOpen: isOpen,
            source: cat == 'Crypto' || sym == 'XAUUSD' ? 'Binance 24/7' : 'Interbank Feed',
          ));
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _pairs = updated;
        _isLoading = false;
      });
    }
  }

  Future<void> _fastPriceSync() async {
    final isForexOpen = !_isForexWeekend();
    for (int i = 0; i < _pairs.length; i++) {
      final pair = _pairs[i];
      if (pair.category == 'Crypto' || pair.symbol == 'XAUUSD' || isForexOpen) {
        try {
          final instant = await _dataService.fetchInstantPrice(pair.symbol);
          if (instant != null && mounted) {
            setState(() {
              final oldP = _pairs[i];
              _pairs[i] = MarketPairInfo(
                symbol: oldP.symbol,
                displayName: oldP.displayName,
                category: oldP.category,
                currentPrice: instant,
                change24h: oldP.change24h,
                high24h: instant > oldP.high24h ? instant : oldP.high24h,
                low24h: instant < oldP.low24h ? instant : oldP.low24h,
                isMarketOpen: true,
                source: oldP.source,
              );
            });
          }
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'ALL'
        ? _pairs
        : _pairs.where((p) => p.category.toUpperCase() == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.candlestick_chart, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Live Markets & Charts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Colors.greenAccent, size: 14),
                Text(' LIVE 2s TICK', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMarketOverview,
        color: const Color(0xFFFFB800),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Tabs (CRYPTO first to easily check 24/7 running BTC)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'CRYPTO', 'COMMODITY', 'FOREX', 'INDICES'].map((cat) {
                    final isSel = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFFFB800) : const Color(0xFF131B2A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? const Color(0xFFFFB800) : const Color(0xFF1E293B)),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSel ? Colors.black : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 6),
              const Text(
                'TAP ANY PAIR TO OPEN TRADINGVIEW INTERACTIVE CHART',
                style: TextStyle(
                  color: Color(0xFFFFB800),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading && _pairs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Color(0xFFFFB800)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final pair = filtered[index];
                    final isPositive = pair.change24h >= 0;

                    return GestureDetector(
                      onTap: () {
                        final candles = _cachedCandles[pair.symbol] ?? [];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandleChartScreen(
                              symbol: pair.symbol,
                              displayName: pair.displayName,
                              initialCandles: candles,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  pair.symbol,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB800),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        pair.symbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: pair.isMarketOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          pair.isMarketOpen ? 'LIVE 24/7' : 'CLOSED',
                                          style: TextStyle(
                                            color: pair.isMarketOpen ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    pair.displayName,
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  pair.currentPrice > 1000
                                      ? '\$${pair.currentPrice.toStringAsFixed(2)}'
                                      : pair.currentPrice.toStringAsFixed(pair.symbol.contains('JPY') ? 3 : 5),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isPositive ? Colors.green : Colors.red).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${isPositive ? '+' : ''}${pair.change24h.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
