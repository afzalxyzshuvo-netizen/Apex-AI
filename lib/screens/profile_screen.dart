import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Afzal Shuvo';
  String _email = 'afzalxyzshuvo@gmail.com';
  String _phone = '+8801700000000';
  String _uid = 'ZVR-849201';

  // Interactive Settings State
  String _timeframe = '15m to 1h (Swing)';
  bool _audioAlerts = true;
  bool _vibration = true;
  String _selectedSound = 'Loud Siren Alert (85dB)';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? 'Afzal Shuvo';
      _email = prefs.getString('user_email') ?? 'afzalxyzshuvo@gmail.com';
      _phone = prefs.getString('user_phone') ?? '+8801700000000';
      _uid = prefs.getString('user_uid') ?? 'ZVR-849201';
      _timeframe = prefs.getString('setting_tf') ?? '15m to 1h (Swing)';
      _audioAlerts = prefs.getBool('setting_audio') ?? true;
      _vibration = prefs.getBool('setting_vib') ?? true;
      _selectedSound = prefs.getString('setting_sound') ?? 'Loud Siren Alert (85dB)';
    });
  }

  Future<void> _saveSetting(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is String) await prefs.setString(key, val);
    if (val is bool) await prefs.setBool(key, val);
  }

  void _showTradingEngineModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trading Engine & Timeframe Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Select analysis timeframe for SMC / ICT confluences', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 16),
                  _buildRadioOption('15m to 1h (Institutional Standard)', _timeframe, (v) {
                    setState(() => _timeframe = v);
                    setModalState(() => _timeframe = v);
                    _saveSetting('setting_tf', v);
                  }),
                  _buildRadioOption('5m to 15m (Quick Scalp)', _timeframe, (v) {
                    setState(() => _timeframe = v);
                    setModalState(() => _timeframe = v);
                    _saveSetting('setting_tf', v);
                  }),
                  _buildRadioOption('1h to 4h (HTF Swing)', _timeframe, (v) {
                    setState(() => _timeframe = v);
                    setModalState(() => _timeframe = v);
                    _saveSetting('setting_tf', v);
                  }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB800), foregroundColor: Colors.black),
                      child: const Text('SAVE & APPLY SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAudioSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131B2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Audio Signals & Loud Sound Selection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('High Volume Signal Alert Sound', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: _audioAlerts,
                    activeColor: const Color(0xFFFFB800),
                    onChanged: (v) {
                      setState(() => _audioAlerts = v);
                      setModalState(() => _audioAlerts = v);
                      _saveSetting('setting_audio', v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Vibration on Instant Entry', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: _vibration,
                    activeColor: const Color(0xFFFFB800),
                    onChanged: (v) {
                      setState(() => _vibration = v);
                      setModalState(() => _vibration = v);
                      _saveSetting('setting_vib', v);
                    },
                  ),
                  const Divider(color: Color(0xFF1E293B)),
                  const Text('Select Loud Alert Tone:', style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSound,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0A0E17),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      'Loud Siren Alert (85dB)',
                      'Institutional Bull Horn (Loud)',
                      'Sonar Beep Warning',
                      'Cash Register Ping',
                    ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedSound = v);
                        setModalState(() => _selectedSound = v);
                        _saveSetting('setting_sound', v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB800), foregroundColor: Colors.black),
                      child: const Text('CONFIRM AUDIO PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRiskManagementModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131B2A),
          title: const Row(
            children: [
              Icon(Icons.shield, color: Color(0xFFFFB800)),
              SizedBox(width: 8),
              Text('Institutional Risk Rules', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mastering Risk Management in Forex & Gold:',
                  style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. 1%-2% Rule: Never risk more than 1% to 2% of your total balance on a single trade.\n\n'
                  '2. Lot Size Sizing:\n'
                  '• \$100 Account -> Max 0.01 Lot\n'
                  '• \$500 Account -> Max 0.03 to 0.05 Lot\n'
                  '• \$1,000 Account -> Max 0.05 to 0.10 Lot\n\n'
                  '3. Risk-Reward Ratio (RRR): Always aim for minimum 1:2 or 1:3 RRR. Even with 50% accuracy, you stay profitable!\n\n'
                  '4. Capital Preservation: "Amateurs focus on how much they can make; Professionals focus on how much they can lose." Protect your capital first!',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('UNDERSTOOD', style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showLearnTradingModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131B2A),
          title: const Row(
            children: [
              Icon(Icons.menu_book, color: Color(0xFFFFB800)),
              SizedBox(width: 8),
              Text('Learn Trading (ICT & SMC)', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Step-by-Step Educational Curriculum:', style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  '📖 Chapter 1: Market Structure (BOS vs CHoCH)\n'
                  'Learn how smart money shifts market direction by breaking previous swing highs and lows.\n\n'
                  '📖 Chapter 2: Order Blocks (OB)\n'
                  'The last opposite candle before an aggressive displacement move where institutional banks place million-dollar orders.\n\n'
                  '📖 Chapter 3: Fair Value Gaps (FVG)\n'
                  '3-candle price imbalance where liquidity is skipped. Price always seeks to fill unmitigated FVGs.\n\n'
                  '📖 Chapter 4: Liquidity Pools & Sweeps\n'
                  'Equal highs and equal lows where retail traders put stop losses. Institutions sweep these levels before massive reversals.\n\n'
                  '📖 Chapter 5: Optimal Trade Entry (OTE)\n'
                  'Using Fibonacci 0.618 to 0.786 discount arrays for sniper entries.',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Color(0xFFFFB800))),
            ),
          ],
        );
      },
    );
  }

  void _showAboutZavroModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131B2A),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFFB800)),
              SizedBox(width: 8),
              Text('About ZAVRO AI', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'ZAVRO TRADING INTELLIGENCE',
                    style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('Version 3.0.0 (Release Build)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Zavro AI is a state-of-the-art institutional trading intelligence system built for high-probability Forex, Gold, and Crypto trading.\n\n'
                  '• Model: Zavro Institutional SMC/ICT v3.0\n'
                  '• Latency: Ultra-low 3s-5s Direct WebSocket Feed\n'
                  '• Filter: 85%+ Multi-Strategy Confluence\n'
                  '• Session: Active 8:00 AM to 11:00 PM (BD Time)\n'
                  '• Privacy: Local Encrypted Storage & Private Cloud',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DONE', style: TextStyle(color: Color(0xFFFFB800))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadioOption(String title, String currentVal, Function(String) onSelect) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
      value: title,
      groupValue: currentVal,
      activeColor: const Color(0xFFFFB800),
      onChanged: (v) { if (v != null) onSelect(v); },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        elevation: 0,
        title: const Text('Trader Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFFFB800),
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'Z',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(_email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(_phone, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFB800)),
                    ),
                    child: Text(
                      'UID: $_uid  •  PRO LICENSE',
                      style: const TextStyle(color: Color(0xFFFFB800), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Active Interactive Options
            _buildActionTile(
              Icons.tune,
              'Trading Engine Settings',
              _timeframe,
              _showTradingEngineModal,
            ),
            _buildActionTile(
              Icons.notifications_active_outlined,
              'Audio Signals & Loud Alerts',
              'Sound: $_selectedSound',
              _showAudioSettingsModal,
            ),
            _buildActionTile(
              Icons.shield_outlined,
              'Risk Management Guidelines',
              '1-2% Rule & Lot Size Guide',
              _showRiskManagementModal,
            ),
            _buildActionTile(
              Icons.menu_book,
              'Learn Trading (ICT & SMC)',
              'Step-by-step Masterclass Guide',
              _showLearnTradingModal,
            ),
            _buildActionTile(
              Icons.support_agent,
              'Support Hub & Live Chat',
              'Open a ticket, Suggest a feature',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support Hub connected: support@zavro.io')),
                );
              },
            ),
            _buildActionTile(
              Icons.info_outline,
              'About ZAVRO AI',
              'Version 3.0.0 (Release Build)',
              _showAboutZavroModal,
            ),

            const SizedBox(height: 28),
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_logged_in', false);
                  widget.onLogout();
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text('Sign Out Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFFFB800), size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ),
    );
  }
}
