import 'package:flutter/material.dart';
import 'NavBar.dart';

class Pin {
  final String id;
  final String title;
  final String description;
  final String user;
  final String category;
  final DateTime date;
  final Color color;
  final String? tutor;
  final DateTime createdAt;

  Pin({
    required this.id,
    required this.title,
    required this.description,
    required this.user,
    required this.category,
    required this.date,
    required this.color,
    this.tutor,
    required this.createdAt,
  });
}

class PinboardPage extends StatefulWidget {
  const PinboardPage({super.key, required this.title});
  final String title;

  @override
  State<PinboardPage> createState() => _PinboardPageState();
}

class _PinboardPageState extends State<PinboardPage> {
  late List<Pin> pins = [
    Pin(
      id: '1',
      title: 'Web Design Challenge',
      description: 'Create a responsive website layout',
      user: 'Emma Johnson',
      category: 'Challenge',
      date: DateTime(2026, 4, 25),
      color: Colors.blue,
      tutor: 'Prof. David Miller',
      createdAt: DateTime.now(),
    ),
    Pin(
      id: '2',
      title: 'Code Review Session',
      description: 'Review and feedback on projects',
      user: 'Lisa Martinez',
      category: 'Meeting',
      date: DateTime(2026, 4, 18),
      color: Colors.green,
      tutor: 'Dr. Elena Rodriguez',
      createdAt: DateTime.now(),
    ),
    Pin(
      id: '3',
      title: 'Flutter Workshop',
      description: 'Introduction to mobile development',
      user: 'Sophie Chen',
      category: 'Workshop',
      date: DateTime(2026, 5, 10),
      color: Colors.purple,
      tutor: null,
      createdAt: DateTime.now(),
    ),
    Pin(
      id: '4',
      title: 'Hackathon 2026',
      description: 'Build amazing apps in 48 hours',
      user: 'Rachel Brown',
      category: 'Event',
      date: DateTime(2026, 6, 15),
      color: Colors.red,
      tutor: 'Prof. James Anderson',
      createdAt: DateTime.now(),
    ),
    Pin(
      id: '5',
      title: 'Python Basics',
      description: 'Learn programming fundamentals',
      user: 'Jessica Lee',
      category: 'Course',
      date: DateTime(2026, 4, 28),
      color: Colors.orange,
      tutor: null,
      createdAt: DateTime.now(),
    ),
  ];

  void _addPin() {
    showDialog(
      context: context,
      builder: (context) => _AddPinDialog(
        onAdd: (title, description, user, category, date, color, tutor) {
          setState(() {
            pins.add(
              Pin(
                id: DateTime.now().toString(),
                title: title,
                description: description,
                user: user,
                category: category,
                date: date,
                color: color,
                tutor: tutor,
                createdAt: DateTime.now(),
              ),
            );
          });
        },
      ),
    );
  }

  void _deletePin(String id) {
    setState(() {
      pins.removeWhere((pin) => pin.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: NavBar.buildDrawer(context),
      body: pins.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.push_pin_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pins yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pins.length,
              itemBuilder: (context, index) {
                final pin = pins[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 100,
                    child: _PinCard(
                      pin: pin,
                      onDelete: () => _deletePin(pin.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPin,
        tooltip: 'Add Pin',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final Pin pin;
  final VoidCallback onDelete;

  const _PinCard({
    required this.pin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: pin.color.withAlpha(200),
        child: InkWell(
          onTap: () {},
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pin.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (pin.tutor != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Tutor: ${pin.tutor}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                pin.category,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      pin.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'By ${pin.user}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          _formatDate(pin.date),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  iconSize: 18,
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddPinDialog extends StatefulWidget {
  final Function(String title, String description, String user, String category, DateTime date, Color color, String? tutor) onAdd;

  const _AddPinDialog({required this.onAdd});

  @override
  State<_AddPinDialog> createState() => _AddPinDialogState();
}

class _AddPinDialogState extends State<_AddPinDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController userController;
  late TextEditingController categoryController;
  late TextEditingController tutorController;
  DateTime selectedDate = DateTime.now();
  Color selectedColor = Colors.pink;

  final List<Color> colors = [
    Colors.pink,
    Colors.purple,
    Colors.orange,
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.yellow,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    userController = TextEditingController();
    categoryController = TextEditingController();
    tutorController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    userController.dispose();
    categoryController.dispose();
    tutorController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Pin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: 'User/Author',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tutorController,
              decoration: const InputDecoration(
                labelText: 'Tutor/Mentor (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Name of the tutor or leave blank',
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${_formatDate(selectedDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Pick'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Select Color:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (titleController.text.isNotEmpty && userController.text.isNotEmpty) {
              widget.onAdd(
                titleController.text,
                descriptionController.text,
                userController.text,
                categoryController.text.isNotEmpty ? categoryController.text : 'General',
                selectedDate,
                selectedColor,
                tutorController.text.isNotEmpty ? tutorController.text : null,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}