import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hotel_booking_app/screens/login_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Hàm hiển thị dialog chỉnh sửa hồ sơ
  Future<void> _showEditProfileDialog(BuildContext context,
      Map<String, dynamic> userData, String userId) async {
    final TextEditingController nameController = TextEditingController(
        text: userData['name']?.isNotEmpty == true
            ? userData['name']
            : 'Người Dùng');
    final TextEditingController emailController =
        TextEditingController(text: userData['email'] ?? '');
    final TextEditingController phoneController =
        TextEditingController(text: userData['phone'] ?? '');
    final TextEditingController dobController = TextEditingController(
        text: userData['dateOfBirth'] != null
            ? DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(userData['dateOfBirth']))
            : '');

    DateTime? selectedDate;
    if (userData['dateOfBirth'] != null) {
      selectedDate = DateTime.tryParse(userData['dateOfBirth']);
    }

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Thay đổi màu nền dialog thành gradient giống nền chính
          backgroundColor: Colors.transparent, // Để gradient hiển thị
          contentPadding: EdgeInsets.zero, // Loại bỏ padding mặc định
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Thêm padding bên trong
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tiêu đề
                    Center(
                      child: Text(
                        'Chỉnh Sửa Hồ Sơ',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF9FAFB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Trường nhập liệu: Tên
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Tên',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Trường nhập liệu: Email
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF9FAFB),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // Trường nhập liệu: Số điện thoại
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: 'Số Điện Thoại',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF9FAFB),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    // Trường nhập liệu: Ngày sinh
                    TextField(
                      controller: dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Ngày Sinh (dd/MM/yyyy)',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFF59E0B),
                          ),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              dobController.text =
                                  DateFormat('dd/MM/yyyy').format(picked);
                              selectedDate = picked;
                            }
                          },
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nút hành động
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Đóng dialog
                          },
                          child: Text(
                            'Hủy',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent, // Đổi màu thành đỏ
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            final newEmail = emailController.text.trim();
                            final newPhone = phoneController.text.trim();
                            final newDob = selectedDate != null
                                ? selectedDate!.toIso8601String()
                                : null;

                            // Kiểm tra dữ liệu đầu vào
                            if (newName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Tên không được để trống')),
                              );
                              return;
                            }

                            if (newEmail.isNotEmpty &&
                                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(newEmail)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Email không hợp lệ')),
                              );
                              return;
                            }

                            if (newPhone.isNotEmpty &&
                                !RegExp(r'^\+?[0-9]{10,12}$')
                                    .hasMatch(newPhone)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Số điện thoại không hợp lệ')),
                              );
                              return;
                            }

                            try {
                              // Chuẩn bị dữ liệu để cập nhật
                              final updateData = <String, dynamic>{};
                              if (newName.isNotEmpty)
                                updateData['name'] = newName;
                              if (newEmail.isNotEmpty)
                                updateData['email'] = newEmail;
                              if (newPhone.isNotEmpty)
                                updateData['phone'] = newPhone;
                              if (newDob != null)
                                updateData['dateOfBirth'] = newDob;

                              // Cập nhật dữ liệu vào Firestore
                              if (updateData.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .update(updateData);

                                // Nếu email thay đổi, gửi email xác nhận để cập nhật
                                if (newEmail.isNotEmpty &&
                                    newEmail !=
                                        FirebaseAuth
                                            .instance.currentUser?.email) {
                                  await FirebaseAuth.instance.currentUser
                                      ?.verifyBeforeUpdateEmail(newEmail);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Đã gửi email xác nhận. Vui lòng kiểm tra email để cập nhật.'),
                                    ),
                                  );
                                }
                              }

                              // Đóng dialog
                              Navigator.of(context).pop();

                              // Làm mới màn hình bằng cách điều hướng lại chính ProfileScreen
                              Navigator.pushReplacementNamed(
                                  context, '/profile');
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Lỗi cập nhật hồ sơ: $e')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Lưu',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hồ Sơ',
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
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi tải thông tin: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      'Không tìm thấy thông tin người dùng.',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String name = userData['name']?.isNotEmpty == true
                    ? userData['name']
                    : 'Người Dùng';
                final String email = userData['email'] ?? 'Chưa cập nhật';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin người dùng
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFFF59E0B),
                              child: Text(
                                name[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF9FAFB),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Khách hàng thân thiết',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFF59E0B)),
                              onPressed: () {
                                _showEditProfileDialog(
                                    context, userData, user.uid);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tài khoản của tôi
                    Text(
                      'Tài Khoản Của Tôi',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.book_online,
                      title: 'Đặt Phòng Của Tôi',
                      onTap: () {
                        Navigator.pushNamed(context, '/booking_history');
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.favorite_border,
                      title: 'Khách Sạn Yêu Thích',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển.'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cài đặt
                    Text(
                      'Cài Đặt',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications,
                      title: 'Thông Báo',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển.'),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.language,
                      title: 'Ngôn Ngữ',
                      subtitle: 'Tiếng Việt',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển.'),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.location_on,
                      title: 'Khu Vực',
                      subtitle: 'TP Hồ Chí Minh',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển.'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Thông tin
                    Text(
                      'Thông Tin',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.help,
                      title: 'Hỏi Đáp',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển.'),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.policy,
                      title: 'Điều Khoản & Chính Sách',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng đang phát triển.'),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.info,
                      title: 'Phiên Bản',
                      subtitle: '1.0.0',
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),

                    // Đăng xuất
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Đăng Xuất',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF59E0B)),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFFF9FAFB),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
