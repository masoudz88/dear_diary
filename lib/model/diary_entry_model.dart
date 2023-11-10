import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String description;
  final int rating;
  List<String>? imageUrls;
  List<XFile>? localImages; // New field for local images

  DiaryEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.rating,
    this.imageUrls,
    this.localImages,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
      'rating': rating,
      'imageUrls': imageUrls,
    };
  }

  static DiaryEntry fromMap(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'],
      rating: map['rating'],
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      localImages: [],
    );
  }
}
