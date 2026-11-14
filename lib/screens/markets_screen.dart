import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../models/trade_signal.dart';
import '../services/market_data_service.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final MarketDataService _dataService = MarketDataService();
  bool _isLoading = true;
  List<MarketPairInfo> _pairs = [];

  @override
  void initState() {
    super.initState();
    _fetchMarketOverview();
  }

  bool _isForexWeekend() {
    final now = DateTime.now().toUtc();
    // Forex closes Friday 21:00 UTC and opens Sunday 21:00 UTC
    if (now.weekday == DateTime.saturday) return true;
    if (now.weekday == DateTime.friday && now.hour >= 21) return true;
    if (now.weekday == DateTime.sunday && now.hour < 21) return true;
    return false;
  }

  Future<void> _fetchMarketOverview() async {
    setState(() => _isLoading = true);
    final isForexOpen = !_isForexWeekend();

    List<MarketPairInfo> updated = [];
    final symbols = [
      {'sym': 'XAUUSD', 'name': 'Spot Gold (PAXG 1:1)', 'forex': false},
      {'sym': 'EURUSD', 'name': 'Euro / US Dollar', 'forex': true},
      {'sym': 'GBPUSD', 'name': 'British Pound / US Dollar', 'forex': true},
      {'sym': 'USDJPY', 'name': 'US Dollar / Japanese Yen', 'forex': true},
      {'sym': 'AUDUSD', 'name': 'Australian Dollar / US Dollar', 'forex': true},
      {'sym': 'USDCAD', 'name': 'US Dollar / Canadian Dollar', 'forex': true},
    ];

    for (var s in symbols) {
      final sym = s['sym'] as String;
      final name = s['name'] as String;
      final isForex = s['forex'] as bool;
      final isOpen = isForex ? isForexOpen : true; // Spot Gold via crypto is 24/7

      try {
        final candles = await _dataService.fetchCandles(sym, interval: '15m');
        if (candles.isNotEmpty) {
          final current = candles.last.close;
          final first = candles.first.open;
          final changePct = ((current - first) / first) * 100;
          double high = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
          double low = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);

          updated.add(MarketPairInfo(
            symbol: sym,
            displayName: name,
            currentPrice: current,
            change24h: changePct,
            high24h: high,
            low24h: low,
            isMarketOpen: isOpen,
            source: sym == 'XAUUSD' ? 'Binance 24/7' : 'Yahoo Live',
          ));
        }
      } catch (_) {
        // Fallback default info
      }
    }

    if (mounted) {
      setState(() {
        _pairs = updated;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final forexClosed = _isForexWeekend();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Text(
          'Live Markets & Watchlist',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFB800)),
            onPressed: _fetchMarketOverview,
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
              // Weekend Market Notification Banner
              if (forexClosed)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B1219),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.redAccent, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Forex Market Closed (Weekend)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Forex opens Sunday 21:00 UTC. Gold Spot (PAXG 1:1) operates 24/7.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🟢 Global Forex & Spot Gold Markets are LIVE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'TRACKED ASSETS',
                style: TextStyle(
                  color: Color(0xFFFFB800),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
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
                  itemCount: _pairs.length,
                  itemBuilder: (context, index) {
                    final pair = _pairs[index];
                    final isPositive = pair.change24h >= 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        children: [
                          // Pair Icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                pair.symbol.substring(0, 3),
                                style: const TextStyle(
                                  color: Color(0xFFFFB800),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Name & Source
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      pair.symbol == 'XAUUSD' ? 'XAU/USD' : '${pair.symbol.substring(0, 3)}/${pair.symbol.substring(3)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: pair.isMarketOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pair.isMarketOpen ? 'LIVE' : 'CLOSED',
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
                          // Price & Change
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                pair.symbol == 'XAUUSD'
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
                        ],
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
