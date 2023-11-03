import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String description;
  final int rating;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      // When storing the date, convert it to a Timestamp
      'date': Timestamp.fromDate(date),
      'description': description,
      'rating': rating,
    };
  }

  static DiaryEntry fromMap(DocumentSnapshot doc) {
    Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      // When retrieving the date, convert the Timestamp to a DateTime
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'],
      rating: map['rating'],
    );
  }
}
