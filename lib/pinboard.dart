import 'package:flutter/material.dart';
import 'package:postgrest/postgrest.dart';
import 'NavBar.dart';
import 'supabase_client.dart';

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
  });

  factory Pin.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return Pin(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      user: json['user'] as String? ?? '',
      category: json['category'] as String? ?? 'Geral',
      date: parseDate(json['date']),
      color: Color(json['color'] as int? ?? Colors.blue.toARGB32()),
      tutor: json['tutor'] as String?,
      createdAt: parseDate(json['created_at']),
      likes: json['likes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'user': user,
      'category': category,
      'date': date.toIso8601String(),
      'color': color.toARGB32(),
      'tutor': tutor,
      'created_at': createdAt.toUtc().toIso8601String(),
      'likes': likes,
    };
  }
}

class PinboardPage extends StatefulWidget {
  const PinboardPage({super.key, required this.title});
  final String title;

  @override
  State<PinboardPage> createState() => _PinboardPageState();
}

class _PinboardPageState extends State<PinboardPage> {
  List<Pin> pins = [];
  bool _isLoadingPins = true;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() {
      _isLoadingPins = true;
      _pinError = null;
    });

    try {
      final rawPins = await supabase.from('pins').select().order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        pins = (rawPins as List<dynamic>)
            .map((item) => Pin.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoadingPins = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _pinError = error.message;
        _isLoadingPins = false;
      });
    }
  }

  Future<void> _savePin(Pin pin) async {
    try {
      await supabase.from('pins').insert(pin.toJson());
      await _loadPins();
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar post: ${error.message}')),
      );
    }
  }

  Future<void> _updatePin(Pin pin) async {
    try {
      await supabase.from('pins').update(pin.toJson()).eq('id', pin.id);
      await _loadPins();
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar post: ${error.message}')),
      );
    }
  }

  Future<void> _deletePin(String id) async {
    try {
      await supabase.from('pins').delete().eq('id', id);
      await _loadPins();
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir post: ${error.message}')),
      );
    }
  }

  void _addPin() {
    showDialog(
      context: context,
      builder: (context) => _AddPinDialog(
        onAdd: (title, description, user, category, date, color, tutor) async {
          await _savePin(
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
            ),
          );
        },
      ),
    );
  }

  void _showPinDetails(BuildContext context, int pinIndex) {
    showDialog(
      context: context,
      builder: (context) => _PinDetailsDialog(
        pin: pins[pinIndex],
        onLike: () {
          final updatedPin = pins[pinIndex];
          updatedPin.likes++;
          _updatePin(updatedPin);
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
      body: _isLoadingPins
          ? const Center(child: CircularProgressIndicator())
          : _pinError != null
              ? Center(
                  child: Text(
                    'Erro ao carregar posts: $_pinError',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : pins.isEmpty
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
                            onLike: () {
                              final updatedPin = Pin(
                                id: pin.id,
                                title: pin.title,
                                description: pin.description,
                                user: pin.user,
                                category: pin.category,
                                date: pin.date,
                                color: pin.color,
                                tutor: pin.tutor,
                                createdAt: pin.createdAt,
                                likes: pin.likes + 1,
                              );
                              _updatePin(updatedPin);
                            },
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
          child: Padding(
            padding: const EdgeInsets.all(12), // um pouco mais compacto
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // LINHA 1: TÍTULO
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

                const SizedBox(height: 10),

                // LINHA 2: DUAS COLUNAS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================
                    // COLUNA ESQUERDA
                    // Tutor, autor, likes
                    // ==========================
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pin.tutor != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                            const SizedBox(height: 6),
                          ],

                          // Autor
                          Text(
                            'Por ${pin.user}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Likes
                          GestureDetector(
                            onTap: onLike,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite_outline,
                                  size: 14,
                                  color: Colors.white70,
                                ),
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
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),

                    // ==========================
                    // COLUNA DIREITA
                    // Linha 1: botão delete
                    // Linha 2: categoria
                    // Linha 3: data
                    // ==========================
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // Linha 2: categoria
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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

                          const SizedBox(height: 6),

                          // Linha 3: data
                          Text(
                            _formatDate(pin.date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                            ),
                          ),
                                                    // Linha 1: botão apagar (no topo)
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(999),
                            child: const Padding(
                              padding: EdgeInsets.all(2), // controle fino da área de toque
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _PinDetailsDialog extends StatelessWidget {
  final Pin pin;
  final VoidCallback onLike;

  const _PinDetailsDialog({
    required this.pin,
    required this.onLike,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Diálogo detalhado sem os comentários
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==========================
            // HEADER COLORIDO
            // ==========================
            Container(
              decoration: BoxDecoration(
                color: pin.color.withAlpha(200),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + categoria + botão fechar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pin.title,
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
                                pin.category,
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
                  if (pin.tutor != null)
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
                              text: pin.tutor,
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
                          text: pin.user,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data: ${_formatDate(pin.date)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título da seção (opcional)
                    const Text(
                      'Descrição',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Área rolável para o texto da descrição
                    Expanded(
                      child: SingleChildScrollView(
                        // scrollbar invisível (apenas gesto de scroll)
                        child: Text(
                          pin.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),  
          ],
        ),
      ),
    );
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

  // Adicionar POST
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