import 'package:flutter/material.dart';
import 'db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  TextEditingController _searchController = TextEditingController();
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final notes = _showArchived
        ? await DBHelper.instance.getArchivedNotes()
        : await DBHelper.instance.getNotes();

    setState(() {
      _notes = notes ?? [];
      _filteredNotes = _notes;
    });
  }

  void _toggleArchivedView() {
    setState(() {
      _showArchived = !_showArchived;
    });
    _fetchNotes();
  }

  void _searchNotes(String query) {
    final results = _notes.where((note) {
      final title = note['title'].toLowerCase();
      final content = note['content'].toLowerCase();
      final searchQuery = query.toLowerCase();
      return title.contains(searchQuery) || content.contains(searchQuery);
    }).toList();

    setState(() {
      _filteredNotes = results;
    });
  }

  Future<void> _addOrEditNote({Map<String, dynamic>? note}) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPriority = note?['priority'] ?? 'Medium';
    String selectedCategory = note?['category'] ?? 'General';

    if (note != null) {
      titleController.text = note['title'] ?? '';
      contentController.text = note['content'] ?? '';
      selectedPriority = note['priority'] ?? 'Medium';
      selectedCategory = note['category'] ?? 'General';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(note == null ? 'Add Note' : 'Edit Note',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
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
                    underline: Container(height: 1, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: ['Work', 'Personal', 'Study', 'General']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                    isExpanded: true,
                    underline: Container(height: 1, color: Colors.grey),
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
                final dateTime = DateTime.now().toString();
                final newNote = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'priority': selectedPriority,
                  'category': selectedCategory,
                  'dateTime': dateTime,
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

  void _archiveNoteDialog(int id, bool isArchived) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(isArchived ? 'Unarchive Note' : 'Archive Note',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to ${isArchived ? 'unarchive' : 'archive'} this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isArchived) {
                await DBHelper.instance.unarchiveNote(id);
              } else {
                await DBHelper.instance.archiveNote(id);
              }
              Navigator.of(context).pop();
              _fetchNotes();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: isArchived ? Colors.green : Colors.blue),
            child: Text(isArchived ? 'Unarchive' : 'Archive'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: TextField(
                controller: _searchController,
                decoration: const InputDecoration(hintText: 'Search notes...'),
                onChanged: _searchNotes,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(_showArchived ? Icons.folder_open : Icons.archive),
                  onPressed: _toggleArchivedView,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _filteredNotes.isEmpty
                    ? const Center(
                        child: Text('No Notes Found',
                            style: TextStyle(fontSize: 18)))
                    : ListView.builder(
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: const Color(
                                0xFFFFFFFF), // White background for cards
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      note['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
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
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note['content'] ?? ''),
                                  const SizedBox(height: 6),
                                  Text('Date: ${note['dateTime'] ?? ''}',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                        _showArchived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.grey),
                                    onPressed: () => _archiveNoteDialog(
                                        note['id'], _showArchived),
                                  ),
                                  if (!_showArchived)
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _addOrEditNote(note: note),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteNoteDialog(note['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (!_showArchived)
              FloatingActionButton(
                onPressed: () => _addOrEditNote(),
                backgroundColor: const Color(0xFF388E3C), // Match AppBar color
                child: const Icon(Icons.add, size: 30),
              ),
          ],
        ),
      ),
    );
  }
}
