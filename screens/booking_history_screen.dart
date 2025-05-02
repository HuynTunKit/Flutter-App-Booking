import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_booking_app/screens/booking_detail_screen.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
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
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lịch Sử Đặt Phòng'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Text(
              'Vui lòng đăng nhập để xem lịch sử đặt phòng của bạn.',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
      );
    }

    print('ID người dùng hiện tại: ${user.uid}');
    print('Email người dùng: ${user.email}');
    print('Đang lấy lịch sử đặt phòng cho người dùng: ${user.uid}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch Sử Đặt Phòng',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user.uid)
              .orderBy('bookingTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Lỗi lấy lịch sử đặt phòng: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lỗi lấy lịch sử đặt phòng:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print(
                  'Không tìm thấy lịch sử đặt phòng cho người dùng: ${user.uid}');
              return Center(
                child: Text(
                  'Không tìm thấy lịch sử đặt phòng.',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
              );
            }

            final bookings = snapshot.data!.docs;
            print(
                'Tìm thấy ${bookings.length} lượt đặt phòng cho người dùng: ${user.uid}');
            for (var booking in bookings) {
              print('ID đặt phòng: ${booking.id}, Dữ liệu: ${booking.data()}');
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final bookingData = booking.data() as Map<String, dynamic>;
                final roomName = bookingData['roomName'] ?? 'Không rõ';
                final price = bookingData['price']?.toString() ?? 'N/A';
                final bookingTime = bookingData['bookingTime'] as Timestamp?;
                final checkInDate = bookingData['checkInDate'] as Timestamp?;
                final checkOutDate = bookingData['checkOutDate'] as Timestamp?;
                final paymentMethod =
                    bookingData['paymentMethod'] as String? ?? 'N/A';
                final bookingId =
                    bookingData['bookingId'] as String? ?? booking.id;

                final formattedBookingTime = bookingTime != null
                    ? DateFormat('dd/MM/yyyy HH:mm')
                        .format(bookingTime.toDate())
                    : 'N/A';
                final formattedCheckIn = checkInDate != null
                    ? DateFormat('yyyy-MM-dd').format(checkInDate.toDate())
                    : 'N/A';
                final formattedCheckOut = checkOutDate != null
                    ? DateFormat('yyyy-MM-dd').format(checkOutDate.toDate())
                    : 'N/A';

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        onTap: () {
                          if (bookingTime != null &&
                              checkInDate != null &&
                              checkOutDate != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailScreen(
                                  bookingId: bookingId,
                                  roomId: bookingData['roomId'] as String,
                                  roomName: roomName,
                                  price: int.parse(price),
                                  bookingTime: bookingTime,
                                  checkInDate: checkInDate,
                                  checkOutDate: checkOutDate,
                                  paymentMethod: paymentMethod,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Dữ liệu đặt phòng không đầy đủ.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        title: Text(
                          'Phòng: $roomName',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF9FAFB),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đặt vào: $formattedBookingTime',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              'Giá: $price VND',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              'Nhận Phòng: $formattedCheckIn',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              'Trả Phòng: $formattedCheckOut',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
