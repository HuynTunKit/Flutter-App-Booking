import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../room.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String currentUserRole = 'user';
  late TabController _tabController;

  // Danh sách các imagePath từ pubspec.yaml
  final List<String> imagePaths = [
    'assets/images/A01.jpg',
    'assets/images/A02.jpg',
    'assets/images/A03.jpg',
    'assets/images/D01.jpg',
    'assets/images/D02.jpg',
    'assets/images/D03.jpg',
    'assets/images/S01.jpg',
    'assets/images/S02.jpg',
    'assets/images/S03.jpg',
    'assets/images/add1.jpg',
    'assets/images/add2.jpg',
    'assets/images/placeholder_room.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            currentUserRole = userDoc.data()!['role'] ?? 'user';
          });
          if (currentUserRole != 'admin') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Bạn cần vai trò admin để truy cập.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không tìm thấy thông tin người dùng.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kiểm tra vai trò: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tiếp tục.')),
      );
    }
  }

  Future<void> _createUser() async {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController dateOfBirthController = TextEditingController();
    final TextEditingController adminPasswordController =
        TextEditingController();
    String role = 'user';

    // Lưu thông tin admin hiện tại
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tiếp tục.')),
      );
      return;
    }

    // Yêu cầu người dùng nhập lại mật khẩu admin
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Xác nhận mật khẩu Admin',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vui lòng nhập mật khẩu của tài khoản ${currentUser.email} để tiếp tục:',
              style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adminPasswordController,
              style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
              decoration: InputDecoration(
                labelText: 'Mật khẩu Admin',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xác nhận',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Thêm tài khoản mới',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Tên',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateOfBirthController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Ngày sinh (YYYY-MM-DD)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                underline: Container(
                  height: 1,
                  color: const Color(0xFFF59E0B),
                ),
                onChanged: (value) => setState(() => role = value!),
                items: ['user', 'admin']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role, style: GoogleFonts.poppins()),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Tạo tài khoản mới
                final userCredential =
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );

                // Lưu thông tin người dùng vào Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .set({
                  'uid': userCredential.user!.uid,
                  'email': emailController.text,
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'dateOfBirth': dateOfBirthController.text,
                  'role': role,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                // Đăng xuất tài khoản mới
                await FirebaseAuth.instance.signOut();

                // Đăng nhập lại tài khoản admin
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: currentUser.email!,
                  password: adminPasswordController.text,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Tài khoản đã được tạo thành công!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
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
              'Thêm',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser(UserModel user) async {
    final TextEditingController nameController =
        TextEditingController(text: user.name);
    final TextEditingController phoneController =
        TextEditingController(text: user.phone);
    final TextEditingController dateOfBirthController =
        TextEditingController(text: user.dateOfBirth);
    String role = user.role;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Sửa tài khoản',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Email: ${user.email} (Không thể sửa)',
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Tên',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateOfBirthController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Ngày sinh (YYYY-MM-DD)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                underline: Container(
                  height: 1,
                  color: const Color(0xFFF59E0B),
                ),
                onChanged: (value) => setState(() => role = value!),
                items: ['user', 'admin']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role, style: GoogleFonts.poppins()),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedUser = UserModel(
                  uid: user.uid,
                  email: user.email,
                  name: nameController.text,
                  phone: phoneController.text,
                  dateOfBirth: dateOfBirthController.text,
                  role: role,
                  createdAt: user.createdAt,
                  updatedAt: DateTime.now(),
                );
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .update(updatedUser.toMap());
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
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
              'Cập nhật',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Xóa tài khoản',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản này?',
          style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(uid).delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _createRoom() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController typeController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    bool isAvailable = true;
    String? selectedImagePath = imagePaths.first; // Giá trị mặc định

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Thêm phòng mới',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Tên phòng',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Loại phòng (Standard/Deluxe/Suite)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Giá (VND)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedImagePath,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                underline: Container(
                  height: 1,
                  color: const Color(0xFFF59E0B),
                ),
                onChanged: (value) {
                  setState(() {
                    selectedImagePath = value;
                  });
                },
                items: imagePaths
                    .map((path) => DropdownMenuItem(
                          value: path,
                          child: Text(
                            path.split('/').last,
                            style: GoogleFonts.poppins(),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Khả dụng: ',
                    style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                  ),
                  Checkbox(
                    value: isAvailable,
                    onChanged: (value) => setState(() => isAvailable = value!),
                    activeColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Kiểm tra đầu vào
                if (nameController.text.isEmpty ||
                    typeController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng điền đầy đủ thông tin.')),
                  );
                  return;
                }
                double price;
                try {
                  price = double.parse(priceController.text);
                  if (price <= 0) {
                    throw Exception('Giá phải lớn hơn 0.');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Giá phải là một số hợp lệ.')),
                  );
                  return;
                }

                final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
                final newRoom = Room(
                  id: roomId,
                  name: nameController.text,
                  type: typeController.text,
                  price: price,
                  isAvailable: isAvailable,
                  imagePath: selectedImagePath!,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await _firestore
                    .collection('rooms')
                    .doc(roomId)
                    .set(newRoom.toMap());
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Phòng đã được thêm thành công!')),
                );
              } catch (e) {
                debugPrint('Lỗi thêm phòng: $e');
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Thêm',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRoom(Room room) async {
    final TextEditingController nameController =
        TextEditingController(text: room.name);
    final TextEditingController typeController =
        TextEditingController(text: room.type);
    final TextEditingController priceController =
        TextEditingController(text: room.price.toString());
    bool isAvailable = room.isAvailable;
    String? selectedImagePath = room.imagePath;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Sửa phòng',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Tên phòng',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Loại phòng (Standard/Deluxe/Suite)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                decoration: InputDecoration(
                  labelText: 'Giá (VND)',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedImagePath,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E293B),
                style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                underline: Container(
                  height: 1,
                  color: const Color(0xFFF59E0B),
                ),
                onChanged: (value) {
                  setState(() {
                    selectedImagePath = value;
                  });
                },
                items: imagePaths
                    .map((path) => DropdownMenuItem(
                          value: path,
                          child: Text(
                            path.split('/').last,
                            style: GoogleFonts.poppins(),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              if (selectedImagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    selectedImagePath!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.red),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Khả dụng: ',
                    style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                  ),
                  Checkbox(
                    value: isAvailable,
                    onChanged: (value) => setState(() => isAvailable = value!),
                    activeColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Kiểm tra đầu vào
                if (nameController.text.isEmpty ||
                    typeController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng điền đầy đủ thông tin.')),
                  );
                  return;
                }
                double price;
                try {
                  price = double.parse(priceController.text);
                  if (price <= 0) {
                    throw Exception('Giá phải lớn hơn 0.');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Giá phải là một số hợp lệ.')),
                  );
                  return;
                }

                final updatedRoom = Room(
                  id: room.id,
                  name: nameController.text,
                  type: typeController.text,
                  price: price,
                  isAvailable: isAvailable,
                  imagePath: selectedImagePath!,
                  createdAt: room.createdAt,
                  updatedAt: DateTime.now(),
                );
                await _firestore
                    .collection('rooms')
                    .doc(room.id)
                    .update(updatedRoom.toMap());
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Phòng đã được cập nhật thành công!')),
                );
              } catch (e) {
                debugPrint('Lỗi cập nhật phòng: $e');
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cập nhật',
              style: GoogleFonts.poppins(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(String roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Xóa phòng',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa phòng này?',
          style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('rooms').doc(roomId).delete();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserRole != 'admin') {
      return Scaffold(
        body: Center(
          child: Text(
            'Bạn không có quyền truy cập màn hình này.',
            style: GoogleFonts.poppins(
              color: Colors.redAccent,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          'Quản lý Admin',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF9FAFB),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF59E0B),
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(),
          labelColor: const Color(0xFFF59E0B),
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'Người dùng'),
            Tab(text: 'Phòng'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFF59E0B)),
            onPressed: () {
              if (_tabController.index == 0) {
                _createUser();
              } else {
                _createRoom();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Đã xảy ra lỗi.',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        title: Text(
                          user.name,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFF9FAFB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email: ${user.email}',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Vai trò: ${user.role}',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'SĐT: ${user.phone}',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFF59E0B)),
                              onPressed: () => _updateUser(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => _deleteUser(user.uid),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('rooms').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Đã xảy ra lỗi.',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rooms = snapshot.data!.docs
                    .map((doc) => Room.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            room.imagePath,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.red),
                            ),
                          ),
                        ),
                        title: Text(
                          room.name,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFF9FAFB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loại: ${room.type}',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Giá: ${room.price.toStringAsFixed(0)} VND',
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              room.isAvailable ? "Khả dụng" : "Không khả dụng",
                              style: GoogleFonts.poppins(
                                color: room.isAvailable
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFFF59E0B)),
                              onPressed: () => _updateRoom(room),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => _deleteRoom(room.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
