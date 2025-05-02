import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
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
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu không khớp.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tạo tài khoản trong Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Lưu thông tin vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dateOfBirthController.text.trim(),
        'role': 'user', // Mặc định là user
        'createdAt': Timestamp.now().toDate().toIso8601String(),
        'updatedAt': Timestamp.now().toDate().toIso8601String(),
      });

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Tạo Tài Khoản Của Bạn',
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
                      'Tham gia để tìm ưu đãi khách sạn tốt nhất',
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và Tên',
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
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
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
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: _dateOfBirthController,
                      decoration: InputDecoration(
                        labelText: 'Ngày sinh (YYYY-MM-DD)',
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
                      keyboardType: TextInputType.datetime,
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
                  SlideTransition(
                    position: _slideAnimation,
                    child: TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Xác Nhận Mật Khẩu',
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
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'ĐĂNG KÝ',
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
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(
                        'Đã có tài khoản? ĐĂNG NHẬP',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF59E0B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
