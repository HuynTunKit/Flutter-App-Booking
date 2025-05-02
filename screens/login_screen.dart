import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Tự động điều chỉnh khi bàn phím hiện
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // Cho phép cuộn
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24), // Khoảng cách trên cùng
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Image.asset(
                      'assets/images/travel_illustration.png',
                      height: 200,
                      errorBuilder: (context, error, stackTrace) {
                        print('Lỗi tải hình ảnh: $error');
                        return const Icon(
                          Icons.image_not_supported,
                          size: 100,
                          color: Colors.grey,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Tìm Ưu Đãi Tốt Nhất',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Tận hưởng giây phút thư giãn',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style:
                          GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật Khẩu',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style:
                          GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFF59E0B),
                        )
                      : SlideTransition(
                          position: _slideAnimation,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'ĐĂNG NHẬP',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'TẠO TÀI KHOẢN',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF59E0B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24), // Khoảng cách dưới cùng
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
