class UserProfile {
  final String name;
  final String email;
  final String photoUrl;
  final String joinDate;
  final bool isPro;

  UserProfile({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.joinDate,
    this.isPro = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'joinDate': joinDate,
    'isPro': isPro,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? 'Apex Trader',
    email: json['email'] ?? 'trader@apexai.io',
    photoUrl: json['photoUrl'] ?? '',
    joinDate: json['joinDate'] ?? 'Nov 2026',
    isPro: json['isPro'] ?? true,
  );
}

class MarketPairInfo {
  final String symbol;
  final String displayName;
  final double currentPrice;
  final double change24h;
  final double high24h;
  final double low24h;
  final bool isMarketOpen;
  final String source;

  MarketPairInfo({
    required this.symbol,
    required this.displayName,
    required this.currentPrice,
    required this.change24h,
    required this.high24h,
    required this.low24h,
    required this.isMarketOpen,
    required this.source,
  });
}

class HistoricalTrade {
  final String id;
  final String symbol;
  final String type; // BUY or SELL
  final double entryPrice;
  final double exitPrice;
  final double pnlPips;
  final bool isProfit;
  final DateTime timestamp;
  final String reason;

  HistoricalTrade({
    required this.id,
    required this.symbol,
    required this.type,
    required this.entryPrice,
    required this.exitPrice,
    required this.pnlPips,
    required this.isProfit,
    required this.timestamp,
    required this.reason,
  });
}
