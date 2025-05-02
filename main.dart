import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart' as login;
import 'screens/home_screen.dart' as home_screen;
import 'screens/register_screen.dart' as register;
import 'screens/room_detail_screen.dart';
import 'screens/booking_history_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart' as admin_screen;
import 'screens/page_screen.dart'; // Thêm import cho PageScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAgaaZfEPlA6lIGjxaw0E1F0jYfSRMYCaQ",
          authDomain: "hotelappbooking-c67d6.firebaseapp.com",
          projectId: "hotelappbooking-c67d6",
          storageBucket: "hotelappbooking-c67d6.firebasestorage.app",
          messagingSenderId: "1095711144991",
          appId: "1:1095711144991:web:044c1982274d2a99c8e92a",
          measurementId: "G-QX9W2QGT8J",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    runApp(const HotelBookingApp());
  } catch (e) {
    print('Error initializing Firebase: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing Firebase: $e'),
        ),
      ),
    ));
  }
}

class HotelBookingApp extends StatelessWidget {
  const HotelBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hotel Booking',
      theme: ThemeData(
        primaryColor: const Color(0xFFF59E0B),
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: const Color(0xFFF9FAFB),
                displayColor: const Color(0xFFF9FAFB),
              ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF9FAFB),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF9FAFB)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
      home: const PageScreen(), // Thay SplashScreen bằng PageScreen
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/page': // Thêm route cho PageScreen
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const PageScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/login':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const login.LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/home':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const home_screen.HomeScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/register':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const register.RegisterScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/room_detail':
            final args = settings.arguments as Map<String, dynamic>;
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RoomDetailScreen(
                id: args['id'],
                name: args['name'],
                type: args['type'],
                price: args['price'],
                isAvailable: args['isAvailable'],
                imagePath: args['imagePath'],
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/booking_history':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const BookingHistoryScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/chatbot':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ChatbotScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/search':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SearchScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/profile':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ProfileScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          case '/admin':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const admin_screen.AdminScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          default:
            return null;
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
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
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/home');
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
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
      },
    );
  }
}
