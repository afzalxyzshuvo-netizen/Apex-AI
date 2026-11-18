import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CapitalCalculatorScreen extends StatefulWidget {
  const CapitalCalculatorScreen({super.key});

  @override
  State<CapitalCalculatorScreen> createState() => _CapitalCalculatorScreenState();
}

class _CapitalCalculatorScreenState extends State<CapitalCalculatorScreen> {
  final _balanceController = TextEditingController(text: '100');
  final _slPipsController = TextEditingController(text: '20');
  double _accountBalance = 100.0;
  double _riskPercent = 1.0;
  double _slPips = 20.0;
  String _selectedPair = 'XAUUSD (Gold)';

  final Map<String, Map<String, dynamic>> _pairData = {
    'XAUUSD (Gold)': {'pipValue': 1.0, 'pipSize': 0.1, 'type': 'Commodity', 'icon': Icons.workspace_premium},
    'EURUSD': {'pipValue': 10.0, 'pipSize': 0.0001, 'type': 'Forex', 'icon': Icons.euro},
    'GBPUSD': {'pipValue': 10.0, 'pipSize': 0.0001, 'type': 'Forex', 'icon': Icons.currency_pound},
    'USDJPY': {'pipValue': 6.67, 'pipSize': 0.01, 'type': 'Forex', 'icon': Icons.currency_yen},
    'GBPJPY': {'pipValue': 6.67, 'pipSize': 0.01, 'type': 'Forex', 'icon': Icons.currency_pound},
    'EURJPY': {'pipValue': 6.67, 'pipSize': 0.01, 'type': 'Forex', 'icon': Icons.euro},
    'AUDUSD': {'pipValue': 10.0, 'pipSize': 0.0001, 'type': 'Forex', 'icon': Icons.attach_money},
    'USDCAD': {'pipValue': 7.50, 'pipSize': 0.0001, 'type': 'Forex', 'icon': Icons.attach_money},
    'BTCUSD (Bitcoin)': {'pipValue': 1.0, 'pipSize': 1.0, 'type': 'Crypto', 'icon': Icons.currency_bitcoin},
    'ETHUSD (Ethereum)': {'pipValue': 1.0, 'pipSize': 1.0, 'type': 'Crypto', 'icon': Icons.diamond},
    'USOIL (WTI Crude)': {'pipValue': 10.0, 'pipSize': 0.01, 'type': 'Commodity', 'icon': Icons.local_gas_station},
    'US30 (Dow Jones)': {'pipValue': 1.0, 'pipSize': 1.0, 'type': 'Index', 'icon': Icons.trending_up},
    'US500 (S&P)': {'pipValue': 1.0, 'pipSize': 1.0, 'type': 'Index', 'icon': Icons.show_chart},
    'US100 (Nasdaq)': {'pipValue': 1.0, 'pipSize': 1.0, 'type': 'Index', 'icon': Icons.insights},
  };

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

  Future<void> _saveBalance(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('saved_capital_balance', val);
  }

  Map<String, double> _calculate() {
    final pairInfo = _pairData[_selectedPair]!;
    double pipValuePerLot = pairInfo['pipValue'] as double;

    double riskAmount = _accountBalance * (_riskPercent / 100.0);
    double lotSize = _slPips > 0 ? riskAmount / (_slPips * pipValuePerLot) : 0.01;
    lotSize = double.parse(lotSize.toStringAsFixed(2));
    if (lotSize < 0.01) lotSize = 0.01;

    double actualRisk = lotSize * _slPips * pipValuePerLot;
    double profitAt1to2 = lotSize * (_slPips * 2) * pipValuePerLot;
    double profitAt1to3 = lotSize * (_slPips * 3) * pipValuePerLot;
    double pipValue = lotSize * pipValuePerLot;
    double riskPercentActual = _accountBalance > 0 ? (actualRisk / _accountBalance) * 100 : 0;

    return {
      'lotSize': lotSize,
      'riskAmount': actualRisk,
      'profitAt2': profitAt1to2,
      'profitAt3': profitAt1to3,
      'pipValue': pipValue,
      'riskPercent': riskPercentActual,
    };
  }

