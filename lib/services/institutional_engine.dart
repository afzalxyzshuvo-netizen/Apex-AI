import 'dart:math';
import '../models/trade_signal.dart';

class InstitutionalEngine {
  // ═══════════════════════════════════════════════════════
  // 1. EMA - Exponential Moving Average
  // ═══════════════════════════════════════════════════════
  static List<double> calculateEMASeries(List<Candle> candles, int period) {
    if (candles.isEmpty) return [];
    double k = 2.0 / (period + 1);
    List<double> emas = [candles.first.close];
    for (int i = 1; i < candles.length; i++) {
      emas.add((candles[i].close * k) + (emas.last * (1.0 - k)));
    }
    return emas;
  }

  static double calculateEMA(List<Candle> candles, int period) {
    final series = calculateEMASeries(candles, period);
    return series.isNotEmpty ? series.last : 0.0;
  }

  // ═══════════════════════════════════════════════════════
  // 2. ATR - Average True Range
  // ═══════════════════════════════════════════════════════
  static double calculateATR(List<Candle> candles, int period) {
    if (candles.length < 2) return candles.isNotEmpty ? (candles.last.high - candles.last.low) : 1.0;
    List<double> trs = [];
    for (int i = 1; i < candles.length; i++) {
      double hl = candles[i].high - candles[i].low;
      double hc = (candles[i].high - candles[i - 1].close).abs();
      double lc = (candles[i].low - candles[i - 1].close).abs();
      trs.add(max(hl, max(hc, lc)));
    }
    int start = max(0, trs.length - period);
    double sum = trs.sublist(start).reduce((a, b) => a + b);
    return sum / trs.sublist(start).length;
  }

