import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/market_data_service.dart';

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
  Map<String, double?> _prevPrices = {};
  Timer? _refreshTimer;

  final List<Map<String, dynamic>> _allSymbols = [
    {'sym': 'BTC', 'name': 'Bitcoin (Spot 24/7)', 'cat': 'Crypto', 'forex': false},
    {'sym': 'ETH', 'name': 'Ethereum (Spot 24/7)', 'cat': 'Crypto', 'forex': false},
    {'sym': 'SOL', 'name': 'Solana (Spot 24/7)', 'cat': 'Crypto', 'forex': false},
    {'sym': 'XAUUSD', 'name': 'Spot Gold (PAXG Live)', 'cat': 'Commodity', 'forex': false},
    {'sym': 'USOIL', 'name': 'Crude Oil (WTI)', 'cat': 'Commodity', 'forex': true},
    {'sym': 'UKOIL', 'name': 'Brent Crude Oil', 'cat': 'Commodity', 'forex': true},
    {'sym': 'NGUSD', 'name': 'Natural Gas (NG)', 'cat': 'Commodity', 'forex': true},
    {'sym': 'EURUSD', 'name': 'Euro / US Dollar', 'cat': 'Forex', 'forex': true},
    {'sym': 'GBPUSD', 'name': 'British Pound / US Dollar', 'cat': 'Forex', 'forex': true},
    {'sym': 'USDJPY', 'name': 'US Dollar / Japanese Yen', 'cat': 'Forex', 'forex': true},
    {'sym': 'GBPJPY', 'name': 'British Pound / Japanese Yen', 'cat': 'Forex', 'forex': true},
    {'sym': 'EURJPY', 'name': 'Euro / Japanese Yen', 'cat': 'Forex', 'forex': true},
    {'sym': 'AUDUSD', 'name': 'Australian Dollar / USD', 'cat': 'Forex', 'forex': true},
    {'sym': 'USDCAD', 'name': 'US Dollar / Canadian Dollar', 'cat': 'Forex', 'forex': true},
    {'sym': 'US30', 'name': 'Dow Jones Industrial 30', 'cat': 'Indices', 'forex': true},
    {'sym': 'US500', 'name': 'S&P 500 Index', 'cat': 'Indices', 'forex': true},
    {'sym': 'US100', 'name': 'Nasdaq 100 Index', 'cat': 'Indices', 'forex': true},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMarketOverview();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fastPriceSync());
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
              _prevPrices[pair.symbol] = pair.currentPrice;
              _pairs[i] = MarketPairInfo(
                symbol: pair.symbol,
                displayName: pair.displayName,
                category: pair.category,
                currentPrice: instant,
                change24h: pair.change24h,
                high24h: instant > pair.high24h ? instant : pair.high24h,
                low24h: instant < pair.low24h ? instant : pair.low24h,
                isMarketOpen: true,
                source: pair.source,
              );
            });
          }
        } catch (_) {}
      }
    }
  }

  Widget _getMarketIcon(String symbol) {
    IconData? icon;
    String? text;
    Color bgColor;
    Color textColor = Colors.white;

    switch (symbol) {
      case 'BTC':
        text = '₿';
        bgColor = const Color(0xFFF7931A);
        break;
      case 'ETH':
        text = 'Ξ';
        bgColor = const Color(0xFF627EEA);
        break;
      case 'SOL':
        text = '◎';
        bgColor = const Color(0xFF00FFA3);
        textColor = Colors.black;
        break;
      case 'XAUUSD':
        icon = Icons.workspace_premium;
        bgColor = const Color(0xFFFFD700);
        textColor = Colors.black;
        break;
      case 'EURUSD':
        text = '€/\$';
        bgColor = const Color(0xFF1565C0);
        break;
      case 'GBPUSD':
        text = '£/\$';
        bgColor = const Color(0xFF283593);
        break;
      case 'USDJPY':
        text = '¥/\$';
        bgColor = const Color(0xFFD32F2F);
        break;
      case 'GBPJPY':
        text = '£/¥';
        bgColor = const Color(0xFFC2185B);
        break;
      case 'EURJPY':
        text = '€/¥';
        bgColor = const Color(0xFF00838F);
        break;
      case 'AUDUSD':
        text = 'A/\$';
        bgColor = const Color(0xFF2E7D32);
        break;
      case 'USDCAD':
        text = '\$/C';
        bgColor = const Color(0xFF689F38);
        break;
      case 'USOIL':
        icon = Icons.local_gas_station;
        bgColor = const Color(0xFF5D4037);
        break;
      case 'UKOIL':
        icon = Icons.local_gas_station;
        bgColor = const Color(0xFF3E2723);
        break;
      case 'NGUSD':
        icon = Icons.local_fire_department;
        bgColor = const Color(0xFFE65100);
        break;
      case 'US30':
        text = 'DJ';
        bgColor = const Color(0xFF1A237E);
        break;
      case 'US500':
        text = 'SP';
        bgColor = const Color(0xFF0D47A1);
        break;
      case 'US100':
        text = 'NQ';
        bgColor = const Color(0xFF4A148C);
        break;
      default:
        text = symbol.substring(0, min(2, symbol.length));
        bgColor = const Color(0xFF37474F);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: textColor, size: 22)
            : Text(
                text ?? '?',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: text != null && text.length > 2 ? 10 : 16,
                ),
              ),
      ),
    );
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
            Icon(Icons.show_chart, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Live Markets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
              // Category Tabs
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
                    final prev = _prevPrices[pair.symbol];
                    final priceUp = prev != null && pair.currentPrice > prev;
                    final priceDown = prev != null && pair.currentPrice < prev;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: priceUp
                              ? Colors.green.withOpacity(0.3)
                              : priceDown
                                  ? Colors.red.withOpacity(0.3)
                                  : const Color(0xFF1E293B),
                        ),
                      ),
                      child: Row(
                        children: [
                          _getMarketIcon(pair.symbol),
                          const SizedBox(width: 12),
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
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: pair.isMarketOpen ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        pair.isMarketOpen ? 'LIVE' : 'CLOSED',
                                        style: TextStyle(
                                          color: pair.isMarketOpen ? Colors.greenAccent : Colors.redAccent,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pair.displayName,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (priceUp) const Icon(Icons.arrow_drop_up, color: Colors.greenAccent, size: 20),
                                  if (priceDown) const Icon(Icons.arrow_drop_down, color: Colors.redAccent, size: 20),
                                  Text(
                                    _formatPrice(pair.symbol, pair.currentPrice),
                                    style: TextStyle(
                                      color: priceUp ? Colors.greenAccent : priceDown ? Colors.redAccent : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${isPositive ? '+' : ''}${pair.change24h.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isPositive ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 10,
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

  String _formatPrice(String symbol, double price) {
    if (price > 1000) return '\$${price.toStringAsFixed(2)}';
    if (symbol.contains('JPY')) return price.toStringAsFixed(3);
    return price.toStringAsFixed(5);
  }
}
