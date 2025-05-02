import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _lastSuggestedRoomType;
  String? _lastRoomTypeContext; // Lưu ngữ cảnh loại phòng gần nhất

  @override
  void initState() {
    super.initState();
    _loadUserBookingHistory();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserBookingHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _addMessage('Chatbot', 'Vui lòng đăng nhập để nhận gợi ý cá nhân hóa.');
      return;
    }

    try {
      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('bookingTime', descending: true)
          .limit(1)
          .get();

      if (bookingSnapshot.docs.isEmpty) {
        _addMessage('Chatbot',
            'Xin chào! Tôi có thể giúp bạn tìm phòng, kiểm tra giá, đặt lại phòng, hoặc hỏi về tiện ích. Bạn cần gì?');
        return;
      }

      final lastBooking = bookingSnapshot.docs.first.data();
      final roomName = lastBooking['roomName'] ?? 'một phòng';

      final roomSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('name', isEqualTo: roomName)
          .where('isAvailable', isEqualTo: true)
          .limit(1)
          .get();

      if (roomSnapshot.docs.isEmpty) {
        final roomData = await FirebaseFirestore.instance
            .collection('rooms')
            .where('name', isEqualTo: roomName)
            .limit(1)
            .get();

        if (roomData.docs.isNotEmpty) {
          final type = roomData.docs.first.data()['type'] as String?;
          if (type != null) {
            _lastSuggestedRoomType = _normalizeRoomType(type);
            _lastRoomTypeContext = _lastSuggestedRoomType;
            final displayType =
                _toVietnameseRoomType(_lastSuggestedRoomType ?? 'Unknown');
            _addMessage('Chatbot',
                'Xin chào! Tôi thấy lần trước bạn đã đặt "$roomName", nhưng hiện tại phòng này đã được đặt. Bạn có muốn tìm phòng loại "$displayType" khác không?');
          } else {
            _addMessage('Chatbot',
                'Xin chào! Tôi thấy lần trước bạn đã đặt "$roomName", nhưng hiện tại phòng này đã được đặt. Bạn muốn tìm loại phòng nào?');
          }
        } else {
          _addMessage('Chatbot',
              'Xin chào! Tôi thấy lần trước bạn đã đặt "$roomName", nhưng không tìm thấy thông tin phòng này. Bạn muốn tìm loại phòng nào?');
        }
        return;
      }

      final room = roomSnapshot.docs.first.data();
      _lastSuggestedRoomType =
          _normalizeRoomType(room['type'] as String? ?? '');
      _lastRoomTypeContext = _lastSuggestedRoomType;
      final displayType =
          _toVietnameseRoomType(_lastSuggestedRoomType ?? 'Unknown');
      _addMessage('Chatbot',
          'Xin chào! Tôi thấy lần trước bạn đã đặt "$roomName". Bạn có muốn đặt lại không?');
    } catch (e) {
      print('Lỗi tải lịch sử đặt phòng: $e');
      _addMessage('Chatbot', 'Đã xảy ra lỗi. Vui lòng thử lại sau.');
    }
  }

  String _normalizeRoomType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized == 'tiêu chuẩn' ||
        normalized == 'tieu chuan' ||
        normalized == 'standard') {
      return 'Standard';
    } else if (normalized == 'thượng hạng' ||
        normalized == 'thuong hang' ||
        normalized == 'suite') {
      return 'Suite';
    } else if (normalized == 'cao cấp' ||
        normalized == 'cao cap' ||
        normalized == 'deluxe') {
      return 'Deluxe';
    }
    return type;
  }

  String _toVietnameseRoomType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized == 'standard') {
      return 'Tiêu Chuẩn';
    } else if (normalized == 'suite') {
      return 'Thượng Hạng';
    } else if (normalized == 'deluxe') {
      return 'Cao Cấp';
    }
    return type;
  }

  void _addMessage(String sender, String message,
      {List<Map<String, dynamic>> rooms = const []}) {
    setState(() {
      _messages.add({
        'sender': sender,
        'message': message,
        'rooms': rooms,
      });
    });
    _animationController.forward(from: 0);
  }

  Future<void> _processUserInput(String input) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addMessage('Chatbot', 'Vui lòng đăng nhập để sử dụng chatbot.');
        return;
      }

      const apiKey = 'AIzaSyABfSpMk7YwyafR-NXCeRj-ctEwhqeZhNM';
      const url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

      final cleanInput = input.replaceAll(RegExp(r'[^\w\s]'), '');
      final prompt = '''
Bạn là một chatbot trong ứng dụng đặt phòng khách sạn, hỗ trợ người dùng bằng tiếng Việt. Người dùng hỏi: "$cleanInput".
Ứng dụng hỗ trợ các chức năng: tìm phòng (Tiêu Chuẩn = Standard, Thượng Hạng = Suite, Cao Cấp = Deluxe), đặt lại phòng dựa trên lịch sử, hỏi giá phòng, và hỏi về tiện ích/dịch vụ (wifi, hồ bơi, bữa sáng, ban công, máy lạnh, view đẹp).
Trả lời câu hỏi một cách tự nhiên và ngắn gọn, chỉ trả về câu trả lời (không giải thích).
### Hướng dẫn xử lý tiếng Việt:
- Hiểu các từ đồng nghĩa và cách diễn đạt tự nhiên trong tiếng Việt:
  - "Tìm phòng", "muốn phòng", "có phòng", "kiếm phòng", "phòng nào còn trống", "cần phòng", "phòng còn không", "muốn đặt", "phòng trống", "tôi muốn", "cho tôi" đều có nghĩa là tìm phòng.
  - "Đặt lại", "đặt thêm", "muốn đặt phòng cũ", "đặt giống lần trước", "đặt tiếp", "đặt thêm lần nữa", "lặp lại", "đặt giống" đều có nghĩa là đặt lại phòng.
  - "Giá", "bao nhiêu", "chi phí", "giá tiền", "bao nhiêu tiền", "hết bao nhiêu", "giá rẻ", "đắt không", "giá phòng", "bao gồm thuế chưa" đều có nghĩa là hỏi giá.
  - "Wifi", "view đẹp", "hồ bơi", "bữa sáng", "ban công", "máy lạnh", "dịch vụ", "tiện ích", "phòng tắm" liên quan đến hỏi tiện ích/dịch vụ.
  - "Phòng đẹp", "phòng rẻ", "phòng tốt", "phòng nào tốt nhất" liên quan đến tìm phòng với yêu cầu đặc biệt.
- Nếu câu hỏi có từ khóa liên quan đến loại phòng (Tiêu Chuẩn/Standard, Thượng Hạng/Suite, Cao Cấp/Deluxe), ưu tiên trả về "Tìm phòng [loại phòng tiếng Anh]".
- Nếu câu hỏi có yêu cầu đặc biệt (giá rẻ, view đẹp, v.v.), trả về "Tìm phòng [loại phòng tiếng Anh] [yêu cầu]".
- Nếu câu hỏi liên quan đến tiện ích/dịch vụ, trả về "Hỏi tiện ích [tiện ích]".
- Nếu câu hỏi không rõ ràng nhưng có vẻ liên quan đến đặt phòng, trả về "Đặt lại phòng" hoặc "Hỏi giá" tùy ngữ cảnh.
### Ví dụ để bạn hiểu cách trả lời:
- Câu hỏi: "Tôi muốn tìm phòng cao cấp" → Trả lời: "Tìm phòng Deluxe"
- Câu hỏi: "Có phòng deluxe không?" → Trả lời: "Tìm phòng Deluxe"
- Câu hỏi: "Phòng tiêu chuẩn còn trống không?" → Trả lời: "Tìm phòng Standard"
- Câu hỏi: "Phòng thượng hạng có không?" → Trả lời: "Tìm phòng Suite"
- Câu hỏi: "Cần phòng cao cấp giá rẻ" → Trả lời: "Tìm phòng Deluxe giá rẻ"
- Câu hỏi: "Phòng tiêu chuẩn còn bao nhiêu phòng?" → Trả lời: "Tìm phòng Standard"
- Câu hỏi: "Tôi muốn phòng đẹp nhất" → Trả lời: "Tìm phòng Deluxe"
- Câu hỏi: "Phòng cao cấp có view đẹp không?" → Trả lời: "Hỏi tiện ích view đẹp"
- Câu hỏi: "Khách sạn có wifi không?" → Trả lời: "Hỏi tiện ích wifi"
- Câu hỏi: "Phòng có bữa sáng không?" → Trả lời: "Hỏi tiện ích bữa sáng"
- Câu hỏi: "Đặt lại phòng lần trước" → Trả lời: "Đặt lại phòng"
- Câu hỏi: "Giá phòng bao nhiêu?" → Trả lời: "Hỏi giá"
- Câu hỏi: "Phòng deluxe giá bao nhiêu?" → Trả lời: "Hỏi giá"
- Câu hỏi: "Phòng tiêu chuẩn bao gồm thuế chưa?" → Trả lời: "Hỏi giá"
- Câu hỏi: "Phòng nào rẻ nhất?" → Trả lời: "Tìm phòng giá rẻ"
- Câu hỏi: "Có phòng nào trống không?" → Trả lời: "Hỏi giá"
- Câu hỏi: "Tôi muốn hủy phòng" → Trả lời: "Tôi có thể giúp bạn tìm phòng, kiểm tra giá, đặt lại phòng, hoặc hỏi về tiện ích. Bạn muốn làm gì?"
- Câu hỏi: "Chào bạn" → Trả lời: "Tôi có thể giúp bạn tìm phòng, kiểm tra giá, đặt lại phòng, hoặc hỏi về tiện ích. Bạn muốn làm gì?"
- Câu hỏi: "Phòng có tivi không?" → Trả lời: "Hỏi tiện ích tivi"
- Câu hỏi: "Khách sạn có phòng gym không?" → Trả lời: "Hỏi tiện ích phòng gym"
### Quy tắc trả lời:
- Nếu câu hỏi liên quan đến tìm phòng, trả về: "Tìm phòng [loại phòng tiếng Anh]" hoặc "Tìm phòng [loại phòng tiếng Anh] [yêu cầu]".
- Nếu câu hỏi liên quan đến đặt lại, trả về: "Đặt lại phòng".
- Nếu câu hỏi liên quan đến giá hoặc kiểm tra phòng trống, trả về: "Hỏi giá".
- Nếu câu hỏi liên quan đến tiện ích/dịch vụ, trả về: "Hỏi tiện ích [tiện ích]".
- Nếu không hiểu hoặc câu hỏi không liên quan, trả về: "Tôi có thể giúp bạn tìm phòng, kiểm tra giá, đặt lại phòng, hoặc hỏi về tiện ích. Bạn muốn làm gì?"
''';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Lỗi khi gọi Gemini API: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final chatbotResponse =
          data['candidates'][0]['content']['parts'][0]['text'];

      if (chatbotResponse.contains('Tìm phòng')) {
        String? roomType;
        bool isPriceCheap = chatbotResponse.contains('giá rẻ');
        bool isBestRoom = chatbotResponse.contains('phòng đẹp') ||
            chatbotResponse.contains('tốt nhất');

        if (chatbotResponse.contains('Standard')) {
          roomType = 'Standard';
        } else if (chatbotResponse.contains('Suite')) {
          roomType = 'Suite';
        } else if (chatbotResponse.contains('Deluxe')) {
          roomType = 'Deluxe';
        } else if (isPriceCheap || isBestRoom) {
          // Nếu không có loại phòng cụ thể, mặc định tìm phòng rẻ nhất hoặc đẹp nhất
          roomType = isBestRoom ? 'Deluxe' : null;
        }

        if (roomType != null || isPriceCheap) {
          _lastSuggestedRoomType = roomType;
          _lastRoomTypeContext = roomType;

          final snapshot = await FirebaseFirestore.instance
              .collection('rooms')
              .where('isAvailable', isEqualTo: true)
              .get();

          var rooms = snapshot.docs.map((doc) {
            final data = doc.data();
            final price = (data['price'] is int)
                ? (data['price'] as int).toDouble()
                : (data['price'] as double?);
            return {
              'id': doc.id,
              'name': data['name'] as String?,
              'type': _normalizeRoomType(data['type'] as String? ?? ''),
              'displayType':
                  _toVietnameseRoomType(data['type'] as String? ?? 'Unknown'),
              'price': price ?? 0.0,
              'isAvailable': data['isAvailable'] as bool?,
              'imagePath': data['imagePath'] as String?,
              'hasWifi': data['hasWifi'] as bool? ?? false,
              'hasPool': data['hasPool'] as bool? ?? false,
              'hasBreakfast': data['hasBreakfast'] as bool? ?? false,
              'hasBalcony': data['hasBalcony'] as bool? ?? false,
              'hasAirConditioner': data['hasAirConditioner'] as bool? ?? false,
              'hasNiceView': data['hasNiceView'] as bool? ?? false,
            };
          }).toList();

          if (roomType != null) {
            rooms = rooms.where((room) {
              return room['type'] == roomType;
            }).toList();
          }

          if (isPriceCheap) {
            rooms.sort((a, b) =>
                (a['price'] as double).compareTo(b['price'] as double));
            rooms = rooms.take(3).toList();
          } else if (isBestRoom) {
            // Ưu tiên phòng Deluxe, nếu không có thì lấy phòng có giá cao nhất
            rooms = rooms.where((room) => room['type'] == 'Deluxe').toList();
            if (rooms.isEmpty) {
              rooms = snapshot.docs.map((doc) {
                final data = doc.data();
                final price = (data['price'] is int)
                    ? (data['price'] as int).toDouble()
                    : (data['price'] as double?);
                return {
                  'id': doc.id,
                  'name': data['name'] as String?,
                  'type': _normalizeRoomType(data['type'] as String? ?? ''),
                  'displayType': _toVietnameseRoomType(
                      data['type'] as String? ?? 'Unknown'),
                  'price': price ?? 0.0,
                  'isAvailable': data['isAvailable'] as bool?,
                  'imagePath': data['imagePath'] as String?,
                  'hasWifi': data['hasWifi'] as bool? ?? false,
                  'hasPool': data['hasPool'] as bool? ?? false,
                  'hasBreakfast': data['hasBreakfast'] as bool? ?? false,
                  'hasBalcony': data['hasBalcony'] as bool? ?? false,
                  'hasAirConditioner':
                      data['hasAirConditioner'] as bool? ?? false,
                  'hasNiceView': data['hasNiceView'] as bool? ?? false,
                };
              }).toList();
              rooms.sort((a, b) =>
                  (b['price'] as double).compareTo(a['price'] as double));
              rooms = rooms.take(3).toList();
            }
          }

          print('Phòng tìm thấy: ${rooms.length} phòng');
          for (var room in rooms) {
            print(
                'Phòng: ${room['name']}, Loại: ${room['displayType']}, Giá: ${room['price']}, Còn trống: ${room['isAvailable']}');
          }

          if (rooms.isEmpty) {
            final allRoomsSnapshot = await FirebaseFirestore.instance
                .collection('rooms')
                .where('isAvailable', isEqualTo: true)
                .limit(3)
                .get();

            if (allRoomsSnapshot.docs.isEmpty) {
              _addMessage('Chatbot',
                  'Hiện tại không có phòng nào còn trống. Bạn muốn thử lại sau không?');
              return;
            }

            final allRooms = allRoomsSnapshot.docs.map((doc) {
              final data = doc.data();
              final price = (data['price'] is int)
                  ? (data['price'] as int).toDouble()
                  : (data['price'] as double?);
              return {
                'id': doc.id,
                'name': data['name'] as String?,
                'type': _normalizeRoomType(data['type'] as String? ?? ''),
                'displayType':
                    _toVietnameseRoomType(data['type'] as String? ?? 'Unknown'),
                'price': price ?? 0.0,
                'isAvailable': data['isAvailable'] as bool?,
                'imagePath': data['imagePath'] as String?,
              };
            }).toList();

            _addMessage('Chatbot',
                'Hiện tại không có phòng${roomType != null ? ' "${_toVietnameseRoomType(roomType)}"' : ''}${isPriceCheap ? " giá rẻ" : ""}${isBestRoom ? " đẹp nhất" : ""} nào còn trống. Dưới đây là các phòng còn trống khác:',
                rooms: allRooms
                    .map((room) => {
                          'id': room['id'],
                          'name': room['name'],
                          'type': room['displayType'],
                          'price': room['price'],
                          'isAvailable': room['isAvailable'],
                          'imagePath': room['imagePath'],
                        })
                    .toList());
            return;
          }

          _addMessage('Chatbot',
              'Dưới đây là danh sách các phòng${roomType != null ? ' "${_toVietnameseRoomType(roomType)}"' : ''}${isPriceCheap ? " giá rẻ" : ""}${isBestRoom ? " đẹp nhất" : ""} còn trống:',
              rooms: rooms
                  .map((room) => {
                        'id': room['id'],
                        'name': room['name'],
                        'type': room['displayType'],
                        'price': room['price'],
                        'isAvailable': room['isAvailable'],
                        'imagePath': room['imagePath'],
                      })
                  .toList());
        } else {
          _addMessage('Chatbot',
              'Bạn muốn tìm loại phòng nào? (Tiêu Chuẩn, Thượng Hạng, Cao Cấp)');
        }
      } else if (chatbotResponse.contains('Đặt lại phòng')) {
        final snapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('bookingTime', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          _addMessage('Chatbot',
              'Bạn chưa có lịch sử đặt phòng. Hãy cho tôi biết loại phòng bạn muốn tìm!');
          return;
        }

        final lastBooking = snapshot.docs.first.data();
        final roomName = lastBooking['roomName'] as String? ?? 'một phòng';
        final roomSnapshot = await FirebaseFirestore.instance
            .collection('rooms')
            .where('name', isEqualTo: roomName)
            .where('isAvailable', isEqualTo: true)
            .limit(1)
            .get();

        if (roomSnapshot.docs.isEmpty) {
          final roomData = await FirebaseFirestore.instance
              .collection('rooms')
              .where('name', isEqualTo: roomName)
              .limit(1)
              .get();

          if (roomData.docs.isNotEmpty) {
            final type = _normalizeRoomType(
                roomData.docs.first.data()['type'] as String? ?? '');
            if (type.isNotEmpty) {
              _lastSuggestedRoomType = type;
              _lastRoomTypeContext = type;
              final similarRoomsSnapshot = await FirebaseFirestore.instance
                  .collection('rooms')
                  .where('isAvailable', isEqualTo: true)
                  .get();

              final similarRooms = similarRoomsSnapshot.docs
                  .where((doc) =>
                      _normalizeRoomType(doc.data()['type'] as String? ?? '') ==
                      type)
                  .map((doc) {
                final data = doc.data();
                final price = (data['price'] is int)
                    ? (data['price'] as int).toDouble()
                    : (data['price'] as double?);
                return {
                  'id': doc.id,
                  'name': data['name'] as String?,
                  'type': _normalizeRoomType(data['type'] as String? ?? ''),
                  'displayType': _toVietnameseRoomType(
                      data['type'] as String? ?? 'Unknown'),
                  'price': price ?? 0.0,
                  'isAvailable': data['isAvailable'] as bool?,
                  'imagePath': data['imagePath'] as String?,
                };
              }).toList();

              if (similarRooms.isEmpty) {
                final allRoomsSnapshot = await FirebaseFirestore.instance
                    .collection('rooms')
                    .where('isAvailable', isEqualTo: true)
                    .limit(3)
                    .get();

                if (allRoomsSnapshot.docs.isEmpty) {
                  _addMessage('Chatbot',
                      'Hiện tại không có phòng nào còn trống. Bạn muốn thử lại sau không?');
                  return;
                }

                final allRooms = allRoomsSnapshot.docs.map((doc) {
                  final data = doc.data();
                  final price = (data['price'] is int)
                      ? (data['price'] as int).toDouble()
                      : (data['price'] as double?);
                  return {
                    'id': doc.id,
                    'name': data['name'] as String?,
                    'type': _normalizeRoomType(data['type'] as String? ?? ''),
                    'displayType': _toVietnameseRoomType(
                        data['type'] as String? ?? 'Unknown'),
                    'price': price ?? 0.0,
                    'isAvailable': data['isAvailable'] as bool?,
                    'imagePath': data['imagePath'] as String?,
                  };
                }).toList();

                _addMessage('Chatbot',
                    'Rất tiếc, hiện không có phòng loại "${_toVietnameseRoomType(type)}" nào còn trống. Dưới đây là các phòng còn trống khác:',
                    rooms: allRooms
                        .map((room) => {
                              'id': room['id'],
                              'name': room['name'],
                              'type': room['displayType'],
                              'price': room['price'],
                              'isAvailable': room['isAvailable'],
                              'imagePath': room['imagePath'],
                            })
                        .toList());
                return;
              }

              _addMessage('Chatbot',
                  'Rất tiếc, phòng "$roomName" hiện không còn trống. Dưới đây là các phòng loại "${_toVietnameseRoomType(type)}" còn trống:',
                  rooms: similarRooms
                      .map((room) => {
                            'id': room['id'],
                            'name': room['name'],
                            'type': room['displayType'],
                            'price': room['price'],
                            'isAvailable': room['isAvailable'],
                            'imagePath': room['imagePath'],
                          })
                      .toList());
            } else {
              _addMessage('Chatbot',
                  'Không tìm thấy thông tin phòng "$roomName". Bạn muốn tìm loại phòng nào?');
            }
          } else {
            _addMessage('Chatbot',
                'Không tìm thấy phòng "$roomName". Bạn muốn tìm loại phòng nào?');
          }
          return;
        }

        final room = roomSnapshot.docs.first;
        final roomData = room.data();
        final price = (roomData['price'] is int)
            ? (roomData['price'] as int).toDouble()
            : (roomData['price'] as double?);
        _lastSuggestedRoomType =
            _normalizeRoomType(roomData['type'] as String? ?? '');
        _lastRoomTypeContext = _lastSuggestedRoomType;
        _addMessage('Chatbot',
            'Phòng "$roomName" hiện còn trống. Bạn có muốn đặt ngay không?',
            rooms: [
              {
                'id': room.id,
                'name': roomData['name'] as String?,
                'type': _toVietnameseRoomType(
                    roomData['type'] as String? ?? 'Unknown'),
                'price': price ?? 0.0,
                'isAvailable': roomData['isAvailable'] as bool?,
                'imagePath': roomData['imagePath'] as String?,
              }
            ]);
      } else if (chatbotResponse.contains('Hỏi giá')) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('rooms')
            .where('isAvailable', isEqualTo: true);

        if (_lastRoomTypeContext != null) {
          query = query.where('type', isEqualTo: _lastRoomTypeContext);
        }

        final snapshot = await query.limit(3).get();

        if (snapshot.docs.isEmpty) {
          final allRoomsSnapshot = await FirebaseFirestore.instance
              .collection('rooms')
              .where('isAvailable', isEqualTo: true)
              .limit(3)
              .get();

          if (allRoomsSnapshot.docs.isEmpty) {
            _addMessage('Chatbot',
                'Hiện tại không có phòng nào còn trống. Bạn muốn thử lại sau không?');
            return;
          }

          final allRooms = allRoomsSnapshot.docs.map((doc) {
            final data = doc.data();
            final price = (data['price'] is int)
                ? (data['price'] as int).toDouble()
                : (data['price'] as double?);
            return {
              'id': doc.id,
              'name': data['name'] as String?,
              'type': _normalizeRoomType(data['type'] as String? ?? ''),
              'displayType':
                  _toVietnameseRoomType(data['type'] as String? ?? 'Unknown'),
              'price': price ?? 0.0,
              'isAvailable': data['isAvailable'] as bool?,
              'imagePath': data['imagePath'] as String?,
            };
          }).toList();

          _addMessage('Chatbot',
              'Hiện tại không có phòng${_lastRoomTypeContext != null ? ' loại "${_toVietnameseRoomType(_lastRoomTypeContext ?? "Unknown")}"' : ''} nào còn trống. Dưới đây là các phòng còn trống khác:',
              rooms: allRooms
                  .map((room) => {
                        'id': room['id'],
                        'name': room['name'],
                        'type': room['displayType'],
                        'price': room['price'],
                        'isAvailable': room['isAvailable'],
                        'imagePath': room['imagePath'],
                      })
                  .toList());
          return;
        }

        final rooms = snapshot.docs.map((doc) {
          final data = doc.data();
          final price = (data['price'] is int)
              ? (data['price'] as int).toDouble()
              : (data['price'] as double?);
          return {
            'id': doc.id,
            'name': data['name'] as String?,
            'type': _normalizeRoomType(data['type'] as String? ?? ''),
            'displayType':
                _toVietnameseRoomType(data['type'] as String? ?? 'Unknown'),
            'price': price ?? 0.0,
            'isAvailable': data['isAvailable'] as bool?,
            'imagePath': data['imagePath'] as String?,
          };
        }).toList();

        _addMessage('Chatbot',
            'Dưới đây là giá của các phòng${_lastRoomTypeContext != null ? ' loại "${_toVietnameseRoomType(_lastRoomTypeContext ?? "Unknown")}"' : ''} còn trống:',
            rooms: rooms
                .map((room) => {
                      'id': room['id'],
                      'name': room['name'],
                      'type': room['displayType'],
                      'price': room['price'],
                      'isAvailable': room['isAvailable'],
                      'imagePath': room['imagePath'],
                    })
                .toList());
      } else if (chatbotResponse.contains('Hỏi tiện ích')) {
        String? amenity;
        if (chatbotResponse.contains('wifi')) {
          amenity = 'wifi';
        } else if (chatbotResponse.contains('hồ bơi')) {
          amenity = 'hồ bơi';
        } else if (chatbotResponse.contains('bữa sáng')) {
          amenity = 'bữa sáng';
        } else if (chatbotResponse.contains('ban công')) {
          amenity = 'ban công';
        } else if (chatbotResponse.contains('máy lạnh')) {
          amenity = 'máy lạnh';
        } else if (chatbotResponse.contains('view đẹp')) {
          amenity = 'view đẹp';
        } else if (chatbotResponse.contains('tivi')) {
          amenity = 'tivi';
        } else if (chatbotResponse.contains('phòng gym')) {
          amenity = 'phòng gym';
        }

        if (amenity != null) {
          final snapshot = await FirebaseFirestore.instance
              .collection('rooms')
              .where('isAvailable', isEqualTo: true)
              .get();

          final rooms = snapshot.docs.map((doc) {
            final data = doc.data();
            final price = (data['price'] is int)
                ? (data['price'] as int).toDouble()
                : (data['price'] as double?);
            return {
              'id': doc.id,
              'name': data['name'] as String?,
              'type': _normalizeRoomType(data['type'] as String? ?? ''),
              'displayType':
                  _toVietnameseRoomType(data['type'] as String? ?? 'Unknown'),
              'price': price ?? 0.0,
              'isAvailable': data['isAvailable'] as bool?,
              'imagePath': data['imagePath'] as String?,
              'hasWifi': data['hasWifi'] as bool? ?? false,
              'hasPool': data['hasPool'] as bool? ?? false,
              'hasBreakfast': data['hasBreakfast'] as bool? ?? false,
              'hasBalcony': data['hasBalcony'] as bool? ?? false,
              'hasAirConditioner': data['hasAirConditioner'] as bool? ?? false,
              'hasNiceView': data['hasNiceView'] as bool? ?? false,
            };
          }).toList();

          bool hasAmenity = false;
          String message = '';
          switch (amenity) {
            case 'wifi':
              hasAmenity = rooms.any((room) => room['hasWifi'] == true);
              message = hasAmenity
                  ? 'Có, một số phòng có wifi. Bạn có muốn xem danh sách phòng không?'
                  : 'Rất tiếc, hiện không có phòng nào có wifi.';
              break;
            case 'hồ bơi':
              hasAmenity = rooms.any((room) => room['hasPool'] == true);
              message = hasAmenity
                  ? 'Có, khách sạn có hồ bơi. Bạn có muốn xem danh sách phòng không?'
                  : 'Rất tiếc, khách sạn hiện không có hồ bơi.';
              break;
            case 'bữa sáng':
              hasAmenity = rooms.any((room) => room['hasBreakfast'] == true);
              message = hasAmenity
                  ? 'Có, một số phòng bao gồm bữa sáng. Bạn có muốn xem danh sách phòng không?'
                  : 'Rất tiếc, hiện không có phòng nào bao gồm bữa sáng.';
              break;
            case 'ban công':
              hasAmenity = rooms.any((room) => room['hasBalcony'] == true);
              message = hasAmenity
                  ? 'Có, một số phòng có ban công. Bạn có muốn xem danh sách phòng không?'
                  : 'Rất tiếc, hiện không có phòng nào có ban công.';
              break;
            case 'máy lạnh':
              hasAmenity =
                  rooms.any((room) => room['hasAirConditioner'] == true);
              message = hasAmenity
                  ? 'Có, một số phòng có máy lạnh. Bạn có muốn xem danh sách phòng không?'
                  : 'Rất tiếc, hiện không có phòng nào có máy lạnh.';
              break;
            case 'view đẹp':
              hasAmenity = rooms.any((room) => room['hasNiceView'] == true);
              message = hasAmenity
                  ? 'Có, một số phòng có view đẹp. Bạn có muốn xem danh sách phòng không?'
                  : 'Rất tiếc, hiện không có phòng nào có view đẹp.';
              break;
            default:
              message =
                  'Vui lòng liên hệ nhân viên để biết thêm chi tiết về tiện ích "$amenity".';
          }

          if (hasAmenity) {
            final filteredRooms = rooms.where((room) {
              switch (amenity) {
                case 'wifi':
                  return room['hasWifi'] == true;
                case 'hồ bơi':
                  return room['hasPool'] == true;
                case 'bữa sáng':
                  return room['hasBreakfast'] == true;
                case 'ban công':
                  return room['hasBalcony'] == true;
                case 'máy lạnh':
                  return room['hasAirConditioner'] == true;
                case 'view đẹp':
                  return room['hasNiceView'] == true;
                default:
                  return false;
              }
            }).toList();

            _addMessage('Chatbot', message,
                rooms: filteredRooms
                    .map((room) => {
                          'id': room['id'],
                          'name': room['name'],
                          'type': room['displayType'],
                          'price': room['price'],
                          'isAvailable': room['isAvailable'],
                          'imagePath': room['imagePath'],
                        })
                    .toList());
          } else {
            _addMessage('Chatbot', message);
          }
        } else {
          _addMessage('Chatbot',
              'Vui lòng liên hệ nhân viên để biết thêm chi tiết về tiện ích.');
        }
      } else {
        _addMessage('Chatbot', chatbotResponse);
      }
    } catch (e) {
      print('Lỗi xử lý yêu cầu: $e');
      _addMessage('Chatbot', 'Đã xảy ra lỗi. Vui lòng thử lại sau.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRoomDetail(Map<String, dynamic> room) {
    Navigator.pushNamed(
      context,
      '/room_detail',
      arguments: {
        'id': room['id'] as String? ?? '',
        'name': room['name'] as String? ?? 'Unknown',
        'type': room['type'] as String? ?? 'Unknown',
        'price': room['price'] as double? ?? 0.0,
        'isAvailable': room['isAvailable'] as bool? ?? false,
        'imagePath':
            room['imagePath'] as String? ?? 'assets/images/placeholder.jpg',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ Trợ Đặt Phòng'),
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message['sender'] == 'Bạn';
                  return Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${message['sender']}: ${message['message']}',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF9FAFB),
                                    fontSize: 16,
                                  ),
                                ),
                                if (message['rooms'].isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...message['rooms'].map<Widget>((room) {
                                    return GestureDetector(
                                      onTap: () => _navigateToRoomDetail(room),
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  room['imagePath']
                                                          as String? ??
                                                      'assets/images/placeholder.jpg',
                                                  width: 60,
                                                  height: 60,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    print(
                                                        'Lỗi tải hình ảnh: ${room['imagePath']}, lỗi: $error');
                                                    return Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                          size: 30,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      room['name'] as String? ??
                                                          'Unknown',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: const Color(
                                                            0xFF1E293B),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Loại: ${room['type'] as String? ?? 'Unknown'}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      'Giá: ${(room['price'] as double? ?? 0.0).toStringAsFixed(0)} VND',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      room['isAvailable'] ==
                                                              true
                                                          ? 'Còn Trống'
                                                          : 'Đã Đặt',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        color:
                                                            room['isAvailable'] ==
                                                                    true
                                                                ? Colors.green
                                                                : Colors.red,
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
                                  }).toList(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF334155),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style:
                          GoogleFonts.poppins(color: const Color(0xFFF9FAFB)),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _addMessage('Bạn', value);
                          _processUserInput(value);
                          setState(() {
                            _isLoading = false;
                          });
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFF59E0B)),
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        _addMessage('Bạn', _controller.text);
                        _processUserInput(_controller.text);
                        setState(() {
                          _isLoading = false;
                        });
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
