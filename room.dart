// lib/room.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String name;
  final String type;
  final double price; // Đổi từ int sang double để thống nhất
  final bool isAvailable;
  final String imagePath;
  final DateTime createdAt; // Thêm từ RoomModel
  final DateTime updatedAt; // Thêm từ RoomModel

  const Room({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.isAvailable,
    this.imagePath = 'assets/images/placeholder_room.jpg',
    required this.createdAt, // Thêm vào constructor
    required this.updatedAt, // Thêm vào constructor
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('Firestore data for room ${doc.id}: $data'); // Log dữ liệu thô
    return Room(
      id: doc.id,
      name: data['name'] ?? 'Unknown Room',
      type: data['type'] ?? 'Unknown Type',
      price: (data['price'] as num?)?.toDouble() ?? 0.0, // Đổi sang double
      isAvailable: data['isAvailable'] ?? false,
      imagePath: data['imagePath'] ?? 'assets/images/placeholder_room.jpg',
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'isAvailable': isAvailable,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Room(id: $id, name: $name, type: $type, price: $price, isAvailable: $isAvailable, imagePath: $imagePath, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
