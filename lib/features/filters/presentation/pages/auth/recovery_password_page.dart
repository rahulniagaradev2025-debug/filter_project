import 'package:flutter/material.dart';
import '../../../../../core/storage/auth_preferences.dart';

class RecoveryPasswordPage extends StatefulWidget {
  const RecoveryPasswordPage({super.key});

  @override
  State<RecoveryPasswordPage> createState() => _RecoveryPasswordPageState();
}

class _RecoveryPasswordPageState extends State<RecoveryPasswordPage> {
  final _mobileController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;

  void _onContinue() async {
    final mobile = _mobileController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (mobile.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Save the new credentials
    await AuthPreferences.instance.saveCredentials(mobile, newPassword);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated successfully!')),
    );
    Navigator.pop(context); // Go back to Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildBackButton(),
              const SizedBox(height: 60),
              const Center(
                child: Text(
                  'Recovery Password',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E232C),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Please Enter Your Email Address To Recieve a Verification Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6A707C),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Mobile Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E232C),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '6121321231',
                  filled: true,
                  fillColor: const Color(0xFFF7F8F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E232C),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your new password',
                  filled: true,
                  fillColor: const Color(0xFFF7F8F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF6A707C),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      width: 41,
      height: 41,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8ECF4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back_ios_new, size: 16),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
