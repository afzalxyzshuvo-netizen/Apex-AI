import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CapitalCalculatorScreen extends StatefulWidget {
  const CapitalCalculatorScreen({super.key});

  @override
  State<CapitalCalculatorScreen> createState() => _CapitalCalculatorScreenState();
}

class _CapitalCalculatorScreenState extends State<CapitalCalculatorScreen> {
  final _balanceController = TextEditingController(text: '100');
  double _accountBalance = 100.0;
  String _selectedPair = 'XAUUSD (Gold Spot)';

  // All Tradable Pairs List
  final List<String> _allPairs = [
    'XAUUSD (Gold Spot)',
    'BTC (Bitcoin 24/7)',
    'ETH (Ethereum 24/7)',
    'EURUSD',
    'GBPUSD',
    'USDJPY',
    'GBPJPY',
    'EURJPY',
    'AUDUSD',
    'USDCAD',
    'USOIL (WTI Crude)',
    'UKOIL (Brent)',
    'US30 (Dow Jones)',
    'US500 (S&P)',
    'US100 (Nasdaq)',
  ];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('saved_capital_balance');
    if (saved != null) {
      setState(() {
        _accountBalance = saved;
        _balanceController.text = saved.toStringAsFixed(0);
      });
    }
  }

  Future<void> _updateBalance(String v) async {
    final parsed = double.tryParse(v) ?? 10.0;
    setState(() => _accountBalance = parsed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_capital_balance', parsed);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Dynamic Lot Sizing & Money Management Calculation
    double recommendedLot = 0.01;
    double pipValuePerLot = 10.0; // Standard Forex 1 pip with 1 lot = $10

    if (_selectedPair.contains('XAU')) {
      // Gold: $100 -> 0.01 lot, $500 -> 0.02-0.03 lot
      recommendedLot = ((_accountBalance / 100) * 0.01).clamp(0.01, 20.0);
      pipValuePerLot = 10.0; // $1 move in gold = 10 pips
    } else if (_selectedPair.contains('BTC') || _selectedPair.contains('ETH')) {
      recommendedLot = ((_accountBalance / 100) * 0.01).clamp(0.01, 10.0);
      pipValuePerLot = 1.0;
    } else if (_selectedPair.contains('JPY')) {
      recommendedLot = ((_accountBalance / 100) * 0.01).clamp(0.01, 20.0);
      pipValuePerLot = 7.0;
    } else {
      // Standard Forex Majors
      recommendedLot = ((_accountBalance / 100) * 0.01).clamp(0.01, 30.0);
      pipValuePerLot = 10.0;
    }

    // Profit & Loss calculation per 10 pips and average 20 pips swing
    final profitPer10Pips = recommendedLot * pipValuePerLot * 10;
    final lossPer10Pips = profitPer10Pips;
    final swingTarget25Pips = profitPer10Pips * 2.5;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.calculate, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('ক্যাপিটাল ও লট সাইজ হিসাব', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capital Balance Input Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'আপনার ট্রেডিং ব্যালেন্স বসান (\$ USD):',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'আপনি যত ডলার দিয়ে ট্রেড করতে চান (যেমন: \$১০, \$৫০, \$১০০ বা \$১০০০)',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _balanceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFFB800)),
                      suffixText: 'USD',
                      suffixStyle: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: const Color(0xFF0A0E17),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: _updateBalance,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            // Select Any Pair Dropdown (All Pairs Included)
            const Text('ট্রেডিং পেয়ার সিলেক্ট করুন:', style: TextStyle(color: Color(0xFFFFB800), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPair,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF131B2A),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  items: _allPairs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPair = v);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Dynamic Output Calculation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF131B2A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('AI লট সাইজ ও প্রফিট/লস হিসাব', style: TextStyle(color: Color(0xFFFFB800), fontSize: 12, fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: const Text('নিরাপদ রিস্ক', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalcRow('নিরাপদ লট সাইজ (Recommended):', '${recommendedLot.toStringAsFixed(2)} Lot', const Color(0xFFFFB800)),
                  _buildCalcRow('প্রতি ১০ পিপসে সম্ভাব্য লাভ (TP):', '+\$${profitPer10Pips.toStringAsFixed(2)}', Colors.greenAccent),
                  _buildCalcRow('প্রতি ১০ পিপসে সম্ভাব্য ক্ষতি (SL):', '-\$${lossPer10Pips.toStringAsFixed(2)}', Colors.redAccent),
                  _buildCalcRow('পূর্ণ সুইং টার্গেট (২৫ পিপস):', '+\$${swingTarget25Pips.toStringAsFixed(2)}', Colors.greenAccent),
                  const Divider(color: Color(0xFF2E384D)),
                  const SizedBox(height: 6),
                  Text(
                    'সহজ নিয়ম: আপনার \$${_accountBalance.toStringAsFixed(0)} ব্যালেন্সের জন্য এই পেয়ারে ${recommendedLot.toStringAsFixed(2)} লটের বেশি নেওয়া উচিত নয়। এর ফলে মার্কেট যদি সাময়িকভাবে ১০ পিপস বিপরীতেও যায়, আপনার অ্যাকাউন্টে মাত্র \$${lossPer10Pips.toStringAsFixed(2)} এর মতো সামান্য ঝুঁকি থাকবে, যা ব্যালেন্স সুরক্ষিত রাখবে!',
                    style: TextStyle(color: Colors.grey[300], fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }
}
