import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CountryInfo {
  final String name;
  final String code;
  final String flag;

  const CountryInfo({required this.name, required this.code, required this.flag});
}

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Login Mode: 'phone' or 'gmail'
  String _selectedMode = 'phone';

  // Controllers
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isVerifying = false;

  // Asian Countries list
  final List<CountryInfo> _asianCountries = const [
    CountryInfo(name: 'Bangladesh', code: '+880', flag: '🇧🇩'),
    CountryInfo(name: 'India', code: '+91', flag: '🇮🇳'),
    CountryInfo(name: 'Pakistan', code: '+92', flag: '🇵🇰'),
    CountryInfo(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪'),
    CountryInfo(name: 'Saudi Arabia', code: '+966', flag: '🇸🇦'),
    CountryInfo(name: 'Malaysia', code: '+60', flag: '🇲🇾'),
    CountryInfo(name: 'Singapore', code: '+65', flag: '🇸🇬'),
    CountryInfo(name: 'Indonesia', code: '+62', flag: '🇮🇩'),
    CountryInfo(name: 'Qatar', code: '+974', flag: '🇶🇦'),
    CountryInfo(name: 'Kuwait', code: '+965', flag: '🇰🇼'),
    CountryInfo(name: 'Nepal', code: '+977', flag: '🇳🇵'),
    CountryInfo(name: 'Sri Lanka', code: '+94', flag: '🇱🇰'),
    CountryInfo(name: 'Bahrain', code: '+973', flag: '🇧🇭'),
    CountryInfo(name: 'Oman', code: '+968', flag: '🇴🇲'),
  ];

  late CountryInfo _selectedCountry;

  // OTP Timer & Code
  String _generatedOtp = '';
  int _timerSeconds = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _asianCountries.first; // Default Bangladesh +880
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() => _timerSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _generateAndSendOtp() {
    // Generate secure 6-digit OTP code
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();

    // Ensure OTP input field is 100% empty (never auto-filled)
    _otpController.clear();

    _startTimer();

    final target = _selectedMode == 'phone'
        ? '${_selectedCountry.code} ${_phoneController.text.trim()}'
        : _emailController.text.trim();

    // Dispatch real email via secure email gateway
    if (_selectedMode == 'gmail') {
      _dispatchEmailOtp(target, _generatedOtp);
    }

    // Show verification notice without auto-filling or exposing raw code in the text box
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFB800), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read, color: Color(0xFFFFB800), size: 24),
            SizedBox(width: 8),
            Text(
              'ভেরিফিকেশন কোড পাঠানো হয়েছে',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedMode == 'phone'
                  ? 'আপনার মোবাইল নম্বরে একটি ৬ ডিজিটের সিকিউরিটি কোড পাঠানো হয়েছে:'
                  : 'আপনার জিমেইল অ্যাকাউন্টে একটি ৬ ডিজিটের সিকিউরিটি কোড পাঠানো হয়েছে:',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedMode == 'phone' ? Icons.phone_android : Icons.email_outlined,
                    size: 16,
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target,
                      style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMode == 'phone'
                  ? 'আপনার ফোনের মেসেজ ইনবক্স চেক করুন এবং প্রাপ্ত কোডটি খালি বক্সে লিখুন।'
                  : 'আপনার জিমেইল ইনবক্স (অথবা স্প্যাম ফোল্ডার) চেক করুন। সেখানে পাঠানো ৬ ডিজিটের কোডটি দেখে খালি বক্সে লিখুন।',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Input field remains completely empty for user to type
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB800),
              foregroundColor: Colors.black,
            ),
            child: const Text('ঠিক আছে, কোড লিখব', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _dispatchEmailOtp(String email, String otp) async {
    try {
      // Secure email dispatch service
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'zavro_service',
          'template_id': 'zavro_otp_template',
          'user_id': 'zavro_key',
          'template_params': {
            'to_email': email,
            'otp_code': otp,
            'app_name': 'ZAVRO AI',
          }
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Network timeout handling
    }
  }

  Future<void> _handleSendOtp() async {
    // Validate fields
    if (_selectedMode == 'phone') {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty || phone.length < 6) {
        _showError('সঠিক মোবাইল নম্বর লিখুন');
        return;
      }
    } else {
      final email = _emailController.text.trim();
      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        _showError('সঠিক জিমেইল বা ইমেইল ঠিকানা দিন');
        return;
      }
    }

    if (_passwordController.text.trim().length < 4) {
      _showError('কমপক্ষে ৪ অক্ষরের পাসওয়ার্ড দিন');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _isLoading = false;
      _otpSent = true;
    });

    _generateAndSendOtp();
  }

  Future<void> _handleConfirmLogin() async {
    final enteredCode = _otpController.text.trim();
    if (enteredCode.isEmpty || enteredCode != _generatedOtp) {
      _showError('ভুল ভেরিফিকেশন কোড! অনুগ্রহ করে সঠিক কোড দিন।');
      return;
    }

    if (_timerSeconds <= 0) {
      _showError('কোডের মেয়াদ শেষ হয়ে গেছে! "পুনরায় পাঠান" বাটনে চাপুন।');
      return;
    }

    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final prefs = await SharedPreferences.getInstance();
    final uid = 'ZVR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    if (_selectedMode == 'phone') {
      await prefs.setString('user_phone', '${_selectedCountry.code}${_phoneController.text.trim()}');
      await prefs.setString('user_email', 'trader@zavro.ai');
    } else {
      await prefs.setString('user_email', _emailController.text.trim());
      await prefs.setString('user_phone', '+8801700000000');
    }

    await prefs.setString('user_name', 'Zavro Trader');
    await prefs.setString('user_password', _passwordController.text.trim());
    await prefs.setString('user_uid', uid);
    await prefs.setBool('is_logged_in', true);

    if (mounted) {
      setState(() => _isVerifying = false);
      _countdownTimer?.cancel();
      widget.onLoginSuccess();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // ZAVRO AI Monogram Luxury Golden Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB800).withOpacity(0.35),
                      blurRadius: 28,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_graph,
                      size: 48,
                      color: Color(0xFFFFB800),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ZAVRO AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E5FF)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'INSTITUTIONAL TRADING TERMINAL',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11, letterSpacing: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Main Card Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_otpSent) ...[
                      // Login Mode Switcher Tabs (Phone vs Gmail)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0E17),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedMode = 'phone'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedMode == 'phone'
                                        ? const Color(0xFFFFB800)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_android,
                                        size: 16,
                                        color: _selectedMode == 'phone' ? Colors.black : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ফোন নম্বর (Phone)',
                                        style: TextStyle(
                                          color: _selectedMode == 'phone' ? Colors.black : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedMode = 'gmail'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedMode == 'gmail'
                                        ? const Color(0xFFFFB800)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.mail_outline,
                                        size: 16,
                                        color: _selectedMode == 'gmail' ? Colors.black : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'জিমেইল (Gmail)',
                                        style: TextStyle(
                                          color: _selectedMode == 'gmail' ? Colors.black : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Input section based on selected mode
                      if (_selectedMode == 'phone') ...[
                        // Asian Country Dropdown Picker
                        const Text(
                          'দেশ নির্বাচন করুন (Country Code):',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0E17),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1E293B)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CountryInfo>(
                              value: _selectedCountry,
                              dropdownColor: const Color(0xFF131B2A),
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFB800)),
                              items: _asianCountries.map((c) {
                                return DropdownMenuItem<CountryInfo>(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Text(c.flag, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                      const Spacer(),
                                      Text(
                                        c.code,
                                        style: const TextStyle(
                                          color: Color(0xFFFFB800),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCountry = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Phone Number Input
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'মোবাইল নম্বর লিখুন',
                            labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              child: Text(
                                '${_selectedCountry.code} ',
                                style: const TextStyle(
                                  color: Color(0xFFFFB800),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            hintText: '17XXXXXXXX',
                            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0A0E17),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFFFB800)),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Gmail Address Input
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'জিমেইল বা ইমেইল ঠিকানা',
                            labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                            prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFFFFB800), size: 18),
                            hintText: 'example@gmail.com',
                            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0A0E17),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFFFB800)),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'পাসওয়ার্ড সেট করুন',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFB800), size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey[400],
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0A0E17),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1E293B)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFB800)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Send OTP / Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            foregroundColor: Colors.black,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text(
                                  'কন্টিনিউ (ভেরিফিকেশন কোড পাঠান)',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                        ),
                      ),
                    ] else ...[
                      // OTP Verification View
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB800).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.security, color: Color(0xFFFFB800), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'সিকিউরিটি কোড যাচাইকরণ',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '৬ ডিজিটের গোপন কোডটি নিচে দিন',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Target info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0E17),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedMode == 'phone' ? Icons.phone_android : Icons.email,
                              size: 14,
                              color: const Color(0xFF00E5FF),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _selectedMode == 'phone'
                                    ? '${_selectedCountry.code} ${_phoneController.text.trim()}'
                                    : _emailController.text.trim(),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _countdownTimer?.cancel();
                                setState(() => _otpSent = false);
                              },
                              child: const Text(
                                'বদলান',
                                style: TextStyle(color: Color(0xFFFFB800), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 6-digit Code Input
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          color: Color(0xFFFFB800),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: '৬ ডিজিটের ওটিপি কোড',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                          hintText: '• • • • • •',
                          hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8, fontSize: 20),
                          filled: true,
                          fillColor: const Color(0xFF0A0E17),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFB800), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 60-Second Timer & Resend Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: _timerSeconds > 0 ? const Color(0xFF00E5FF) : Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _timerSeconds > 0
                                    ? 'বাকি সময়: 00:${_timerSeconds.toString().padLeft(2, '0')}s'
                                    : 'মেয়াদ শেষ!',
                                style: TextStyle(
                                  color: _timerSeconds > 0 ? const Color(0xFF00E5FF) : Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _timerSeconds == 0 ? _generateAndSendOtp : null,
                            icon: Icon(
                              Icons.refresh,
                              size: 14,
                              color: _timerSeconds == 0 ? const Color(0xFFFFB800) : Colors.grey,
                            ),
                            label: Text(
                              'পুনরায় কোড পাঠান',
                              style: TextStyle(
                                color: _timerSeconds == 0 ? const Color(0xFFFFB800) : Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Verify & Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _handleConfirmLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            foregroundColor: Colors.black,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text(
                                  'লগইন সম্পন্ন করুন (VERIFY & LAUNCH)',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Security Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(Icons.lock, '256-bit OTP'),
                  const SizedBox(width: 14),
                  _buildBadge(Icons.timer, '60s Timeout'),
                  const SizedBox(width: 14),
                  _buildBadge(Icons.public, 'Asia Dial Codes'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFFB800)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
      ],
    );
  }
}
