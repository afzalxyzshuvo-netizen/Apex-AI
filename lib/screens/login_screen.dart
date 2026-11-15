import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController(text: 'Afzal Shuvo');
  final _emailController = TextEditingController(text: 'afzalxyzshuvo@gmail.com');
  final _phoneController = TextEditingController(text: '1700000000');
  final _passwordController = TextEditingController(text: 'zavro@2026');
  final _otpController = TextEditingController(text: '8492');

  bool _isVerifying = false;
  bool _otpSent = false;
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all account fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));

    setState(() {
      _isLoading = false;
      _otpSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification Code sent to +880 phone & Gmail! (Code: 8492)')),
    );
  }

  Future<void> _handleConfirmLogin() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    final uid = 'ZVR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_email', _emailController.text.trim());
    await prefs.setString('user_phone', '+880${_phoneController.text.trim()}');
    await prefs.setString('user_password', _passwordController.text.trim());
    await prefs.setString('user_uid', uid);
    await prefs.setBool('is_logged_in', true);

    if (mounted) {
      setState(() => _isVerifying = false);
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // ZAVRO Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB800).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_graph,
                      size: 50,
                      color: Color(0xFFFFB800),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ZAVRO AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Institutional Trading Intelligence Platform',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 32),

              // Form Container
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otpSent ? 'Enter Verification Code' : 'Create Trader Account',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _otpSent
                          ? 'Enter the 4-digit code sent to your phone and email'
                          : 'Sign up with Gmail & Bangladeshi (+880) Phone',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    if (!_otpSent) ...[
                      // Name
                      _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 12),
                      // Gmail
                      _buildTextField(_emailController, 'Gmail Address', Icons.email_outlined, keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      // Bangladesh Phone Number with prefix
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Text(
                              '+880 ',
                              style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0A0E17),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Password
                      _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                      const SizedBox(height: 24),
                      // Send OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                              : const Text('VERIFY & CONTINUE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                    ] else ...[
                      // OTP Verification Box
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFFB800), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                        decoration: InputDecoration(
                          labelText: 'Verification Code',
                          labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF0A0E17),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _handleConfirmLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isVerifying
                              ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                              : const Text('LAUNCH ZAVRO DESK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _otpSent = false),
                          child: const Text('Edit Details', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(Icons.security, 'Encrypted Auth'),
                  const SizedBox(width: 14),
                  _buildBadge(Icons.bolt, '3s Instant Feed'),
                  const SizedBox(width: 14),
                  _buildBadge(Icons.flag, 'BD Session Sync'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFFFFB800), size: 20),
        filled: true,
        fillColor: const Color(0xFF0A0E17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
