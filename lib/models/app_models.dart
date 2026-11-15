class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String joinDate;
  final bool isPro;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.joinDate,
    this.isPro = true,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'joinDate': joinDate,
    'isPro': isPro,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] ?? 'ZVR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    name: json['name'] ?? 'Zavro Trader',
    email: json['email'] ?? 'trader@zavro.io',
    phone: json['phone'] ?? '+8801700000000',
    joinDate: json['joinDate'] ?? 'Nov 2026',
    isPro: json['isPro'] ?? true,
  );
}

class MarketPairInfo {
  final String symbol;
  final String displayName;
  final String category; // 'Forex', 'Commodity', 'Crypto', 'Indices'
  final double currentPrice;
  final double change24h;
  final double high24h;
  final double low24h;
  final bool isMarketOpen;
  final String source;

  MarketPairInfo({
    required this.symbol,
    required this.displayName,
    required this.category,
    required this.currentPrice,
    required this.change24h,
    required this.high24h,
    required this.low24h,
    required this.isMarketOpen,
    required this.source,
  });
}

class ForexNewsItem {
  final String time;
  final String currency;
  final String impact; // High, Medium, Low
  final String title;
  final String forecast;
  final String previous;

  ForexNewsItem({
    required this.time,
    required this.currency,
    required this.impact,
    required this.title,
    required this.forecast,
    required this.previous,
  });
}

class RealTradeRecord {
  final String id;
  final String symbol;
  final String action; // BUY or SELL
  final double entryPrice;
  final double? exitPrice;
  final double pnlPips;
  final String outcome; // 'ACTIVE', 'PROFIT (TP1)', 'PROFIT (TP2)', 'LOSS (SL)'
  final DateTime timestamp;
  final String reason;

  RealTradeRecord({
    required this.id,
    required this.symbol,
    required this.action,
    required this.entryPrice,
    this.exitPrice,
    required this.pnlPips,
    required this.outcome,
    required this.timestamp,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'symbol': symbol,
    'action': action,
    'entryPrice': entryPrice,
    'exitPrice': exitPrice,
    'pnlPips': pnlPips,
    'outcome': outcome,
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
  };

  factory RealTradeRecord.fromJson(Map<String, dynamic> json) => RealTradeRecord(
    id: json['id'],
    symbol: json['symbol'],
    action: json['action'],
    entryPrice: (json['entryPrice'] as num).toDouble(),
    exitPrice: json['exitPrice'] != null ? (json['exitPrice'] as num).toDouble() : null,
    pnlPips: (json['pnlPips'] as num).toDouble(),
    outcome: json['outcome'],
    timestamp: DateTime.parse(json['timestamp']),
    reason: json['reason'],
  );
}
