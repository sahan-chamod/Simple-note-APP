import 'package:flutter/material.dart';
import '../dbhelper/db_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  TextEditingController _searchController = TextEditingController();
  String? _selectedCategorySort;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final notes =
        await DBHelper.instance.getNotes();

    setState(() {
      _notes = notes ?? [];
      _applyCategoryFilter();
    });
  }

  void _applyCategoryFilter() {
    if (_selectedCategorySort == null || _selectedCategorySort == 'All') {
      _filteredNotes = _notes;
    } else {
      _filteredNotes = _notes
          .where((note) => note['category'] == _selectedCategorySort)
          .toList();
    }
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Text(note == null ? 'Add Note' : 'Edit Note',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: contentController,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      items: ['High', 'Medium', 'Low'].map((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedPriority = newValue;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: ['Work', 'Personal', 'Study', 'General']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final dateTime = DateTime.now().toString();
                      final newNote = {
                        'title': titleController.text,
                        'content': contentController.text,
                        'priority': selectedPriority,
                        'category': selectedCategory,
                        'createdAt': note?['createdAt'] ?? dateTime,
                        'updatedAt': dateTime,
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
              ),
            ],
          ),
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
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Search notes...'),
          onChanged: _searchNotes,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: _selectedCategorySort,
            hint: Text('Sort'),
            items:
                ['All', 'Work', 'Personal', 'Study', 'General'].map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newCategory) {
              setState(() {
                _selectedCategorySort = newCategory;
                _applyCategoryFilter();
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
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
                            child: ListTile(
                              title: Text(note['title'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note['content'] ?? ''),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${note['createdAt']}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Priority: ${note['priority']}',
                                    style: TextStyle(
                                        color: _getPriorityColor(
                                            note['priority'])),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _addOrEditNote(note: note),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteNoteDialog(note['id']),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        backgroundColor: const Color(0xFF448AFF),
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
        tooltip: 'Add New Note',
      ),
    );
  }
}