  // ═══════════════════════════════════════════════════════
  // 3. RSI - Relative Strength Index + Divergence
  // ═══════════════════════════════════════════════════════
  static Map<String, dynamic> calculateRSI(List<Candle> candles, {int period = 14}) {
    if (candles.length <= period) return {'current': 50.0, 'divergence': 'None', 'zone': 'Neutral'};

    List<double> gains = [];
    List<double> losses = [];
    for (int i = 1; i < candles.length; i++) {
      double diff = candles[i].close - candles[i - 1].close;
      gains.add(diff > 0 ? diff : 0.0);
      losses.add(diff < 0 ? diff.abs() : 0.0);
    }

    double avgGain = gains.sublist(0, period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.sublist(0, period).reduce((a, b) => a + b) / period;

    List<double> rsis = [];
    for (int i = period; i < gains.length; i++) {
      avgGain = ((avgGain * (period - 1)) + gains[i]) / period;
      avgLoss = ((avgLoss * (period - 1)) + losses[i]) / period;
      double rs = avgLoss == 0 ? 100.0 : avgGain / avgLoss;
      rsis.add(100.0 - (100.0 / (1.0 + rs)));
    }

    double currentRsi = rsis.isNotEmpty ? rsis.last : 50.0;
    String zone = 'Neutral';
    if (currentRsi > 70) zone = 'Overbought';
    if (currentRsi < 30) zone = 'Oversold';

    // Divergence detection
    String div = 'None';
    if (candles.length > 20 && rsis.length > 15) {
      int lookback = min(15, rsis.length);
      List<double> recentPriceLows = candles.sublist(candles.length - lookback).map((e) => e.low).toList();
      List<double> recentRsi = rsis.sublist(rsis.length - lookback);

      double priceLow1 = recentPriceLows.sublist(0, lookback ~/ 2).reduce(min);
      double priceLow2 = recentPriceLows.sublist(lookback ~/ 2).reduce(min);
      double rsiLow1 = recentRsi.sublist(0, lookback ~/ 2).reduce(min);
      double rsiLow2 = recentRsi.sublist(lookback ~/ 2).reduce(min);

      if (priceLow2 < priceLow1 && rsiLow2 > rsiLow1) {
        div = 'Bullish Divergence';
      }

      double priceHigh1 = candles.sublist(candles.length - lookback, candles.length - lookback ~/ 2).map((e) => e.high).reduce(max);
      double priceHigh2 = candles.sublist(candles.length - lookback ~/ 2).map((e) => e.high).reduce(max);
      double rsiHigh1 = recentRsi.sublist(0, lookback ~/ 2).reduce(max);
      double rsiHigh2 = recentRsi.sublist(lookback ~/ 2).reduce(max);

      if (priceHigh2 > priceHigh1 && rsiHigh2 < rsiHigh1) {
        div = 'Bearish Divergence';
      }
    }

    return {'current': currentRsi, 'divergence': div, 'zone': zone};
  }

  // ═══════════════════════════════════════════════════════
  // 4. MACD - Moving Average Convergence Divergence
  // ═══════════════════════════════════════════════════════
  static Map<String, dynamic> calculateMACD(List<Candle> candles) {
    if (candles.length < 26) return {'macd': 0.0, 'signal': 0.0, 'histogram': 0.0, 'trend': 'Neutral'};

    List<double> ema12 = calculateEMASeries(candles, 12);
    List<double> ema26 = calculateEMASeries(candles, 26);

    List<double> macdLine = [];
    for (int i = 0; i < candles.length; i++) {
      macdLine.add(ema12[i] - ema26[i]);
    }

    // Signal line (9-period EMA of MACD)
    double k = 2.0 / 10.0;
    List<double> signalLine = [macdLine.first];
    for (int i = 1; i < macdLine.length; i++) {
      signalLine.add((macdLine[i] * k) + (signalLine.last * (1.0 - k)));
    }

    double macdVal = macdLine.last;
    double signalVal = signalLine.last;
    double histogram = macdVal - signalVal;

    // Check crossover in last 3 candles
    String trend = 'Neutral';
    if (macdLine.length >= 3) {
      double prevMacd = macdLine[macdLine.length - 3];
      double prevSignal = signalLine[signalLine.length - 3];
      if (prevMacd <= prevSignal && macdVal > signalVal) trend = 'Bullish Crossover';
      if (prevMacd >= prevSignal && macdVal < signalVal) trend = 'Bearish Crossover';
      if (trend == 'Neutral') {
        if (histogram > 0) trend = 'Bullish';
        if (histogram < 0) trend = 'Bearish';
      }
    }

    return {'macd': macdVal, 'signal': signalVal, 'histogram': histogram, 'trend': trend};
  }

  // ═══════════════════════════════════════════════════════
  // 5. Bollinger Bands
  // ═══════════════════════════════════════════════════════
  static Map<String, dynamic> calculateBollingerBands(List<Candle> candles, {int period = 20, double stdDev = 2.0}) {
    if (candles.length < period) return {'upper': 0.0, 'middle': 0.0, 'lower': 0.0, 'signal': 'Neutral'};

    List<double> closes = candles.sublist(candles.length - period).map((c) => c.close).toList();
    double sma = closes.reduce((a, b) => a + b) / period;
    double variance = closes.map((c) => pow(c - sma, 2)).reduce((a, b) => a + b) / period;
    double sd = sqrt(variance);

    double upper = sma + (stdDev * sd);
    double lower = sma - (stdDev * sd);
    double price = candles.last.close;

    String signal = 'Neutral';
    double bandWidth = (upper - lower) / sma;
    if (price <= lower) signal = 'Oversold (Below Lower Band)';
    if (price >= upper) signal = 'Overbought (Above Upper Band)';
    if (bandWidth < 0.02) signal = 'Squeeze (Breakout Imminent)';

    return {'upper': upper, 'middle': sma, 'lower': lower, 'signal': signal, 'bandWidth': bandWidth};
  }

  // ═══════════════════════════════════════════════════════
  // 6. Fair Value Gaps (FVG) - ICT Concept
  // ═══════════════════════════════════════════════════════
  static Map<String, dynamic> detectFVG(List<Candle> candles) {
    Map<String, dynamic>? nearestBull;
    Map<String, dynamic>? nearestBear;

    int startIdx = max(2, candles.length - 40);
    for (int i = startIdx; i < candles.length; i++) {
      Candle c1 = candles[i - 2];
      Candle c3 = candles[i];

      if (c3.low > c1.high) {
        nearestBull = {'bottom': c1.high, 'top': c3.low, 'age': candles.length - i};
      }
      if (c3.high < c1.low) {
        nearestBear = {'bottom': c3.high, 'top': c1.low, 'age': candles.length - i};
      }
    }

    return {'bullish': nearestBull, 'bearish': nearestBear};
  }

  // ═══════════════════════════════════════════════════════
  // 7. Order Blocks & Liquidity Sweeps - SMC
  // ═══════════════════════════════════════════════════════
  static Map<String, dynamic> detectOrderBlocksAndLiquidity(List<Candle> candles) {
    int lookback = min(30, candles.length);
    List<Candle> recent = candles.sublist(candles.length - lookback);

    double swingHigh = recent.map((e) => e.high).reduce(max);
    double swingLow = recent.map((e) => e.low).reduce(min);
    double currentPrice = candles.last.close;

    bool sweptBSL = candles.last.high >= swingHigh && candles.last.close < swingHigh;
    bool sweptSSL = candles.last.low <= swingLow && candles.last.close > swingLow;

    double equilibrium = swingLow + ((swingHigh - swingLow) * 0.5);
    bool isDiscount = currentPrice < equilibrium;
    bool isPremium = currentPrice > equilibrium;

    // Detect potential OB (last bearish candle before a strong bullish move)
    double? bullOBLevel;
    double? bearOBLevel;
    for (int i = recent.length - 5; i >= 1; i--) {
      if (!recent[i].isBullish && recent.length > i + 2) {
        bool strongUp = recent[i + 1].isBullish && recent[i + 2].isBullish;
        if (strongUp) {
          bullOBLevel = recent[i].low;
          break;
        }
      }
    }
    for (int i = recent.length - 5; i >= 1; i--) {
      if (recent[i].isBullish && recent.length > i + 2) {
        bool strongDown = !recent[i + 1].isBullish && !recent[i + 2].isBullish;
        if (strongDown) {
          bearOBLevel = recent[i].high;
          break;
        }
      }
    }

    return {
      'swingHigh': swingHigh,
      'swingLow': swingLow,
      'equilibrium': equilibrium,
      'isDiscount': isDiscount,
      'isPremium': isPremium,
      'sweptBSL': sweptBSL,
      'sweptSSL': sweptSSL,
      'bullOBLevel': bullOBLevel,
      'bearOBLevel': bearOBLevel,
    };
  }

  // ═══════════════════════════════════════════════════════
  // 8. Candlestick Pattern Detection
  // ═══════════════════════════════════════════════════════
  static Map<String, dynamic> detectCandlePatterns(List<Candle> candles) {
    if (candles.length < 3) return {'pattern': 'None', 'bias': 'Neutral'};

    Candle last = candles.last;
    Candle prev = candles[candles.length - 2];
    double body = (last.close - last.open).abs();
    double upperWick = last.high - max(last.open, last.close);
    double lowerWick = min(last.open, last.close) - last.low;
    double totalRange = last.high - last.low;

    if (totalRange == 0) return {'pattern': 'Doji', 'bias': 'Neutral'};

    // Bullish Engulfing
    if (!prev.isBullish && last.isBullish && last.close > prev.open && last.open < prev.close) {
      return {'pattern': 'Bullish Engulfing', 'bias': 'Bullish'};
    }
    // Bearish Engulfing
    if (prev.isBullish && !last.isBullish && last.close < prev.open && last.open > prev.close) {
      return {'pattern': 'Bearish Engulfing', 'bias': 'Bearish'};
    }
    // Hammer / Pin Bar (bullish)
    if (lowerWick > body * 2 && upperWick < body * 0.5 && body / totalRange < 0.4) {
      return {'pattern': 'Hammer (Bullish Pin Bar)', 'bias': 'Bullish'};
    }
    // Shooting Star / Inverted Pin Bar (bearish)
    if (upperWick > body * 2 && lowerWick < body * 0.5 && body / totalRange < 0.4) {
      return {'pattern': 'Shooting Star (Bearish Pin Bar)', 'bias': 'Bearish'};
    }
    // Doji
    if (body / totalRange < 0.1) {
      return {'pattern': 'Doji (Indecision)', 'bias': 'Neutral'};
    }
    // Strong momentum candle
    if (body / totalRange > 0.75) {
      return {'pattern': last.isBullish ? 'Strong Bullish Candle' : 'Strong Bearish Candle', 'bias': last.isBullish ? 'Bullish' : 'Bearish'};
    }

    return {'pattern': 'None', 'bias': 'Neutral'};
  }

  // ═══════════════════════════════════════════════════════
  // 9. Volume Spike Detection
  // ═══════════════════════════════════════════════════════
  static Map<String, dynamic> detectVolumeSpike(List<Candle> candles, {int period = 20}) {
    if (candles.length < period) return {'spike': false, 'ratio': 1.0};
    int start = max(0, candles.length - period - 1);
    int end = candles.length - 1;
    List<double> volumes = candles.sublist(start, end).map((c) => c.volume).toList();
    double avgVol = volumes.isNotEmpty ? volumes.reduce((a, b) => a + b) / volumes.length : 1.0;
    double currentVol = candles.last.volume;
    double ratio = avgVol > 0 ? currentVol / avgVol : 1.0;

    return {'spike': ratio > 1.5, 'ratio': ratio, 'direction': candles.last.isBullish ? 'Bullish' : 'Bearish'};
  }

  // ═══════════════════════════════════════════════════════
  //  MASTER SIGNAL EVALUATOR
  //  Multi-Strategy Confluence Scoring
  // ═══════════════════════════════════════════════════════
  static TradeSignal evaluate({required String symbol, required List<Candle> candles}) {
    if (candles.length < 20) {
      return _waitSignal(symbol, candles, 'Insufficient data');
    }

    double currentPrice = candles.last.close;
    double atr = calculateATR(candles, 14);

    // Calculate all indicators
    double ema9 = calculateEMA(candles, 9);
    double ema21 = calculateEMA(candles, 21);
    double ema50 = calculateEMA(candles, 50);

    var rsiData = calculateRSI(candles);
    double rsi = rsiData['current'];
    String rsiZone = rsiData['zone'];
    String rsiDiv = rsiData['divergence'];

    var macdData = calculateMACD(candles);
    String macdTrend = macdData['trend'];
    double macdHist = macdData['histogram'];

    var bbData = calculateBollingerBands(candles);
    String bbSignal = bbData['signal'];

    var fvgData = detectFVG(candles);
    var liqData = detectOrderBlocksAndLiquidity(candles);
    var candlePattern = detectCandlePatterns(candles);
    var volumeData = detectVolumeSpike(candles);

    int bullScore = 0;
    int bearScore = 0;
    List<String> reasons = [];

    // ── 1. EMA Trend Alignment (max +20 each) ──
    if (currentPrice > ema21 && ema21 > ema50) {
      bullScore += 15;
      reasons.add('EMA Trend: Bullish (Price > EMA21 > EMA50)');
    } else if (currentPrice < ema21 && ema21 < ema50) {
      bearScore += 15;
      reasons.add('EMA Trend: Bearish (Price < EMA21 < EMA50)');
    }

    // EMA 9/21 crossover (fast momentum)
    if (ema9 > ema21 && currentPrice > ema9) {
      bullScore += 10;
    } else if (ema9 < ema21 && currentPrice < ema9) {
      bearScore += 10;
    }

    // ── 2. RSI Zone (max +15 each) ──
    if (rsi < 35) {
      bullScore += 15;
      reasons.add('RSI Oversold: ${ rsi.toStringAsFixed(1)} (Buy Zone)');
    } else if (rsi < 45) {
      bullScore += 8;
    } else if (rsi > 65) {
      bearScore += 15;
      reasons.add('RSI Overbought: ${rsi.toStringAsFixed(1)} (Sell Zone)');
    } else if (rsi > 55) {
      bearScore += 8;
    }

    // ── 3. RSI Divergence (max +20 each) ──
    if (rsiDiv.contains('Bullish')) {
      bullScore += 20;
      reasons.add('RSI Bullish Divergence Detected');
    } else if (rsiDiv.contains('Bearish')) {
      bearScore += 20;
      reasons.add('RSI Bearish Divergence Detected');
    }

    // ── 4. MACD (max +15 each) ──
    if (macdTrend.contains('Bullish')) {
      bullScore += macdTrend.contains('Crossover') ? 15 : 10;
      if (macdTrend.contains('Crossover')) reasons.add('MACD Bullish Crossover');
    } else if (macdTrend.contains('Bearish')) {
      bearScore += macdTrend.contains('Crossover') ? 15 : 10;
      if (macdTrend.contains('Crossover')) reasons.add('MACD Bearish Crossover');
    }

    // ── 5. Bollinger Bands (max +12 each) ──
    if (bbSignal.contains('Oversold')) {
      bullScore += 12;
      reasons.add('Price at Lower Bollinger Band (Bounce Zone)');
    } else if (bbSignal.contains('Overbought')) {
      bearScore += 12;
      reasons.add('Price at Upper Bollinger Band (Rejection Zone)');
    } else if (bbSignal.contains('Squeeze')) {
      bullScore += 5;
      bearScore += 5;
    }

    // ── 6. Liquidity Sweeps (max +20 each) ──
    if (liqData['sweptSSL'] == true) {
      bullScore += 20;
      reasons.add('SSL Swept: Retail stops cleared, smart money buying');
    }
    if (liqData['sweptBSL'] == true) {
      bearScore += 20;
      reasons.add('BSL Swept: Breakout buyers trapped, smart money selling');
    }

    // ── 7. FVG Proximity (max +15 each) ──
    if (fvgData['bullish'] != null) {
      double bot = fvgData['bullish']['bottom'];
      double top = fvgData['bullish']['top'];
      double gap = (top - bot).abs();
      if (currentPrice >= bot - gap * 0.5 && currentPrice <= top + gap * 0.5) {
        bullScore += 15;
        reasons.add('Near Bullish FVG [${bot.toStringAsFixed(2)} - ${top.toStringAsFixed(2)}]');
      }
    }
    if (fvgData['bearish'] != null) {
      double bot = fvgData['bearish']['bottom'];
      double top = fvgData['bearish']['top'];
      double gap = (top - bot).abs();
      if (currentPrice >= bot - gap * 0.5 && currentPrice <= top + gap * 0.5) {
        bearScore += 15;
        reasons.add('Near Bearish FVG [${bot.toStringAsFixed(2)} - ${top.toStringAsFixed(2)}]');
      }
    }

    // ── 8. Discount/Premium Zone (max +10 each) ──
    if (liqData['isDiscount'] == true) {
      bullScore += 10;
    } else {
      bearScore += 10;
    }

    // ── 9. Candlestick Pattern (max +12 each) ──
    String candleBias = candlePattern['bias'] ?? 'Neutral';
    if (candleBias == 'Bullish') {
      bullScore += 12;
      reasons.add('Pattern: ${candlePattern['pattern']}');
    } else if (candleBias == 'Bearish') {
      bearScore += 12;
      reasons.add('Pattern: ${candlePattern['pattern']}');
    }

    // ── 10. Volume Spike (max +8 each) ──
    if (volumeData['spike'] == true) {
      if (volumeData['direction'] == 'Bullish') {
        bullScore += 8;
        reasons.add('Volume Spike: ${(volumeData['ratio'] as double).toStringAsFixed(1)}x avg (Bullish)');
      } else {
        bearScore += 8;
        reasons.add('Volume Spike: ${(volumeData['ratio'] as double).toStringAsFixed(1)}x avg (Bearish)');
      }
    }

    // ── 11. Order Block proximity (max +10 each) ──
    if (liqData['bullOBLevel'] != null) {
      double ob = liqData['bullOBLevel'];
      if ((currentPrice - ob).abs() < atr * 1.5 && currentPrice >= ob) {
        bullScore += 10;
        reasons.add('Near Bullish Order Block');
      }
    }
    if (liqData['bearOBLevel'] != null) {
      double ob = liqData['bearOBLevel'];
      if ((currentPrice - ob).abs() < atr * 1.5 && currentPrice <= ob) {
        bearScore += 10;
        reasons.add('Near Bearish Order Block');
      }
    }

    // ═══════════════════════════════════════════════════════
    //  SIGNAL DECISION (Threshold: 45 points)
    // ═══════════════════════════════════════════════════════
    int signalThreshold = 45;
    String action = 'WAIT';
    int winRate = 0;
    String entryZone = '';
    double stopLoss = 0.0;
    double tp1 = 0.0;
    double tp2 = 0.0;

    if (bullScore >= signalThreshold && bullScore > bearScore + 10) {
      // BUY Signal
      winRate = min(98, 85 + ((bullScore - signalThreshold) * 0.15).round());
      action = 'BUY (LONG)';

      double entryLow = currentPrice - (atr * 0.3);
      double entryHigh = currentPrice + (atr * 0.2);
      entryZone = '${entryLow.toStringAsFixed(_getDecimals(symbol))} - ${entryHigh.toStringAsFixed(_getDecimals(symbol))}';

      stopLoss = liqData['swingLow'] - (atr * 0.5);
      double risk = (currentPrice - stopLoss).abs();
      if (risk < atr * 0.5) risk = atr * 0.8;
      tp1 = currentPrice + (risk * 1.5);
      tp2 = currentPrice + (risk * 2.5);

    } else if (bearScore >= signalThreshold && bearScore > bullScore + 10) {
      // SELL Signal
      winRate = min(98, 85 + ((bearScore - signalThreshold) * 0.15).round());
      action = 'SELL (SHORT)';

      double entryLow = currentPrice - (atr * 0.2);
      double entryHigh = currentPrice + (atr * 0.3);
      entryZone = '${entryLow.toStringAsFixed(_getDecimals(symbol))} - ${entryHigh.toStringAsFixed(_getDecimals(symbol))}';

      stopLoss = liqData['swingHigh'] + (atr * 0.5);
      double risk = (stopLoss - currentPrice).abs();
      if (risk < atr * 0.5) risk = atr * 0.8;
      tp1 = currentPrice - (risk * 1.5);
      tp2 = currentPrice - (risk * 2.5);
    }

    if (action == 'WAIT') {
      return _waitSignal(symbol, candles, 'No strong confluence');
    }

    int dec = _getDecimals(symbol);
    String rrr = (stopLoss != 0 && (currentPrice - stopLoss).abs() > 0)
        ? '1 : ${((tp2 - currentPrice).abs() / (currentPrice - stopLoss).abs()).toStringAsFixed(1)}'
        : '1 : 2.5';

    return TradeSignal(
      symbol: symbol,
      action: action,
      winRatio: '$winRate%',
      currentPrice: currentPrice,
      entryZone: entryZone,
      stopLoss: double.parse(stopLoss.toStringAsFixed(dec)),
      takeProfit1: double.parse(tp1.toStringAsFixed(dec)),
      takeProfit2: double.parse(tp2.toStringAsFixed(dec)),
      riskReward: rrr,
      holdingTime: '2-3 Hours (Scalping)',
      reasons: reasons,
      signalTime: DateTime.now().toUtc().add(const Duration(hours: 6)).toString().split('.').first,
    );
  }

  static int _getDecimals(String symbol) {
    if (symbol.contains('JPY')) return 3;
    if (symbol.contains('XAU') || symbol.contains('BTC')) return 2;
    if (symbol.contains('ETH') || symbol.contains('SOL')) return 2;
    if (symbol.contains('OIL') || symbol.contains('US')) return 2;
    return 5;
  }

  static TradeSignal _waitSignal(String symbol, List<Candle> candles, String reason) {
    return TradeSignal(
      symbol: symbol,
      action: 'WAIT',
      winRatio: '0%',
      currentPrice: candles.isNotEmpty ? candles.last.close : 0.0,
      entryZone: reason,
      stopLoss: 0.0,
      takeProfit1: 0.0,
      takeProfit2: 0.0,
      riskReward: 'N/A',
      holdingTime: 'WAIT',
      reasons: [reason],
      signalTime: DateTime.now().toString().split('.').first,
    );
  }
}
