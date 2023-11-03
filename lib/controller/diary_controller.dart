import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dear_diary/model/diary_entry_model.dart';

class DiaryController {
  final user = FirebaseAuth.instance.currentUser;
  final CollectionReference diaryCollection;

  DiaryController()
      : diaryCollection = FirebaseFirestore.instance
      .collection('diaries')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('userDiaries');

  Future<DocumentReference<Object?>> addEntry(DiaryEntry entry) async {
    return await diaryCollection.add(entry.toMap());
  }

  Future<List<DiaryEntry>> getAllEntries() async {
    QuerySnapshot snapshot = await diaryCollection.get();
    return snapshot.docs.map((doc) => DiaryEntry.fromMap(doc)).toList();
  }

  Future<void> updateEntry(DiaryEntry updatedEntry) async {
    return await diaryCollection.doc(updatedEntry.id).update(updatedEntry.toMap());
  }

  Future<void> deleteEntry(DiaryEntry entry) async {
    return await diaryCollection.doc(entry.id).delete();
  }

  Future<bool> entryExistsForDate(DateTime date) async {
    QuerySnapshot snapshot = await diaryCollection
        .where('date', isEqualTo: date)
        .get();
    return snapshot.docs.isNotEmpty;
  }

}
