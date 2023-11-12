import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dear_diary/controller/diary_entry_service.dart';
import 'package:dear_diary/model/diary_entry_model.dart';
import 'package:dear_diary/view/add_edit_diary_entry_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dear_diary/model_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DiaryListView extends StatefulWidget {
  const DiaryListView({super.key});

  @override
  State<DiaryListView> createState() => _DiaryListViewState();
}

class _DiaryListViewState extends State<DiaryListView> {
  final DiaryEntryService diaryController = DiaryEntryService();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  DiaryEntry? _selectedEntry;
  List<DiaryEntry>? _filteredEntries;


  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images.add(image);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image picked from gallery")));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _images.add(image);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image picked from camera")));
    }
  }


  Future<void> _uploadImagesToFirebase(DiaryEntry entry) async {
    if (_images.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> uploadedImageUrls = [];
    for (var image in _images) {
      final firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('images/${currentUser.uid}/${image.name}');

      try {
        final uploadTask = await firebaseStorageRef.putFile(File(image.path));
        if (uploadTask.state == TaskState.success) {
          final downloadURL = await firebaseStorageRef.getDownloadURL();
          uploadedImageUrls.add(downloadURL);
        }
      } catch (e) {
        print("Failed to upload image: $e");
      }
    }

    if (uploadedImageUrls.isNotEmpty) {
      _updateEntryWithImages(entry, uploadedImageUrls);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Images uploaded successfully")));
    }
  }


  Future<void> _updateEntryWithImages(DiaryEntry entry, List<String> imageUrls) async {
    DiaryEntry updatedEntry = DiaryEntry(
      id: entry.id,
      date: entry.date,
      description: entry.description,
      rating: entry.rating,
      imageUrls: (entry.imageUrls ?? []) + imageUrls,
    );

    await diaryController.updateEntry(updatedEntry);
    setState(() {
      _selectedEntry = updatedEntry;
      _images = []; // Reset the images after uploading
    });
  }

  Widget _buildImageList(DiaryEntry entry) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: List.generate(entry.imageUrls?.length ?? 0, (index) {
        String imageUrl = entry.imageUrls![index];
        return Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.remove_circle),
              onPressed: () async {
                // Remove from Firebase Storage
                await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                // Update entry by removing the image URL
                List<String> updatedUrls = List.from(entry.imageUrls!)..removeAt(index);
                DiaryEntry updatedEntry = DiaryEntry(
                  id: entry.id,
                  date: entry.date,
                  description: entry.description,
                  rating: entry.rating,
                  imageUrls: updatedUrls,
                );
                await diaryController.updateEntry(updatedEntry);
                setState(() {
                  entry.imageUrls?.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image removed successfully")));
              },
            ),
          ],
        );
      }),
    );
  }


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


  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int? searchRating;
        return AlertDialog(
          title: Text('Search by Rating'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              searchRating = int.tryParse(value);
            },
            decoration: InputDecoration(hintText: "Enter rating (1-5)"),
          ),
          actions: [
            TextButton(
              child: Text('Search'),
              onPressed: () {
                if (searchRating != null) {
                  _filterEntriesByRating(searchRating!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _filterEntriesByRating(int rating) async {
    List<DiaryEntry> allEntries = await diaryController.getAllEntries();
    setState(() {
      _filteredEntries = allEntries.where((entry) => entry.rating == rating).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ModelTheme>(
      builder: (context, ModelTheme themeNotifier, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Diary Entries'),
            backgroundColor: themeNotifier.isDark ? Colors.black : Colors.green,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _showSearchDialog(context);
                },
              ),
              if (_filteredEntries != null) // Show the clear icon only when there is a filter applied
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _filteredEntries = null; // Clear the search filter
                    });
                  },
                ),
              IconButton(
                icon: Icon(themeNotifier.isDark ? Icons.wb_sunny : Icons.nightlight_round),
                onPressed: () {
                  setState(() {
                    themeNotifier.isDark = !themeNotifier.isDark; // Toggle theme state
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
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong!'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              List<DiaryEntry> entries = snapshot.data!.docs.map((doc) => DiaryEntry.fromMap(doc)).toList();
              if (_filteredEntries != null) {
                entries = _filteredEntries!;
              }
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
                            color: themeNotifier.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      ...monthEntries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeNotifier.isDark ? Colors.black : Colors.white,
                              border: Border.all(color: Colors.grey.shade300, width: 1),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          ..add(const SizedBox(width: 10))
                                          ..add(
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => AddEditDiaryEntryView(
                                                      onEntryAdded: (entry) {
                                                        setState(() {});
                                                      },
                                                      entryToEdit: e,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          ..add(const SizedBox(width: 10))
                                          ..add(
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () async {
                                                await diaryController.deleteEntry(e);
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _pickImageFromGallery,
                                        child: const Text('Gallery'),
                                      ),
                                      ElevatedButton(
                                        onPressed: _pickImageFromCamera,
                                        child: const Text('Camera'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _selectedEntry = e;
                                          _uploadImagesToFirebase(e);
                                        },
                                        child: const Text('Upload to Firebase'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: themeNotifier.isDark ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(e.description, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 10),
                                  _buildImageList(e),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                  builder: (context) => AddEditDiaryEntryView(
                    onEntryAdded: (entry) {
                      setState(() {});
                    },
                  ),
                ),
              );
            },
            backgroundColor: themeNotifier.isDark ? Colors.grey : Colors.green,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