  @override
  Widget build(BuildContext context) {
    final calc = _calculate();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.calculate, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('ক্যাপিটাল ও লট সাইজ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'আপনার ট্রেডিং ব্যালেন্স (USD):',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
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
                    onChanged: (v) {
                      final parsed = double.tryParse(v) ?? 10.0;
                      setState(() => _accountBalance = parsed);
                      _saveBalance(parsed);
                    },
                  ),
                  const SizedBox(height: 10),
                  // Quick balance buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [10, 50, 100, 500, 1000, 5000].map((amt) {
                      bool isSel = _accountBalance == amt.toDouble();
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _accountBalance = amt.toDouble();
                            _balanceController.text = amt.toString();
                          });
                          _saveBalance(amt.toDouble());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFFFB800) : const Color(0xFF0A0E17),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSel ? const Color(0xFFFFB800) : const Color(0xFF1E293B)),
                          ),
                          child: Text(
                            '\$$amt',
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
                ],
              ),
            ),

            const SizedBox(height: 14),
            // Pair Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  items: _pairData.keys.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedPair = v);
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),
            // Risk % Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('রিস্ক পার্সেন্টেজ:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _riskPercent <= 1 ? Colors.green.withOpacity(0.2) : _riskPercent <= 2 ? Colors.orange.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_riskPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: _riskPercent <= 1 ? Colors.greenAccent : _riskPercent <= 2 ? Colors.orangeAccent : Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _riskPercent,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    activeColor: const Color(0xFFFFB800),
                    inactiveColor: const Color(0xFF1E293B),
                    label: '${_riskPercent.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() => _riskPercent = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.5%', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                      Text(_riskPercent <= 1 ? '✅ নিরাপদ' : _riskPercent <= 2 ? '⚠️ মধ্যম' : '❌ ঝুঁকিপূর্ণ', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                      Text('5.0%', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            // SL Pips Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('স্টপ লস দূরত্ব (পিপস):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _slPipsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.safety_check, color: Colors.redAccent),
                      suffixText: 'Pips',
                      suffixStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: const Color(0xFF0A0E17),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) {
                      setState(() => _slPips = double.tryParse(v) ?? 20.0);
                    },
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [10, 15, 20, 30, 50, 100].map((p) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _slPips = p.toDouble();
                            _slPipsController.text = p.toString();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _slPips == p.toDouble() ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF0A0E17),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: Text('$p', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            // Result Card
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
                      const Text('AI ক্যালকুলেশন রেজাল্ট', style: TextStyle(color: Color(0xFFFFB800), fontSize: 12, fontWeight: FontWeight.w900)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: calc['riskPercent']! <= 2 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          calc['riskPercent']! <= 2 ? '✅ নিরাপদ' : '⚠️ ঝুঁকিপূর্ণ',
                          style: TextStyle(
                            color: calc['riskPercent']! <= 2 ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildResultRow('📊 নিরাপদ লট সাইজ:', '${calc['lotSize']!.toStringAsFixed(2)} Lot', const Color(0xFFFFB800)),
                  _buildResultRow('🔒 রিস্ক এমাউন্ট:', '\$${calc['riskAmount']!.toStringAsFixed(2)}', Colors.orangeAccent),
                  _buildResultRow('📈 পিপ ভ্যালু/লট:', '\$${calc['pipValue']!.toStringAsFixed(2)} / pip', Colors.white70),
                  const Divider(color: Color(0xFF2E384D), height: 20),
                  _buildResultRow('✅ লাভ (1:2 RRR):', '+\$${calc['profitAt2']!.toStringAsFixed(2)}', Colors.greenAccent),
                  _buildResultRow('✅ লাভ (1:3 RRR):', '+\$${calc['profitAt3']!.toStringAsFixed(2)}', Colors.greenAccent),
                  _buildResultRow('❌ সর্বোচ্চ ক্ষতি:', '-\$${calc['riskAmount']!.toStringAsFixed(2)}', Colors.redAccent),
                  const Divider(color: Color(0xFF2E384D), height: 20),
                  Text(
                    'আপনার \$${_accountBalance.toStringAsFixed(0)} ব্যালেন্সের জন্য ${_riskPercent.toStringAsFixed(1)}% রিস্কে ${_slPips.toStringAsFixed(0)} পিপস SL দিয়ে ${calc['lotSize']!.toStringAsFixed(2)} লট নিরাপদ। ক্ষতি হলেও মাত্র \$${calc['riskAmount']!.toStringAsFixed(2)} হবে।',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
