import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RoomDetailScreen extends StatefulWidget {
  final String id;
  final String name;
  final String type;
  final double price;
  final bool isAvailable;
  final String imagePath;

  const RoomDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.isAvailable,
    required this.imagePath,
  });

  @override
  _RoomDetailScreenState createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late bool _isAvailable;
  bool _isLoading = true;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  double _averageRating = 0;
  String? _selectedPaymentMethod;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final List<String> _paymentMethods = [
    'Thanh Toán Tiền Mặt',
    'Ngân Hàng Liên Kết'
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoomStatus();
    _fetchAverageRating();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoomStatus() async {
    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.id)
          .get();

      if (roomDoc.exists) {
        final data = roomDoc.data();
        if (data != null && data.containsKey('isAvailable')) {
          setState(() {
            _isAvailable = data['isAvailable'] as bool;
            _isLoading = false;
          });
          print('Trạng thái phòng ${widget.id}: isAvailable = $_isAvailable');
        } else {
          throw Exception(
              'Dữ liệu phòng không hợp lệ: Thiếu trường isAvailable');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy phòng.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi lấy trạng thái phòng: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lấy trạng thái phòng: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _fetchAverageRating() async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .where('roomId', isEqualTo: widget.id)
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in ratingsSnapshot.docs) {
          final rating = doc['rating'];
          if (rating is num) {
            totalRating += rating.toDouble();
          }
        }
        setState(() {
          _averageRating = totalRating / ratingsSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Lỗi lấy điểm đánh giá trung bình: $e');
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isCheckIn) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (_checkInDate ?? DateTime.now())
          : (_checkOutDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isCheckIn) {
        _checkInDate = selectedDateTime;
        if (_checkOutDate != null &&
            _checkOutDate!.isBefore(selectedDateTime)) {
          _checkOutDate = null;
        }
      } else {
        _checkOutDate = selectedDateTime;
      }
    });
  }

  Future<bool> _checkDateConflict() async {
    if (_checkInDate == null || _checkOutDate == null) {
      return false;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: widget.id)
          .get();

      for (var doc in snapshot.docs) {
        final booking = doc.data();
        if (!booking.containsKey('checkInDate') ||
            !booking.containsKey('checkOutDate')) {
          print(
              'Booking ${doc.id} thiếu checkInDate hoặc checkOutDate, bỏ qua.');
          continue;
        }

        if (booking['checkInDate'] is! Timestamp ||
            booking['checkOutDate'] is! Timestamp) {
          print(
              'Booking ${doc.id} có checkInDate/checkOutDate không hợp lệ: $booking');
          continue;
        }

        final DateTime existingCheckIn =
            (booking['checkInDate'] as Timestamp).toDate();
        final DateTime existingCheckOut =
            (booking['checkOutDate'] as Timestamp).toDate();

        print('Kiểm tra xung đột: Đặt mới từ $_checkInDate đến $_checkOutDate');
        print('Đặt hiện có từ $existingCheckIn đến $existingCheckOut');

        if (_checkInDate!.isBefore(existingCheckOut) &&
            _checkOutDate!.isAfter(existingCheckIn)) {
          print('Xung đột thời gian phát hiện!');
          return true;
        }
      }
      print('Không có xung đột thời gian.');
      return false;
    } catch (e) {
      print('Lỗi kiểm tra xung đột thời gian: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kiểm tra thời gian: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return true; // Trả về true để dừng đặt phòng nếu có lỗi
    }
  }

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Người dùng chưa đăng nhập');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để đặt phòng.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (_checkInDate == null || _checkOutDate == null) {
      print('Chưa chọn ngày giờ nhận/trả phòng');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngày giờ nhận và trả phòng.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (_selectedPaymentMethod == null) {
      print('Chưa chọn phương thức thanh toán');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn phương thức thanh toán.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (_checkOutDate!.isBefore(_checkInDate!)) {
      print('Ngày giờ trả phòng không hợp lệ');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ngày giờ trả phòng phải sau ngày giờ nhận phòng.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final hasConflict = await _checkDateConflict();
    if (hasConflict) {
      print('Xung đột thời gian khi đặt phòng');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phòng này đã được đặt cho thời gian bạn chọn.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (_selectedPaymentMethod == 'Ngân Hàng Liên Kết') {
      print('Phương thức thanh toán không được hỗ trợ');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hình thức thanh toán này hiện chưa được hỗ trợ.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final bool? confirmed = await _showConfirmDialog(
      context,
      'Xác Nhận Đặt Phòng',
      'Bạn có chắc chắn muốn đặt "${widget.name}" từ ${DateFormat('HH:mm, dd/MM/yyyy').format(_checkInDate!)} đến ${DateFormat('HH:mm, dd/MM/yyyy').format(_checkOutDate!)} với hình thức thanh toán "${_selectedPaymentMethod}" không?',
    );

    if (confirmed != true) {
      print('Người dùng hủy đặt phòng');
      return;
    }

    try {
      print('Lưu đặt phòng cho người dùng: ${user.uid}, phòng: ${widget.name}');
      final bookingRef =
          await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'roomId': widget.id,
        'roomName': widget.name,
        'price': widget.price,
        'bookingTime': Timestamp.now(),
        'checkInDate': Timestamp.fromDate(_checkInDate!),
        'checkOutDate': Timestamp.fromDate(_checkOutDate!),
        'paymentMethod': _selectedPaymentMethod,
        'bookingId': '',
        'hasRated': false,
        'imagePath': widget.imagePath,
        'roomType': widget.type,
        'address': '123 Đường 45, Phường Thảo Điền, TP HCM',
        'hours': '4 giờ',
        'phone': '+84 922110570',
      });

      await bookingRef.update({'bookingId': bookingRef.id});
      print('Đặt phòng thành công với ID: ${bookingRef.id}');

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.id)
          .update({'isAvailable': false});

      setState(() {
        _isAvailable = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt phòng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      print('Lỗi đặt phòng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt phòng: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmDialog(
      BuildContext context, String title, String message) async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    widget.imagePath,
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.3,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print(
                          'Lỗi tải hình ảnh: ${widget.imagePath}, lỗi: $error');
                      return Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.3,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loại: ${widget.type}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Giá: ${NumberFormat("#,##0", "vi_VN").format(widget.price)} VND',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isAvailable ? 'Còn Trống' : 'Đã Đặt',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _isAvailable ? Colors.green : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        'Điểm Đánh Giá Trung Bình: ',
                        style: GoogleFonts.poppins(
                          fontSize: 14, // Giảm font size
                          color: Colors.grey[400],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: Text(
                        _averageRating > 0
                            ? '${_averageRating.toStringAsFixed(1)}/5'
                            : 'Chưa có đánh giá',
                        style: GoogleFonts.poppins(
                          fontSize: 14, // Giảm font size
                          color: const Color(0xFFF59E0B),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chọn Thời Gian Đặt Phòng',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () => _selectDateTime(context, true),
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _checkInDate == null
                                  ? 'Chọn Ngày Giờ Nhận Phòng'
                                  : 'Nhận: ${DateFormat('HH:mm, dd/MM').format(_checkInDate!)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () => _selectDateTime(context, false),
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _checkOutDate == null
                                  ? 'Chọn Ngày Giờ Trả Phòng'
                                  : 'Trả: ${DateFormat('HH:mm, dd/MM').format(_checkOutDate!)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chọn Phương Thức Thanh Toán',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF9FAFB),
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: _paymentMethods.map((method) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                method,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFFF9FAFB),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_selectedPaymentMethod == method)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton(
                      onPressed: _isAvailable ? _confirmBooking : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Chọn Phòng',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
