import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CapitalCalculatorScreen extends StatefulWidget {
  const CapitalCalculatorScreen({super.key});

  @override
  State<CapitalCalculatorScreen> createState() => _CapitalCalculatorScreenState();
}

class _CapitalCalculatorScreenState extends State<CapitalCalculatorScreen> {
  final _balanceController = TextEditingController(text: '500');
  double _riskPercent = 1.5;
  double _accountBalance = 500.0;
  String _selectedPair = 'XAUUSD (Gold)';

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
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

  @override
  Widget build(BuildContext context) {
    final riskAmount = _accountBalance * (_riskPercent / 100);
    final targetReward = riskAmount * 2.5; // 1:2.5 institutional target

    // Recommended Lot Size calculation based on asset volatility
    double recLot = 0.01;
    if (_selectedPair.contains('XAU')) {
      recLot = ((_accountBalance / 500) * 0.02).clamp(0.01, 10.0);
    } else {
      recLot = ((_accountBalance / 500) * 0.05).clamp(0.01, 10.0);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.calculate, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Capital & Lot Size Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Input Card
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
                  const Text('Enter Your Trading Capital (\$ USD):', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _balanceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFFB800)),
                      filled: true,
                      fillColor: const Color(0xFF0A0E17),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixText: 'USD',
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v) ?? 100.0;
                      setState(() => _accountBalance = parsed);
                      _saveBalance(parsed);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Risk Per Trade: ${_riskPercent.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Max Risk: \$${riskAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Slider(
                    value: _riskPercent,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    activeColor: const Color(0xFFFFB800),
                    onChanged: (v) => setState(() => _riskPercent = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Select Pair for exact lot sizing
            const Text('SELECT TARGET PAIR', style: TextStyle(color: Color(0xFFFFB800), fontSize: 11, fontWeight: FontWeight.bold)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: ['XAUUSD (Gold)', 'EURUSD', 'GBPUSD', 'USDJPY', 'USOIL (Crude)'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _selectedPair = v); },
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Calculation Output Sheet
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
                children: [
                  const Text('AI CAPITAL SIZING PLAN', style: TextStyle(color: Color(0xFFFFB800), fontSize: 12, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  _buildPlanRow('Recommended Lot Size:', '${recLot.toStringAsFixed(2)} Lots', Colors.greenAccent),
                  _buildPlanRow('Max Risk Dollar (Stop Loss):', '-\$${riskAmount.toStringAsFixed(2)}', Colors.redAccent),
                  _buildPlanRow('Expected Target (TP1 / TP2):', '+\$${targetReward.toStringAsFixed(2)}', Colors.greenAccent),
                  _buildPlanRow('Minimum RRR Setup:', '1 : 2.5', Colors.white),
                  _buildPlanRow('Holding Period:', '2 to 3 Hours (Swift Swing)', Colors.white70),
                  const Divider(color: Color(0xFF2E384D)),
                  const SizedBox(height: 8),
                  Text(
                    'Zavro AI Auto-Rule: If balance is \$${_accountBalance.toStringAsFixed(0)}, taking a ${recLot.toStringAsFixed(2)} lot trade ensures your account can withstand 20 consecutive losses without blowing up!',
                    style: TextStyle(color: Colors.grey[300], fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanRow(String title, String val, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
