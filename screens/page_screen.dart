// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_booking_app/screens/login_screen.dart';
import 'package:hotel_booking_app/screens/register_screen.dart';

class PageScreen extends StatelessWidget {
  const PageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Nếu đang kiểm tra trạng thái đăng nhập, hiển thị màn hình tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          );
        }

        // Nếu người dùng đã đăng nhập, điều hướng đến HomeScreen
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/home');
          });
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          );
        }

        // Nếu người dùng chưa đăng nhập, hiển thị giao diện PageScreen
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/welcome_background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black26,
                  BlendMode.darken,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Xíu HOTEL',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nâng tầm trải nghiệm',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, '/login'); // Sử dụng pushNamed
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 18, 214, 83),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Bắt đầu',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                          context, '/register'); // Sử dụng pushNamed
                    },
                    child: Text(
                      'Chưa có tài khoản ? Hãy đăng ký',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
