import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String name;
  final String type;
  final double price;
  final bool isAvailable;
  final String imagePath;

  const Room({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.isAvailable,
    this.imagePath = 'assets/images/placeholder_room.jpg',
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      isAvailable: data['isAvailable'] ?? false,
      imagePath: data['imagePath'] ?? 'assets/images/placeholder_room.jpg',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'isAvailable': isAvailable,
      'imagePath': imagePath,
    };
  }
}
