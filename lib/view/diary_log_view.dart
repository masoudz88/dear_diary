import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dear_diary/controller/diary_controller.dart';
import 'package:dear_diary/model/diary_entry_model.dart';
import 'package:dear_diary/view/diary_entry_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dear_diary/model_theme.dart';

class DiaryLogView extends StatefulWidget {
  const DiaryLogView({super.key});

  @override
  State<DiaryLogView> createState() => _DiaryLogViewState();
}

class _DiaryLogViewState extends State<DiaryLogView> {
  final DiaryController diaryController = DiaryController();

  List<Widget> _buildStars(int rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        Icon(
          i <= rating ? Icons.star : Icons.star_border,
          color: Colors.green,
        ),
      );
    }
    return stars;
  }

  Map<String, List<DiaryEntry>> _groupEntriesByMonth(List<DiaryEntry> entries) {
    Map<String, List<DiaryEntry>> groupedEntries = {};
    for (var entry in entries) {
      String monthYearKey = DateFormat('MMMM yyyy').format(entry.date);
      if (groupedEntries.containsKey(monthYearKey)) {
        groupedEntries[monthYearKey]!.add(entry);
      } else {
        groupedEntries[monthYearKey] = [entry];
      }
    }
    return groupedEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
      builder: (context, ModelTheme themeNotifier, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Diary Entries'),
            backgroundColor: themeNotifier.isDark ? Colors.black : Colors.green,
            // AppBar color changes based on theme
            actions: [
              IconButton(
                icon: Icon(themeNotifier.isDark ? Icons.wb_sunny : Icons
                    .nightlight_round),
                onPressed: () {
                  setState(() {
                    themeNotifier.isDark =
                    !themeNotifier.isDark; // Toggle theme state
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: StreamBuilder(
            stream: diaryController.diaryCollection.snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong!'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<DiaryEntry> entries = snapshot.data!.docs.map((doc) =>
                  DiaryEntry.fromMap(doc)).toList();
              var groupedEntries = _groupEntriesByMonth(entries);

              return ListView(
                children: groupedEntries.entries.map((entry) {
                  var monthEntries = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: themeNotifier.isDark ? Colors.white : Colors.black, // Text color changes based on theme
                          ),
                        ),
                      ),
                      ...monthEntries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeNotifier.isDark ? Colors.black : Colors.white,
                              border: Border.all(
                                  color: Colors.grey.shade300, width: 1),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('EEE, MMM d').format(e.date),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: _buildStars(e.rating)
                                          ..add(const SizedBox(width: 10))..add(
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DiaryEntryView(
                                                          onEntryAdded: (
                                                              entry) {
                                                            // Pass the new entry or updated entry back to refresh the state
                                                            setState(() {});
                                                          },
                                                          entryToEdit: e,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )..add(
                                              const SizedBox(width: 10))..add(
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () async {
                                                await diaryController
                                                    .deleteEntry(e);
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                      ),
                                    ],
                                  ),
                                  Text(e.description,
                                      style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList()
                    ],
                  );
                }).toList(),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DiaryEntryView(
                        onEntryAdded: (entry) {
                          // Pass the new entry back to refresh the state
                          setState(() {});
                        },
                      ),
                ),
              );
            },
            backgroundColor: themeNotifier.isDark ? Colors.grey : Colors.green,
            child: const Icon(Icons.add), // FAB color changes based on theme
          ),
        );
      },
    );
  }
}
