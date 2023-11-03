import 'package:flutter/material.dart';
import 'package:dear_diary/controller/diary_controller.dart';
import 'package:dear_diary/model/diary_entry_model.dart';
import 'package:flutter/services.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.entryToEdit == null ? 'Add Diary Entry' : 'Edit Diary Entry')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What happened today?',
                border: OutlineInputBorder(),
              ),
              maxLength: 140,
              maxLines: 5,
              inputFormatters: [LengthLimitingTextInputFormatter(140)],
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null && pickedDate != selectedDate) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Text('Rating: $rating'),
            Slider(
              value: rating.toDouble(),
              onChanged: (newRating) {
                setState(() => rating = newRating.round());
              },
              divisions: 4,
              label: '$rating stars',
              min: 1,
              max: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveEntry(diaryController),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(widget.entryToEdit == null ? 'Add Entry' : 'Update Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
