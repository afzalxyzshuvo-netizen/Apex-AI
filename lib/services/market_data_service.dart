import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trade_signal.dart';

class MarketDataService {
  static const Map<String, String> symbolMap = {
    'BTC': 'BTCUSDT',
    'ETH': 'ETHUSDT',
    'SOL': 'SOLUSDT',
    'XAUUSD': 'PAXGUSDT',
    'EURUSD': 'EURUSD=X',
    'GBPUSD': 'GBPUSD=X',
    'USDJPY': 'JPY=X',
    'GBPJPY': 'GBPJPY=X',
    'EURJPY': 'EURJPY=X',
    'AUDUSD': 'AUDUSD=X',
    'USDCAD': 'CAD=X',
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
      case '15m': return '15m';
      case '30m': return '30m';
      case '1h': return '1h';
      case '4h': return '4h';
      case '1d': return '1d';
      default: return '15m';
    }
  }

  bool _isBinancePair(String symbol) {
    String resolved = symbolMap[symbol] ?? symbol;
    return resolved.endsWith('USDT');
  }

  String _resolve(String symbol) {
    if (symbol == 'BTC') return 'BTCUSDT';
    if (symbol == 'ETH') return 'ETHUSDT';
    if (symbol == 'SOL') return 'SOLUSDT';
    return symbolMap[symbol] ?? symbol;
  }

  // ── Instant Price (sub-second for Binance) ──
  Future<double?> fetchInstantPrice(String symbol) async {
    String resolved = _resolve(symbol);

    if (resolved.endsWith('USDT')) {
      return await _binancePrice(resolved);
    } else {
      // Yahoo Finance spot price
      return await _yahooSpotPrice(resolved);
    }
  }

  Future<double?> _binancePrice(String ticker) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final url = Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$ticker');
        final res = await http.get(url).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return double.tryParse(data['price'].toString());
        }
      } catch (_) {}
      if (attempt == 0) await Future.delayed(const Duration(milliseconds: 400));
    }
    return null;
  }

  Future<double?> _yahooSpotPrice(String ticker) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker?range=1d&interval=1m');
        final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final result = data['chart']['result'][0];
          final quote = result['indicators']['quote'][0];
          final closes = quote['close'] as List<dynamic>;
          for (int i = closes.length - 1; i >= 0; i--) {
            if (closes[i] != null) return (closes[i] as num).toDouble();
          }
        }
      } catch (_) {}
      if (attempt == 0) await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  // ── Candle Data ──
  Future<List<Candle>> fetchLiveCandles(String symbol, {String timeframe = '15m'}) async {
    String resolved = _resolve(symbol);

    if (resolved.endsWith('USDT')) {
      return await _fetchBinanceKlines(resolved, toBinanceInterval(timeframe));
    } else {
      return await _fetchYahooChart(resolved, timeframe);
    }
  }

  Future<List<Candle>> _fetchBinanceKlines(String ticker, String interval) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final url = Uri.parse('https://api.binance.com/api/v3/klines?symbol=$ticker&interval=$interval&limit=100');
        final res = await http.get(url).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final List<dynamic> list = jsonDecode(res.body);
          return list.map((k) {
            return Candle(
              time: DateTime.fromMillisecondsSinceEpoch(k[0] as int),
              open: double.tryParse(k[1].toString()) ?? 0.0,
              high: double.tryParse(k[2].toString()) ?? 0.0,
              low: double.tryParse(k[3].toString()) ?? 0.0,
              close: double.tryParse(k[4].toString()) ?? 0.0,
              volume: double.tryParse(k[5].toString()) ?? 0.0,
            );
          }).toList();
        }
      } catch (_) {}
      if (attempt == 0) await Future.delayed(const Duration(milliseconds: 500));
    }
    return [];
  }

  Future<List<Candle>> _fetchYahooChart(String ticker, String interval) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        String range = '1d';
        String yInterval = '15m';
        if (interval == '1m' || interval == '5m') { range = '1d'; yInterval = interval; }
        else if (interval == '15m' || interval == '30m') { range = '5d'; yInterval = interval; }
        else if (interval == '1h') { range = '5d'; yInterval = '60m'; }
        else if (interval == '4h') { range = '1mo'; yInterval = '60m'; }
        else if (interval == '1d') { range = '3mo'; yInterval = '1d'; }

        final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker?range=$range&interval=$yInterval');
        final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final result = data['chart']['result'][0];
          final timestamps = result['timestamp'] as List<dynamic>?;
          if (timestamps == null || timestamps.isEmpty) return [];
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
                volume: (volumes != null && i < volumes.length && volumes[i] != null) ? (volumes[i] as num).toDouble() : 0.0,
              ));
            }
          }
          return candles;
        }
      } catch (_) {}
      if (attempt == 0) await Future.delayed(const Duration(milliseconds: 500));
    }
    return [];
  }

  // ── Multi-Timeframe Fetch (for deeper analysis) ──
  Future<Map<String, List<Candle>>> fetchMultiTimeframeCandles(String symbol) async {
    final results = await Future.wait([
      fetchLiveCandles(symbol, timeframe: '5m'),
      fetchLiveCandles(symbol, timeframe: '15m'),
    ]);
    return {
      '5m': results[0],
      '15m': results[1],
    };
  }
}
