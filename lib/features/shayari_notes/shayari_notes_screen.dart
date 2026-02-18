import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../data/models/note.dart';
import '../../data/models/entry.dart';
import '../../data/models/entry_type.dart';
import '../../data/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class ShayariNotesScreen extends StatefulWidget {
  const ShayariNotesScreen({super.key});

  @override
  State<ShayariNotesScreen> createState() => _ShayariNotesScreenState();
}

class _ShayariNotesScreenState extends State<ShayariNotesScreen>
    with WidgetsBindingObserver {
  List<Entry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotes();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      // Load from unified entries table
      final entriesData = await DatabaseHelper.instance.getAllEntries();
      // Filter for journal type
      final journalEntries = entriesData
          .where((e) =>
              e.type == EntryType.journal ||
              e.type == EntryType.midnightThought ||
              e.type == EntryType.spark ||
              e.type == EntryType.media ||
              e.type == EntryType.dream)
          .toList();

      setState(() {
        _entries = journalEntries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
      }
    }
  }

  Future<void> _addNote() async {
    final contentController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.onSurfaceColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: InputBorder.none,
              ),
              maxLines: 8,
              style: const TextStyle(fontSize: 18, height: 1.6),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && contentController.text.isNotEmpty) {
      final now = DateTime.now();
      // Save as unified Entry
      final entry = Entry(
        id: const Uuid().v4(),
        type: EntryType.journal,
        content: contentController.text,
        createdAt: now,
        updatedAt: now,
      );

      await DatabaseHelper.instance.insertEntry(entry);
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.delete('notes', note.id);
      _loadNotes();
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood) {
      case 'Happy':
        return Colors.yellow;
      case 'Sad':
        return Colors.blue;
      case 'Inspired':
        return Colors.orange;
      case 'Calm':
        return Colors.teal;
      case 'Anxious':
        return Colors.purple;
      case 'Grateful':
        return Colors.green;
      case 'Angry':
        return Colors.red;
      case 'Peaceful':
        return Colors.cyan;
      case 'Melancholy':
        return Colors.indigo;
      case 'Hopeful':
        return Colors.pink;
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zen Space')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOptions,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create New',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.edit_note,
              title: 'Journal',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                _addNote();
              },
            ),
            _buildOptionTile(
              icon: Icons.nightlight_round,
              title: 'Midnight Thought',
              color: Colors.green.shade700,
              onTap: () {
                Navigator.pop(context);
                _addMidnightThought();
              },
            ),
            _buildOptionTile(
              icon: Icons.lightbulb,
              title: 'Spark (Idea)',
              color: Colors.amber,
              onTap: () {
                Navigator.pop(context);
                _addSpark();
              },
            ),
            _buildOptionTile(
              icon: Icons.movie,
              title: 'Media Review',
              color: Colors.purple,
              onTap: () {
                Navigator.pop(context);
                _addMedia();
              },
            ),
            _buildOptionTile(
              icon: Icons.cloud,
              title: 'Dream',
              color: Colors.indigo,
              onTap: () {
                Navigator.pop(context);
                _addDream();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _addMidnightThought() async {
    final contentController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Midnight Thought',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(color: Colors.green),
                border: InputBorder.none,
              ),
              style: const TextStyle(color: Colors.green, fontSize: 16),
              maxLines: 8,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && contentController.text.isNotEmpty) {
      final entry = Entry(
        id: const Uuid().v4(),
        type: EntryType.midnightThought,
        content: contentController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertEntry(entry);
      _loadNotes();
    }
  }

  Future<void> _addSpark() async {
    final contentController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Spark (Idea)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'Got an idea? Write it down!',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && contentController.text.isNotEmpty) {
      final entry = Entry(
        id: const Uuid().v4(),
        type: EntryType.spark,
        content: contentController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertEntry(entry);
      _loadNotes();
    }
  }

  Future<void> _addMedia() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int rating = 3;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.movie, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Media Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Movie/Book name',
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    hintText: 'Your thoughts...',
                    labelText: 'Review',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text('Rating'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setModalState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true &&
        (titleController.text.isNotEmpty ||
            contentController.text.isNotEmpty)) {
      final entry = Entry(
        id: const Uuid().v4(),
        type: EntryType.media,
        title: titleController.text.isNotEmpty ? titleController.text : null,
        content: contentController.text,
        metadata: {'rating': rating},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertEntry(entry);
      _loadNotes();
    }
  }

  Future<void> _addDream() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int clarity = 3;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud, color: Colors.indigo, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Dream',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Dream title (optional)',
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your dream...',
                    labelText: 'Dream',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                const Text('Clarity'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < clarity ? Icons.cloud : Icons.cloud_outlined,
                        color: Colors.indigo,
                        size: 32,
                      ),
                      onPressed: () {
                        setModalState(() {
                          clarity = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && contentController.text.isNotEmpty) {
      final entry = Entry(
        id: const Uuid().v4(),
        type: EntryType.dream,
        title: titleController.text.isNotEmpty ? titleController.text : null,
        content: contentController.text,
        metadata: {'rating': clarity},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertEntry(entry);
      _loadNotes();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to write your first note',
            style: TextStyle(color: AppTheme.onSurfaceColor.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(Entry entry) {
    final dateFormat = DateFormat('h:mm a');
    final entryColor = _getEntryColor(entry.type);

    return GestureDetector(
      onTap: () => _showEntryDetails(entry),
      onLongPress: () => _deleteEntry(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: entryColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getEntryIcon(entry.type), color: entryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  entry.type.displayName,
                  style: TextStyle(
                    color: entryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(entry.createdAt),
                  style: TextStyle(
                    color: AppTheme.onSurfaceColor.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getEntryColor(EntryType type) {
    switch (type) {
      case EntryType.journal:
        return AppTheme.primaryColor;
      case EntryType.midnightThought:
        return Colors.green.shade700;
      case EntryType.spark:
        return Colors.amber.shade700;
      case EntryType.media:
        return Colors.purple;
      case EntryType.dream:
        return Colors.indigo;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getEntryIcon(EntryType type) {
    switch (type) {
      case EntryType.journal:
        return Icons.edit_note;
      case EntryType.midnightThought:
        return Icons.nightlight_round;
      case EntryType.spark:
        return Icons.lightbulb;
      case EntryType.media:
        return Icons.movie;
      case EntryType.dream:
        return Icons.cloud;
      default:
        return Icons.edit_note;
    }
  }

  Future<void> _deleteEntry(Entry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteEntry(entry.id);
      _loadNotes();
    }
  }

  void _showEntryDetails(Entry entry) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • h:mm a');
    final entryColor = _getEntryColor(entry.type);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getEntryIcon(entry.type), color: entryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    entry.type.displayName,
                    style: TextStyle(
                      color: entryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                entry.content,
                style: const TextStyle(fontSize: 16, height: 1.8),
              ),
              const SizedBox(height: 20),
              Text(
                dateFormat.format(entry.createdAt),
                style: TextStyle(
                  color: AppTheme.onSurfaceColor.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
