import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trade_signal.dart';

class MarketDataService {
  // Mapping symbols to high-frequency live endpoints
  static const Map<String, String> symbolMap = {
    // Crypto & 24/7 Spot
    'XAUUSD': 'PAXGUSDT',
    'BTCUSD': 'BTCUSDT',
    'ETHUSD': 'ETHUSDT',
    
    // Forex Majors & Crosses
    'EURUSD': 'EURUSD=X',
    'GBPUSD': 'GBPUSD=X',
    'USDJPY': 'JPY=X',
    'GBPJPY': 'GBPJPY=X',
    'EURJPY': 'EURJPY=X',
    'AUDUSD': 'AUDUSD=X',
    'USDCAD': 'CAD=X',
    
    // Commodities
    'USOIL': 'CL=F',    // WTI Crude Oil
    'UKOIL': 'BZ=F',    // Brent Crude Oil
    'NGUSD': 'NG=F',    // Natural Gas
    
    // Major World Indices
    'US30': '^DJI',     // Dow Jones 30
    'US500': '^GSPC',   // S&P 500
    'US100': '^IXIC',   // Nasdaq 100
  };

  // Ultra-fast fetcher (Binance 3-5 sec live response, Yahoo fast charts)
  Future<List<Candle>> fetchLiveCandles(String symbol, {String timeframe = '15m'}) async {
    String resolved = symbolMap[symbol] ?? symbol;

    if (resolved.endsWith('USDT')) {
      return await _fetchBinanceKlines(resolved, timeframe);
    } else {
      return await _fetchYahooChart(resolved, timeframe);
    }
  }

  Future<List<Candle>> _fetchBinanceKlines(String ticker, String interval) async {
    try {
      final url = Uri.parse('https://api.binance.com/api/v3/klines?symbol=$ticker&interval=$interval&limit=60');
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((k) {
          final dt = DateTime.fromMillisecondsSinceEpoch(k[0]);
          return Candle(
            time: dt,
            open: double.tryParse(k[1].toString()) ?? 0.0,
            high: double.tryParse(k[2].toString()) ?? 0.0,
            low: double.tryParse(k[3].toString()) ?? 0.0,
            close: double.tryParse(k[4].toString()) ?? 0.0,
            volume: double.tryParse(k[5].toString()) ?? 0.0,
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Candle>> _fetchYahooChart(String ticker, String interval) async {
    try {
      String range = '1d';
      String yInterval = '15m';
      if (interval == '1h') { range = '5d'; yInterval = '60m'; }
      if (interval == '1d') { range = '1mo'; yInterval = '1d'; }

      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker?range=$range&interval=$yInterval');
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['chart']['result'][0];
        final timestamps = result['timestamp'] as List<dynamic>;
        final quote = result['indicators']['quote'][0];

        final opens = quote['open'] as List<dynamic>;
        final highs = quote['high'] as List<dynamic>;
        final lows = quote['low'] as List<dynamic>;
        final closes = quote['close'] as List<dynamic>;
        final volumes = quote['volume'] as List<dynamic>?;

        List<Candle> candles = [];
        for (int i = 0; i < timestamps.length; i++) {
          if (opens[i] != null && closes[i] != null && highs[i] != null && lows[i] != null) {
            candles.add(Candle(
              time: DateTime.fromMillisecondsSinceEpoch((timestamps[i] as int) * 1000),
              open: (opens[i] as num).toDouble(),
              high: (highs[i] as num).toDouble(),
              low: (lows[i] as num).toDouble(),
              close: (closes[i] as num).toDouble(),
              volume: (volumes != null && volumes[i] != null) ? (volumes[i] as num).toDouble() : 0.0,
            ));
          }
        }
        return candles;
      }
    } catch (_) {}
    return [];
  }
}
