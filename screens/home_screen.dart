import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../room.dart';
import 'room_detail_screen.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _searchKeyword = '';
  String? _selectedType;
  bool? _selectedAvailability;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String currentUserRole = 'user';
  String currentUserName = ''; // Bỏ mặc định "Khách"
  late Future<void> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    _userRoleFuture = _checkUserRole();
    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
      });
    });

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
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Checking role for UID: ${user.uid}');
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));

        if (docSnapshot.exists) {
          final userModel = UserModel.fromMap(docSnapshot.data()!, user.uid);
          print(
              'User role: ${userModel.role}, Name: ${userModel.name}, Document ID: ${docSnapshot.id}');
          setState(() {
            currentUserRole = userModel.role.toLowerCase();
            currentUserName = userModel.name.isNotEmpty
                ? userModel.name
                : 'Người Dùng'; // Thay "Khách" bằng "Người Dùng" nếu không có tên
          });
        } else {
          print('No user document found for UID: ${user.uid}');
          setState(() {
            currentUserRole = 'user';
            currentUserName = 'Người Dùng'; // Thay "Khách" bằng "Người Dùng"
          });
        }
      } else {
        print('No user logged in');
        setState(() {
          currentUserRole = 'user';
          currentUserName = 'Người Dùng'; // Thay "Khách" bằng "Người Dùng"
        });
      }
    } catch (e, stackTrace) {
      print('Error checking user role: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        currentUserRole = 'user';
        currentUserName = 'Người Dùng'; // Thay "Khách" bằng "Người Dùng"
      });
    }
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFF1E293B),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lọc Phòng',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF9FAFB),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loại Phòng',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF9FAFB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: _selectedType,
                    hint: Text(
                      'Chọn Loại Phòng',
                      style:
                          GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'Tất Cả Loại Phòng',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFF9FAFB)),
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Standard',
                        child: Text(
                          'Tiêu Chuẩn',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFF9FAFB)),
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Deluxe',
                        child: Text(
                          'Cao Cấp',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFF9FAFB)),
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Suite',
                        child: Text(
                          'Thượng Hạng',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFF9FAFB)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedType = value;
                      });
                      setState(() {
                        _selectedType = value;
                      });
                    },
                    style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                    dropdownColor: const Color(0xFF1E293B),
                    underline: Container(
                      height: 1,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Trạng Thái',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF9FAFB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<bool?>(
                    value: _selectedAvailability,
                    hint: Text(
                      'Chọn Trạng Thái',
                      style:
                          GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text(
                          'Tất Cả',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFF9FAFB)),
                        ),
                      ),
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text(
                          'Còn Trống',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFF9FAFB)),
                        ),
                      ),
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text(
                          'Đã Đặt',
                          style: GoogleFonts.poppins(
                              color: const Color(0xFFF9FAFB)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedAvailability = value;
                      });
                      setState(() {
                        _selectedAvailability = value;
                      });
                    },
                    style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                    dropdownColor: const Color(0xFF1E293B),
                    underline: Container(
                      height: 1,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedType = null;
                        _selectedAvailability = null;
                      });
                      setState(() {
                        _selectedType = null;
                        _selectedAvailability = null;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Đặt Lại Bộ Lọc',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFFF1F5F9),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFF5E6FF), // Màu giống hình ảnh
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<void>(
                    future: _userRoleFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                            color: Colors.white);
                      }
                      if (snapshot.hasError) {
                        print('Error in FutureBuilder: ${snapshot.error}');
                        return Text(
                          'Lỗi tải thông tin',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        );
                      }
                      print('Current user name in Drawer: $currentUserName');
                      return Text(
                        currentUserName, // Hiển thị tên thực tế từ Firestore
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF9FAFB),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.grey),
              title: Text(
                'Xem và Chỉnh Sửa Hồ Sơ',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            FutureBuilder<void>(
              future: _userRoleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Đang kiểm tra quyền...'),
                  );
                }
                if (snapshot.hasError) {
                  print('Error in FutureBuilder: ${snapshot.error}');
                  return const ListTile(
                    leading: Icon(Icons.error, color: Colors.red),
                    title: Text('Lỗi kiểm tra quyền'),
                  );
                }
                print('Current user role in Drawer: $currentUserRole');
                if (currentUserRole == 'admin') {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings,
                        color: Colors.grey),
                    title: Text(
                      'Quản lý Admin',
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/admin');
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.grey),
              title: Text(
                'Đổi Mật Khẩu',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                // Thêm logic đổi mật khẩu nếu cần
              },
            ),
            ListTile(
              leading: const Icon(Icons.group, color: Colors.grey),
              title: Text(
                'Mời Bạn Bè',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                // Thêm logic mời bạn bè nếu cần
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.grey),
              title: Text(
                'Tín Dụng & Phiếu Giảm Giá',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                // Thêm logic tín dụng và phiếu giảm giá nếu cần
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.grey),
              title: Text(
                'Trung Tâm Hỗ Trợ',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                // Thêm logic trung tâm hỗ trợ nếu cần
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.grey),
              title: Text(
                'Thanh Toán',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                // Thêm logic thanh toán nếu cần
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: Text(
                'Cài Đặt',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () {
                Navigator.pop(context);
                // Thêm logic cài đặt nếu cần
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: Text(
                'Đăng Xuất',
                style: GoogleFonts.poppins(color: Colors.black),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Xíu Hotel'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFF9FAFB)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0x33F59E0B),
                child: const Icon(
                  Icons.chat_bubble,
                  size: 24,
                  color: Color(0xFFF59E0B),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/chatbot');
              },
            ),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm phòng theo tên...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search,
                          size: 20, color: Colors.grey),
                      suffixIcon: _searchKeyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 20, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                    style: GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Khám phá thêm',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              'Những căn phòng lý tưởng không thể bỏ lỡ',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _showFilterOptions(context);
                        },
                        child: Text(
                          'Lọc',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFF59E0B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('rooms').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Lỗi lấy dữ liệu: ${snapshot.error}');
                    return Center(
                        child: Text(
                      'Lỗi lấy dữ liệu: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print('Không có phòng nào trong Firestore.');
                    return Center(
                      child: Text(
                        'Hiện tại không có phòng nào.',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  final rooms = snapshot.data!.docs
                      .map((doc) {
                        try {
                          final room = Room.fromFirestore(doc);
                          print(
                              'Phòng được lấy: ID=${doc.id}, Tên=${room.name}, Trạng thái=${room.isAvailable}, Hình ảnh=${room.imagePath}');
                          return room;
                        } catch (e) {
                          print('Lỗi ánh xạ phòng ${doc.id}: $e');
                          return null;
                        }
                      })
                      .where((room) => room != null)
                      .cast<Room>()
                      .where((room) {
                        final matchesKeyword = _searchKeyword.isEmpty ||
                            room.name.toLowerCase().contains(_searchKeyword);
                        final matchesType =
                            _selectedType == null || room.type == _selectedType;
                        final matchesAvailability =
                            _selectedAvailability == null ||
                                room.isAvailable == _selectedAvailability;
                        return matchesKeyword &&
                            matchesType &&
                            matchesAvailability;
                      })
                      .toList();

                  if (rooms.isEmpty) {
                    print('Không có phòng hợp lệ sau khi ánh xạ hoặc lọc.');
                    return Center(
                      child: Text(
                        'Không có phòng nào khớp với tìm kiếm hoặc bộ lọc của bạn.',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  print('Tổng số phòng hiển thị: ${rooms.length}');
                  _animationController.forward(from: 0);

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Card(
                            elevation: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            color: const Color(0xFF1E293B),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        RoomDetailScreen(
                                      id: room.id,
                                      name: room.name,
                                      type: room.type,
                                      price: room.price,
                                      isAvailable: room.isAvailable,
                                      imagePath: room.imagePath,
                                    ),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
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
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.asset(
                                            room.imagePath,
                                            width: 120,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              print(
                                                  'Lỗi tải hình ảnh từ assets: ${room.imagePath}, lỗi: $error');
                                              return Container(
                                                width: 120,
                                                height: 100,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.red,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Icon(
                                            Icons.favorite_border,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            room.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFF9FAFB),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Loại: ${room.type == 'Standard' ? 'Tiêu Chuẩn' : room.type == 'Deluxe' ? 'Cao Cấp' : 'Thượng Hạng'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Giá: ${room.price.toStringAsFixed(0)} VND',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFF9FAFB),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            room.isAvailable
                                                ? 'Còn Trống'
                                                : 'Đã Đặt',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: room.isAvailable
                                                  ? Colors.green
                                                  : Colors.redAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFFF59E0B),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/booking_history');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Phòng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Lịch Sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ Sơ',
          ),
        ],
      ),
    );
  }
}
