import 'package:flutter/material.dart';
import 'NavBar.dart';
import 'api_client.dart';
import 'global_state.dart';

class Pin {
  final dynamic id;
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

  /// Parse from backend PostCuriosidade JSON, mapping fields as closely as possible.
  factory Pin.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    // Extract tutora (author) name from nested object
    String authorName = '';
    String? tutorName;
    final tutora = json['tutora'];
    if (tutora != null && tutora is Map<String, dynamic>) {
      authorName = tutora['nome'] as String? ?? '';
      // If the tutora has a tutora field too (for tutorandas), extract it
      final tutoraOfTutora = tutora['tutora'];
      if (tutoraOfTutora != null && tutoraOfTutora is Map<String, dynamic>) {
        tutorName = tutoraOfTutora['nome'] as String?;
      }
    }

    // Map backend categoria enum to display string
    final categoria = json['categoria'] as String? ?? 'Geral';

    // Count likes from curtidas list
    final curtidas = json['curtidas'] as List<dynamic>?;
    final likesCount = curtidas?.length ?? 0;

    return Pin(
      id: json['id'],
      title: json['titulo'] as String? ?? '',
      description: json['texto'] as String? ?? '',
      user: authorName,
      category: categoria,
      date: parseDate(json['criadoEm']),
      color: _categoryColor(categoria),
      tutor: tutorName ?? authorName,
      createdAt: parseDate(json['criadoEm']),
      likes: likesCount,
    );
  }

  /// Assign a color based on category for visual variety
  static Color _categoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'TECNOLOGIA':
        return Colors.blue;
      case 'CIENCIA':
        return Colors.green;
      case 'CURIOSIDADE':
        return Colors.purple;
      case 'INSPIRACAO':
        return Colors.orange;
      case 'CARREIRA':
        return Colors.teal;
      default:
        return Colors.pink;
    }
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
    _checkAuthAndLoadPins();
  }

  Future<void> _checkAuthAndLoadPins() async {
    if (!GlobalState.isLoggedIn) {
      // Not authenticated, redirect to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    await _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() {
      _isLoadingPins = true;
      _pinError = null;
    });

    try {
      final rawPins = await ApiClient.listPosts();
      if (!mounted) return;
      setState(() {
        pins = rawPins
            .map((item) => Pin.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoadingPins = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _pinError = error.message;
        _isLoadingPins = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pinError = error.toString();
        _isLoadingPins = false;
      });
    }
  }

  Future<void> _deletePin(dynamic id) async {
    try {
      await ApiClient.deletePost(id);
      await _loadPins();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir post: ${error.message}')),
      );
    }
  }

  Future<void> _likePin(dynamic id) async {
    try {
      await ApiClient.likePost(id);
      await _loadPins();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao curtir post: ${error.message}')),
      );
    }
  }

  void _addPin() {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddPinDialog(
        onAdd: (title, description, category, date) async {
          try {
            // Map category to match backend Enum where possible
            // String backendCategory = 'GERAL';
            // final catUpper = category.toUpperCase();
            // if (catUpper.contains('MULHER') || catUpper.contains('CIÊNCIA') || catUpper.contains('CIENCIA')) {
            //   backendCategory = 'MULHERES_NA_CIENCIA';
            // } else if (catUpper.contains('CARREIRA')) {
            //   backendCategory = 'CARREIRA';
            // } else if (catUpper.contains('PROGRAMA')) {
            //   backendCategory = 'PROGRAMACAO';
            // } else {
            //   backendCategory = 'TECNOLOGIA'; // Default fallback
            // }
            
            String backendCategory = category.toUpperCase().replaceAll('Ê', 'E').replaceAll('Ç', 'C').replaceAll('Ã', 'A').replaceAll('Á', 'A');

            await ApiClient.publicar({
              'titulo': title,
              'texto': description,
              'categoria': backendCategory,
            });
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post criado com sucesso!')),
            );
            await _loadPins();
          } on ApiException catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao criar post: ${error.message}')),
            );
          } catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro inesperado: $error')),
            );
          }
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
          _likePin(pins[pinIndex].id);
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
                            onLike: () => _likePin(pin.id),
                          ),
                        );
                      },
                    ),
      floatingActionButton: GlobalState.userRole != 'Tutoranda'
          ? FloatingActionButton(
              onPressed: _addPin,
              tooltip: 'Adicionar Post',
              child: const Icon(Icons.add),
            )
          : null,
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
                          // Autor
                          Text(
                            'Tutor: ${pin.user}',
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
                          if (GlobalState.userRole?.toLowerCase() == 'admin')
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
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Tutor: ',
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
  final Function(String title, String description, String category, DateTime date) onAdd;

  const _AddPinDialog({required this.onAdd});

  @override
  State<_AddPinDialog> createState() => _AddPinDialogState();
}

class _AddPinDialogState extends State<_AddPinDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  DateTime selectedDate = DateTime.now();
  String selectedCategory = 'Tecnologia';
  
  final List<String> categories = ['Tecnologia', 'Ciência', 'Curiosidade', 'Inspiração', 'Carreira', 'Outros'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
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
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
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
            if (titleController.text.isNotEmpty) {
              widget.onAdd(
                titleController.text,
                descriptionController.text,
                selectedCategory,
                selectedDate,
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