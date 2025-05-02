import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../room.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _selectedType = 'Tất Cả';
  double _minPrice = 400000;
  double _maxPrice = 1200000;
  bool _onlyAvailable = true;
  String _searchKeyword = '';
  final TextEditingController _minPriceController =
      TextEditingController(text: '400000');
  final TextEditingController _maxPriceController =
      TextEditingController(text: '1200000');
  final TextEditingController _searchController = TextEditingController();

  // Ánh xạ để chuẩn hóa loại phòng từ Firestore
  final Map<String, String> _typeMapping = {
    'Tất Cả': 'Tất Cả',
    'Tiêu Chuẩn': 'Tiêu Chuẩn',
    'Thượng Hạng': 'Thượng Hạng',
    'Cao Cấp': 'Cao Cấp',
    'Standard': 'Tiêu Chuẩn',
    'Suite': 'Thượng Hạng',
    'Deluxe': 'Cao Cấp',
  };

  @override
  void initState() {
    super.initState();
    _minPriceController.addListener(() {
      setState(() {
        _minPrice = double.tryParse(_minPriceController.text) ?? 400000;
      });
    });
    _maxPriceController.addListener(() {
      setState(() {
        _maxPrice = double.tryParse(_maxPriceController.text) ?? 1200000;
      });
    });
    _searchController.addListener(() {
      setState(() {
        _searchKeyword = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedType = 'Tất Cả';
      _minPrice = 400000;
      _maxPrice = 1200000;
      _onlyAvailable = true;
      _searchKeyword = '';
      _minPriceController.text = '400000';
      _maxPriceController.text = '1200000';
      _searchController.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tìm Kiếm Phòng',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tìm Theo Tên',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên phòng (ví dụ: Tiêu Chuẩn 01)',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFF9FAFB),
                        ),
                        suffixIcon: _searchKeyword.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFFF9FAFB),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                      ),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lọc Theo Loại Phòng',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF9FAFB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFF59E0B),
                        ),
                        underline: const SizedBox(),
                        items:
                            ['Tất Cả', 'Tiêu Chuẩn', 'Thượng Hạng', 'Cao Cấp']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFF9FAFB),
                                        ),
                                      ),
                                    ))
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Khoảng Giá (VND)',
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
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Giá Tối Thiểu',
                              labelStyle: GoogleFonts.poppins(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Giá Tối Đa',
                              labelStyle: GoogleFonts.poppins(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _onlyAvailable,
                          onChanged: (value) {
                            setState(() {
                              _onlyAvailable = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFFF59E0B),
                          checkColor: Colors.white,
                        ),
                        Text(
                          'Chỉ hiển thị phòng còn trống',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFFF9FAFB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _resetFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Đặt Lại Bộ Lọc',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('rooms').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Lỗi lấy danh sách phòng.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF9FAFB),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF59E0B),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'Không có phòng nào.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF9FAFB),
                        ),
                      ),
                    );
                  }

                  final rooms = snapshot.data!.docs
                      .map((doc) => Room.fromFirestore(doc))
                      .where((room) {
                    // Chuẩn hóa loại phòng từ Firestore
                    String normalizedType =
                        _typeMapping[room.type] ?? room.type;
                    bool matchesType = _selectedType == 'Tất Cả' ||
                        normalizedType == _selectedType;
                    bool matchesPrice =
                        room.price >= _minPrice && room.price <= _maxPrice;
                    bool matchesAvailability =
                        !_onlyAvailable || room.isAvailable;
                    bool matchesKeyword = _searchKeyword.isEmpty ||
                        room.name.toLowerCase().contains(_searchKeyword);
                    return matchesType &&
                        matchesPrice &&
                        matchesAvailability &&
                        matchesKeyword;
                  }).toList();

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lọc',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: rooms.isEmpty
                            ? Center(
                                child: Text(
                                  'Không có phòng nào khớp với tiêu chí của bạn.',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF9FAFB),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: rooms.length,
                                itemBuilder: (context, index) {
                                  final room = rooms[index];
                                  return Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: const Color(0xFF1E293B),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/room_detail',
                                          arguments: {
                                            'id': room.id,
                                            'name': room.name,
                                            'type': room.type,
                                            'price': room.price,
                                            'isAvailable': room.isAvailable,
                                            'imagePath': room.imagePath,
                                          },
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.asset(
                                                room.imagePath,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  print(
                                                      'Lỗi tải hình ảnh: ${room.imagePath}, lỗi: $error');
                                                  return Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
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
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                          0xFFF9FAFB),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Loại: ${_typeMapping[room.type] ?? room.type}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Giá: ${room.price.toStringAsFixed(0)} VND',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ),
                                                  if (room.isAvailable)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4),
                                                      child: Text(
                                                        'Khả dụng',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
