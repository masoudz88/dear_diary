import 'package:flutter/material.dart';
import 'package:dear_diary/controller/diary_controller.dart';
import 'package:dear_diary/model/diary_entry_model.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dear_diary/model_theme.dart';

class DiaryEntryView extends StatefulWidget {
  final Function(DiaryEntry entry) onEntryAdded;
  final DiaryEntry? entryToEdit;

  const DiaryEntryView({
    super.key,
    required this.onEntryAdded,
    this.entryToEdit,
  });

  @override
  State<DiaryEntryView> createState() => _DiaryEntryViewState();
}

class _DiaryEntryViewState extends State<DiaryEntryView> {
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  int rating = 1; // Assuming a default value

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      descriptionController.text = widget.entryToEdit!.description;
      selectedDate = widget.entryToEdit!.date;
      rating = widget.entryToEdit!.rating;
    }
  }

  void _saveEntry(DiaryController diaryController) async {
    if (descriptionController.text.isEmpty) {
      _showErrorSnackbar("Description cannot be empty!");
      return;
    }

    var entry = DiaryEntry(
      id: widget.entryToEdit?.id ?? '', // Ensure the id is maintained for edits, generated for new entries
      description: descriptionController.text,
      date: selectedDate,
      rating: rating,
    );

    if (widget.entryToEdit == null) {
      // Add mode
      bool entryExists = await diaryController.entryExistsForDate(selectedDate);
      if (entryExists) {
        _showErrorSnackbar("An entry with the same date already exists!");
        return;
      }
      await diaryController.addEntry(entry);
    } else {
      // Edit mode
      await diaryController.updateEntry(entry);
    }

    widget.onEntryAdded.call(entry);
    Navigator.pop(context);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DiaryController diaryController = DiaryController();
    return Consumer<ModelTheme>(
      builder: (context, ModelTheme themeNotifier, child) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.entryToEdit == null
              ? 'Add Diary Entry'
              : 'Edit Diary Entry')),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme: InputDecorationTheme(
                      labelStyle: TextStyle(
                        color: themeNotifier.isDark ? Colors.white : Colors.green,
                      ),
                      hintStyle: TextStyle(
                        color: themeNotifier.isDark ? Colors.white : Colors.grey,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeNotifier.isDark ? Colors.white : Colors.green,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeNotifier.isDark ? Colors.white : Colors.green,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: themeNotifier.isDark ? Colors.white : Colors.green,
                        ),
                      ),
                    ),
                  ),
                  child: TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What happened today?',
                      // Removed const from decoration since we are changing the style based on the theme
                    ),
                    maxLength: 140,
                    maxLines: 5,
                    inputFormatters: [LengthLimitingTextInputFormatter(140)],
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: themeNotifier.isDark ?
                          ThemeData.dark().copyWith(
                            // Change this to ThemeData.dark() if you want dark mode
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.green, // header background color
                            ),
                          ):
                          ThemeData.light().copyWith(
                            // Change this to ThemeData.dark() if you want dark mode
                            colorScheme: const ColorScheme.light(
                              primary: Colors.green, // header background color
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
                Text('Rating: $rating'),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: themeNotifier.isDark ? Colors.white : Colors.green,
                    inactiveTrackColor: themeNotifier.isDark ? Colors.white38 : Colors.green[100],
                    thumbColor: themeNotifier.isDark ? Colors.white : Colors.green,
                    overlayColor: themeNotifier.isDark ? Colors.white.withOpacity(0.1) : Colors.green.withOpacity(0.2),
                    valueIndicatorColor: themeNotifier.isDark ? Colors.grey : Colors.green,
                    // You might want to adjust the thumb shape as well
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    // Also the overlay shape (the effect on thumb when pressed)
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
                  ),
                  child: Slider(
                    value: rating.toDouble(),
                    onChanged: (newRating) {
                      setState(() => rating = newRating.round());
                    },
                    divisions: 4,
                    label: '$rating stars',
                    min: 1,
                    max: 5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _saveEntry(diaryController),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.green,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      widget.entryToEdit == null ? 'Add Entry' : 'Update Entry',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
