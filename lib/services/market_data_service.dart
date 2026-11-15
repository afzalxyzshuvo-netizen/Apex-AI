import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trade_signal.dart';

class MarketDataService {
  // Direct High-Frequency 24/7 Spot Endpoints (Binance) & Yahoo Finance
  static const Map<String, String> symbolMap = {
    // 24/7 Crypto & Gold Spot
    'BTC': 'BTCUSDT',
    'ETH': 'ETHUSDT',
    'SOL': 'SOLUSDT',
    'XAUUSD': 'PAXGUSDT', // 1:1 Physical Gold Spot
    
    // Forex
    'EURUSD': 'EURUSD=X',
    'GBPUSD': 'GBPUSD=X',
    'USDJPY': 'JPY=X',
    'GBPJPY': 'GBPJPY=X',
    'EURJPY': 'EURJPY=X',
    'AUDUSD': 'AUDUSD=X',
    'USDCAD': 'CAD=X',
    
    // Commodities & World Indices
    'USOIL': 'CL=F',
    'UKOIL': 'BZ=F',
    'NGUSD': 'NG=F',
    'US30': '^DJI',
    'US500': '^GSPC',
    'US100': '^IXIC',
  };

  static String toBinanceInterval(String tf) {
    switch (tf) {
      case '1m': return '1m';
      case '5m': return '5m';
      case '10m': return '15m';
      case '15m': return '15m';
      case '30m': return '30m';
      case '40m': return '1h';
      case '45m': return '1h';
      case '1h': return '1h';
      case '1d': return '1d';
      default: return '15m';
    }
  }

  // Ultra-Fast Live Price Ticker (Instant 0 to 1 sec response from Binance)
  Future<double?> fetchInstantPrice(String symbol) async {
    String resolved = symbolMap[symbol] ?? symbol;
    if (symbol == 'BTC') resolved = 'BTCUSDT';
    if (symbol == 'ETH') resolved = 'ETHUSDT';
    if (symbol == 'SOL') resolved = 'SOLUSDT';

    if (resolved.endsWith('USDT')) {
      try {
        final url = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$resolved');
        final res = await http.get(url).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return double.tryParse(data['price'].toString());
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<Candle>> fetchLiveCandles(String symbol, {String timeframe = '15m'}) async {
    String resolved = symbolMap[symbol] ?? symbol;
    if (symbol == 'BTC') resolved = 'BTCUSDT';
    if (symbol == 'ETH') resolved = 'ETHUSDT';
    if (symbol == 'SOL') resolved = 'SOLUSDT';

    if (resolved.endsWith('USDT')) {
      return await _fetchBinanceKlines(resolved, toBinanceInterval(timeframe));
    } else {
      return await _fetchYahooChart(resolved, timeframe);
    }
  }

  Future<List<Candle>> _fetchBinanceKlines(String ticker, String interval) async {
    try {
      final url = Uri.parse('https://api.binance.com/api/v3/klines?symbol=$ticker&interval=$interval&limit=80');
      final res = await http.get(url).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((k) {
          final dt = DateTime.fromMillisecondsSinceEpoch(k[0] as int);
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
      if (interval == '1m' || interval == '5m') { range = '1d'; yInterval = interval; }
      else if (interval == '1h') { range = '5d'; yInterval = '60m'; }
      else if (interval == '1d') { range = '1mo'; yInterval = '1d'; }

      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker?range=$range&interval=$yInterval');
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 3));

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
