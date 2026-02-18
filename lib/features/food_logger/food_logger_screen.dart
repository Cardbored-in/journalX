import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../data/models/meal.dart';
import '../../data/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class FoodLoggerScreen extends StatefulWidget {
  const FoodLoggerScreen({super.key});

  @override
  State<FoodLoggerScreen> createState() => _FoodLoggerScreenState();
}

class _FoodLoggerScreenState extends State<FoodLoggerScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  List<Meal> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMeals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMeals();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final mealsData = await DatabaseHelper.instance.queryAll('meals');
      setState(() {
        _meals = mealsData.map((map) => Meal.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading meals: $e')));
      }
    }
  }

  Future<void> _addMeal() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    // Show dialog to get meal details
    final titleController = TextEditingController();
    final noteController = TextEditingController();

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(image.path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Meal title...',
                      labelText: 'Title',
                    ),
                    autofocus: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: "Chef's note (optional)...",
                labelText: "Chef's Note",
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Meal'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      // Save image to permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final mealsDir = Directory('${appDir.path}/meals');
      if (!await mealsDir.exists()) {
        await mealsDir.create(recursive: true);
      }

      final uuid = const Uuid();
      final fileName = '${uuid.v4()}.jpg';
      final savedPath = '${mealsDir.path}/$fileName';

      await File(image.path).copy(savedPath);

      // Save to database
      final meal = Meal(
        id: uuid.v4(),
        title: titleController.text,
        imagePath: savedPath,
        chefNote: noteController.text.isEmpty ? null : noteController.text,
        createdAt: DateTime.now(),
      );

      await DatabaseHelper.instance.insert('meals', meal.toMap());
      _loadMeals();
    }
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.title}"?'),
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
      // Delete image file
      final file = File(meal.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Delete from database
      await DatabaseHelper.instance.delete('meals', meal.id);
      _loadMeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Journal')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meals.isEmpty
              ? _buildEmptyState()
              : _buildMealsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMeal,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Meal'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No meals yet',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first meal',
            style: TextStyle(color: AppTheme.onSurfaceColor.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _meals.length,
      itemBuilder: (context, index) {
        final meal = _meals[index];
        return _buildMealCard(meal);
      },
    );
  }

  Widget _buildMealCard(Meal meal) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return GestureDetector(
      onTap: () => _showMealDetails(meal),
      onLongPress: () => _deleteMeal(meal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.file(
                File(meal.imagePath),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppTheme.surfaceColor,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(meal.createdAt),
                    style: TextStyle(
                      color: AppTheme.onSurfaceColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  if (meal.chefNote != null && meal.chefNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meal.chefNote!,
                      style: TextStyle(
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealDetails(Meal meal) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • h:mm a');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.file(
                  File(meal.imagePath),
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(meal.createdAt),
                      style: TextStyle(
                        color: AppTheme.onSurfaceColor.withOpacity(0.5),
                      ),
                    ),
                    if (meal.chefNote != null && meal.chefNote!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        "Chef's Note:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal.chefNote!,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
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
            ],
          ),
        ),
      ),
    );
  }
}
