// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String roomId;
  final String roomName;
  final double price;
  final Timestamp bookingTime;
  final Timestamp checkInDate;
  final Timestamp checkOutDate;
  final String paymentMethod;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.roomId,
    required this.roomName,
    required this.price,
    required this.bookingTime,
    required this.checkInDate,
    required this.checkOutDate,
    required this.paymentMethod,
  });

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool? hasRated;
  String? imagePath;
  String? roomType;
  String? address;
  String? hours;
  String? phone;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
    _fetchRatingStatus();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      setState(() {
        imagePath = bookingDoc['imagePath'] ?? 'assets/images/placeholder.jpg';
        roomType = bookingDoc['roomType'] ?? 'Tiêu Chuẩn';
        address =
            bookingDoc['address'] ?? '123 Đường 45, Phường Thảo Điền, TP HCM';
        hours = bookingDoc['hours'] ?? '4 giờ';
        phone = bookingDoc['phone'] ?? '+84 922110570';
      });
    } catch (e) {
      print('Lỗi khi lấy chi tiết đặt phòng: $e');
      setState(() {
        imagePath = 'assets/images/placeholder.jpg';
        roomType = 'Tiêu Chuẩn';
        address = '123 Đường 45, Phường Thảo Điền, TP HCM';
        hours = '4 giờ';
        phone = '+84 922110570';
      });
    }
  }

  Future<void> _fetchRatingStatus() async {
    try {
      DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      setState(() {
        hasRated = bookingDoc['hasRated'] ?? false;
      });
    } catch (e) {
      print('Lỗi khi lấy trạng thái đánh giá: $e');
      setState(() {
        hasRated = false;
      });
    }
  }

  Future<bool?> _showConfirmDialog(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          title,
          style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Xác Nhận',
              style: GoogleFonts.poppins(color: const Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingDialog() async {
    double rating = 0;
    final TextEditingController commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Đánh Giá "${widget.roomName}"',
          style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 30,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Color(0xFFF59E0B),
                ),
                onRatingUpdate: (value) {
                  rating = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Bình luận (không bắt buộc)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 3,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (rating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng chọn điểm đánh giá.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(
              'Gửi',
              style: GoogleFonts.poppins(color: const Color(0xFFF59E0B)),
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await FirebaseFirestore.instance.collection('ratings').add({
        'roomId': widget.roomId,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'bookingId': widget.bookingId,
        'rating': rating,
        'comment': commentController.text,
        'timestamp': Timestamp.now(),
      });

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'hasRated': true,
      });

      setState(() {
        hasRated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đánh giá đã được gửi thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gửi đánh giá: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final formattedCheckIn =
        DateFormat('HH:mm - dd/MM/yyyy').format(widget.checkInDate.toDate());
    final formattedCheckOut =
        DateFormat('HH:mm - dd/MM/yyyy').format(widget.checkOutDate.toDate());
    final formattedBookingTime =
        DateFormat('dd/MM/yyyy HH:mm').format(widget.bookingTime.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi Tiết Đặt Phòng',
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông báo hoàn thành
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cảm ơn bạn đã đặt phòng và đánh giá khách sạn!',
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Lựa Chọn Của Bạn
                Text(
                  'Lựa Chọn Của Bạn',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imagePath == null
                              ? Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : Image.asset(
                                  imagePath!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        'Lỗi tải hình ảnh: $imagePath, lỗi: $error');
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                        size: 40,
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.roomName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF9FAFB),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Loại phòng: $roomType',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Địa chỉ: $address',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hours ?? '4 giờ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Thông Tin Nhận Phòng
                Text(
                  'Thông Tin Nhận Phòng',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Mã đặt phòng', widget.bookingId),
                        _buildInfoRow(
                            'Số điện thoại', phone ?? '+84 922110570'),
                        _buildInfoRow('Họ tên', user?.email ?? 'Khách'),
                        _buildInfoRow('Nhận phòng', formattedCheckIn),
                        _buildInfoRow('Trả phòng', formattedCheckOut),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Chi Tiết Thanh Toán
                Text(
                  'Chi Tiết Thanh Toán',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Trạng thái', 'Đã thanh toán',
                            valueColor: Colors.green),
                        _buildInfoRow(
                            'Hình thức thanh toán', widget.paymentMethod),
                        _buildInfoRow('Tiền phòng',
                            '${NumberFormat("#,##0", "vi_VN").format(widget.price)}đ'),
                        _buildInfoRow('Ưu đãi',
                            '-${NumberFormat("#,##0", "vi_VN").format(10000)}đ'),
                        const Divider(color: Colors.grey),
                        _buildInfoRow(
                          'Tổng thanh toán',
                          '${NumberFormat("#,##0", "vi_VN").format(widget.price - 10000)}đ',
                          valueColor: const Color(0xFFF59E0B),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Chính Sách Hủy Phòng
                Text(
                  'Chính Sách Hủy Phòng',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Hủy miễn phí trước 13:00, ${DateFormat('dd/MM/yyyy').format(widget.checkInDate.toDate())}.\n'
                      'Tới đúng vị trí Điều khoản và Chính sách đặt phòng.\n'
                      'Dịch vụ hỗ trợ khách hàng - Liên hệ ngay.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Hủy Đặt và Đánh Giá
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (hasRated ==
                        false) // Chỉ hiển thị nút Đánh Giá nếu chưa đánh giá
                      ElevatedButton(
                        onPressed: _showRatingDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(150, 50),
                        ),
                        child: Text(
                          'Đánh Giá',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        final bool? confirmed = await _showConfirmDialog(
                          context,
                          'Xác Nhận Hủy Đặt',
                          'Bạn có chắc chắn muốn hủy đặt phòng cho "${widget.roomName}"?',
                        );

                        if (confirmed != true) return;

                        try {
                          print('Đang hủy đặt phòng: ${widget.bookingId}');
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(widget.bookingId)
                              .delete();
                          await FirebaseFirestore.instance
                              .collection('rooms')
                              .doc(widget.roomId)
                              .update({'isAvailable': true});
                          print(
                              'Đặt phòng ${widget.bookingId} đã được xóa thành công');

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hủy đặt phòng thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Quay lại màn hình trước đó sau khi hủy
                          Navigator.pop(context);
                        } catch (e) {
                          print('Lỗi hủy đặt phòng: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi hủy đặt phòng: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(150, 50),
                      ),
                      child: Text(
                        'Hủy Đặt',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: valueColor ?? const Color(0xFFF9FAFB),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
