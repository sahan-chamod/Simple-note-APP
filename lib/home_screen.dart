import 'package:flutter/material.dart';
import 'db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final notes = await DBHelper.instance.getNotes();
    setState(() {
      _notes = notes ?? [];
    });
  }

  Future<void> _addOrEditNote({Map<String, dynamic>? note}) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPriority = note?['priority'] ?? 'Medium';

    if (note != null) {
      titleController.text = note['title'] ?? '';
      contentController.text = note['content'] ?? '';
      selectedPriority = note['priority'] ?? 'Medium';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            note == null ? 'Add Note' : 'Edit Note',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    maxLines: null, // Allows unlimited lines
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedPriority,
                    items: ['High', 'Medium', 'Low'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedPriority = newValue;
                        });
                      }
                    },
                    isExpanded: true,
                    underline: Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newNote = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'priority': selectedPriority,
                  if (note != null) 'id': note['id']
                };

                if (note == null) {
                  await _addNote(newNote);
                } else {
                  await _updateNote(newNote);
                }

                Navigator.of(context).pop();
                _fetchNotes();
              },
              child: Text(note == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNote(Map<String, dynamic> note) async {
    await DBHelper.instance.insertNote(note);
  }

  Future<void> _updateNote(Map<String, dynamic> note) async {
    await DBHelper.instance.updateNote(note);
  }

  void _deleteNoteDialog(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Note',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper.instance.deleteNote(id);
              Navigator.of(context).pop();
              _fetchNotes();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _notes.isEmpty
            ? const Center(
                child: Text('No Notes Found', style: TextStyle(fontSize: 18)))
            : ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                          Expanded(
                            child: Text(
                              note['title'] ?? 'Untitled',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                  note['priority'] ?? 'Medium'),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              note['priority'] ?? 'Medium',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(note['content'] ?? ''),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _addOrEditNote(note: note),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNoteDialog(note['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
