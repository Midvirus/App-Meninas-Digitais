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
  int likes;
  final List<String> comments;

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
    this.likes = 0,
    List<String>? comments,
  }) : comments = comments ?? [];
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
      title: 'Desafio de Web Design',
      description: 'Crie um layout de site responsivo',
      user: 'Emma Johnson',
      category: 'Desafio',
      date: DateTime(2026, 4, 25),
      color: Colors.blue,
      tutor: 'Prof. David Miller',
      createdAt: DateTime.now(),
      likes: 24,
      comments: ['Ótimo desafio!', 'Animado para participar', 'Isso fica incrível', 'Quando começa?'],
    ),
    Pin(
      id: '2',
      title: 'Sessão de Revisão de Código',
      description: 'Revisão e feedback em projetos',
      user: 'Lisa Martinez',
      category: 'Reunião',
      date: DateTime(2026, 4, 18),
      color: Colors.green,
      tutor: 'Dr. Elena Rodriguez',
      createdAt: DateTime.now(),
      likes: 18,
      comments: ['Muito útil', 'Aprendi muito', 'Obrigado pelo feedback'],
    ),
    Pin(
      id: '3',
      title: 'Workshop do Flutter',
      description: 'Introdução ao desenvolvimento móvel',
      user: 'Sophie Chen',
      category: 'Workshop',
      date: DateTime(2026, 5, 10),
      color: Colors.purple,
      tutor: null,
      createdAt: DateTime.now(),
      likes: 32,
      comments: ['Mal posso esperar!', 'É gratuito?', 'Flutter é incrível', 'Me inscreva!', 'Haverá lanches?'],
    ),
    Pin(
      id: '4',
      title: 'Hackathon 2026',
      description: 'Crie apps incríveis em 48 horas',
      user: 'Rachel Brown',
      category: 'Evento',
      date: DateTime(2026, 6, 15),
      color: Colors.red,
      tutor: 'Prof. James Anderson',
      createdAt: DateTime.now(),
      likes: 45,
      comments: ['Isso será épico!', 'Formando um time', 'Qual é o prêmio?', 'Pode contar comigo!'],
    ),
    Pin(
      id: '5',
      title: 'Conceitos Básicos de Python',
      description: 'Aprenda fundamentos de programação',
      user: 'Jessica Lee',
      category: 'Curso',
      date: DateTime(2026, 4, 28),
      color: Colors.orange,
      tutor: null,
      createdAt: DateTime.now(),
      likes: 15,
      comments: ['Perfeito para iniciantes', 'Ótima introdução', 'Link do curso?'],
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
                likes: 0,
                comments: [],
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

  void _showPinDetails(BuildContext context, int pinIndex) {
    showDialog(
      context: context,
      builder: (context) => _PinDetailsDialog(
        pin: pins[pinIndex],
        onAddComment: (comment) {
          setState(() {
            pins[pinIndex].comments.add(comment);
          });
        },
        onLike: () {
          setState(() {
            pins[pinIndex].likes++;
          });
        },
      ),
    );
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
                    'Nenhum post ainda',
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
                  child: _PinCard(
                    pin: pin,
                    onDelete: () => _deletePin(pin.id),
                    onTap: () => _showPinDetails(context, index),
                    onLike: () => setState(() => pins[index].likes++),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPin,
        tooltip: 'Adicionar Post',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  final Pin pin;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _PinCard({
    required this.pin,
    required this.onDelete,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: pin.color.withAlpha(200),
        child: InkWell(
          onTap: onTap,
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
                                    'Orientador: ${pin.tutor}',
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
                        Expanded(
                          child: Text(
                            'Por ${pin.user}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
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
                    // Instagram-style engagement metrics
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onLike,
                          child: Row(
                            children: [
                              Icon(Icons.favorite_outline, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                '${pin.likes}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(Icons.comment_outlined, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${pin.comments.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
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

class _PinDetailsDialog extends StatefulWidget {
  final Pin pin;
  final Function(String) onAddComment;
  final VoidCallback onLike;

  const _PinDetailsDialog({
    required this.pin,
    required this.onAddComment,
    required this.onLike,
  });

  @override
  State<_PinDetailsDialog> createState() => _PinDetailsDialogState();
}

class _PinDetailsDialogState extends State<_PinDetailsDialog> {
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with pin details
            Container(
              color: widget.pin.color.withAlpha(200),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pin.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.pin.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.pin.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.pin.tutor != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Orientador: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: widget.pin.tutor,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'De: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: widget.pin.user,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data: ${_formatDate(widget.pin.date)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // Engagement metrics
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.onLike,
                    icon: const Icon(Icons.favorite_outline),
                    label: Text('${widget.pin.likes}'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.comment_outlined),
                        const SizedBox(width: 8),
                        Text('${widget.pin.comments.length} comentários'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Seção de comentários
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.pin.comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Sem comentários ainda. Seja o primeiro!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.pin.comments.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Usuário ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.pin.comments[index],
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Add comment section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Adicione um comentário...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        widget.onAddComment(commentController.text);
                        commentController.clear();
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
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
      title: const Text('Adicionar Novo Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userController,
              decoration: const InputDecoration(
                labelText: 'Usuário/Autor',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tutorController,
              decoration: const InputDecoration(
                labelText: 'Orientador/Mentor (Opcional)',
                border: OutlineInputBorder(),
                hintText: 'Nome do orientador ou deixe em branco',
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Data: ${_formatDate(selectedDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Selecionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Selecionar Cor:', style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (titleController.text.isNotEmpty && userController.text.isNotEmpty) {
              widget.onAdd(
                titleController.text,
                descriptionController.text,
                userController.text,
                categoryController.text.isNotEmpty ? categoryController.text : 'Geral',
                selectedDate,
                selectedColor,
                tutorController.text.isNotEmpty ? tutorController.text : null,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}