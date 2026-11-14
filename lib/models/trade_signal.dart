class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  bool get isBullish => close >= open;
}

class TradeSignal {
  final String symbol;
  final String action; // "BUY (LONG)" or "SELL (SHORT)" or "WAIT"
  final String winRatio; // "88%", "92%", "96%"
  final double currentPrice;
  final String entryZone;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final String riskReward;
  final String holdingTime;
  final List<String> reasons;
  final String signalTime;
  String outcome; // "ACTIVE", "PROFIT (TP1)", "PROFIT (TP2)", "LOSS (SL)"
  double? closePrice;
  String? closeTime;

  TradeSignal({
    required this.symbol,
    required this.action,
    required this.winRatio,
    required this.currentPrice,
    required this.entryZone,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.riskReward,
    required this.holdingTime,
    required this.reasons,
    required this.signalTime,
    this.outcome = "ACTIVE",
    this.closePrice,
    this.closeTime,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'action': action,
    'winRatio': winRatio,
    'currentPrice': currentPrice,
    'entryZone': entryZone,
    'stopLoss': stopLoss,
    'takeProfit1': takeProfit1,
    'takeProfit2': takeProfit2,
    'riskReward': riskReward,
    'holdingTime': holdingTime,
    'reasons': reasons,
    'signalTime': signalTime,
    'outcome': outcome,
    'closePrice': closePrice,
    'closeTime': closeTime,
  };

  factory TradeSignal.fromJson(Map<String, dynamic> json) => TradeSignal(
    symbol: json['symbol'] ?? '',
    action: json['action'] ?? 'WAIT',
    winRatio: json['winRatio'] ?? '0%',
    currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
    entryZone: json['entryZone'] ?? '',
    stopLoss: (json['stopLoss'] as num?)?.toDouble() ?? 0.0,
    takeProfit1: (json['takeProfit1'] as num?)?.toDouble() ?? 0.0,
    takeProfit2: (json['takeProfit2'] as num?)?.toDouble() ?? 0.0,
    riskReward: json['riskReward'] ?? '',
    holdingTime: json['holdingTime'] ?? '',
    reasons: (json['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    signalTime: json['signalTime'] ?? '',
    outcome: json['outcome'] ?? 'ACTIVE',
    closePrice: (json['closePrice'] as num?)?.toDouble(),
    closeTime: json['closeTime'],
  );
}
