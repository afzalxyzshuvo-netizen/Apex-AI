import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trade_signal.dart';

class MarketDataService {
  static const Map<String, String> symbolMap = {
    'XAUUSD': 'PAXGUSDT',
    'EURUSD': 'EURUSD=X',
    'GBPUSD': 'GBPUSD=X',
    'USDJPY': 'JPY=X',
    'BTCUSD': 'BTCUSDT',
  };

  // Fetch real-time candles from Binance (Spot Gold 1:1) or Yahoo Interbank
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
      final res = await http.get(url).timeout(const Duration(seconds: 8));

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
      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$ticker?interval=$interval&range=5d');
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['chart']['result'][0];
        final List<dynamic> timestamps = result['timestamp'];
        final quotes = result['indicators']['quote'][0];

        List<Candle> candles = [];
        for (int i = 0; i < timestamps.length; i++) {
          final o = quotes['open'][i];
          final h = quotes['high'][i];
          final l = quotes['low'][i];
          final c = quotes['close'][i];
          final v = quotes['volume']?[i];

          if (o != null && h != null && l != null && c != null) {
            candles.add(Candle(
              time: DateTime.fromMillisecondsSinceEpoch((timestamps[i] as int) * 1000),
              open: (o as num).toDouble(),
              high: (h as num).toDouble(),
              low: (l as num).toDouble(),
              close: (c as num).toDouble(),
              volume: (v as num?)?.toDouble() ?? 0.0,
            ));
          }
        }
        return candles;
      }
    } catch (_) {}
    return [];
  }
}
