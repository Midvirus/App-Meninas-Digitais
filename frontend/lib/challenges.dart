import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'NavBar.dart';
import 'global_state.dart';
import 'api_client.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key, required this.title});
  final String title;

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

enum TutorResponseType { multipleChoice, text, file }

class TutorChallenge {
  final String question;
  final TutorResponseType responseType;
  final List<String> options;
  final String description;
  final String tutorName;

  TutorChallenge({
    required this.question,
    required this.responseType,
    this.options = const [],
    this.description = '',
    this.tutorName = '',
  });
}

class _ChallengesPageState extends State<ChallengesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTabIndex = 0;

  List<dynamic> get globalChallenges => _apiChallenges.where((c) => c['paraTodasTutorandas'] == true && c['tipoResposta'] == 'MULTIPLA_ESCOLHA').toList();

  List<dynamic> _apiChallenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _tabController = TabController(
      length: GlobalState.userRole == 'admin' ? 1 : 2, 
      vsync: this
    );
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _loadApiChallenges();
  }

  Future<void> _loadApiChallenges() async {
    try {
      List<dynamic> data = [];
      if (GlobalState.userRole == 'Tutoranda') {
        data = await ApiClient.listChallengesForTutoranda();
      } else if (GlobalState.userRole == 'Tutor' || GlobalState.userRole == 'Tutora') {
        data = await ApiClient.listChallengesForTutora();
      }
      
      if (mounted) {
        setState(() {
          _apiChallenges = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar desafios: $e')),
        );
      }
    }
  }

  final Map<int, String> _selectedAnswers = {};
  final Map<int, String> _tutorSelectedChoices = {};
  final Map<int, TextEditingController> _tutorTextControllers = {};
  final Map<int, String> _tutorFileNames = {};
  final Map<int, PlatformFile?> _tutorPickedFiles = {};

  // Gamification tracking
  int _totalAttempts = 0;
  int _correctAnswers = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalPoints = 0;
  final DateTime _firstChallengeDate = DateTime.now();
  final Map<int, bool> _answeredCorrectly = {};

  // (initState removido porque movi pra cima junto com _loadApiChallenges)

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _tutorTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAuth() async {
    if (!GlobalState.isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _selectAnswer(int index, String? value) {
    if (value == null) return;
    setState(() {
      _selectedAnswers[index] = value;
    });
  }

  void _submitResponse(int index) {
    final selected = _selectedAnswers[index];
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma opção antes de enviar.')),
      );
      return;
    }

    final challenge = globalChallenges[index];
    final isCorrect = selected == challenge['respostaCorreta'];

    setState(() {
      if (!_answeredCorrectly.containsKey(index)) {
        _totalAttempts++;
        _answeredCorrectly[index] = isCorrect;

        if (isCorrect) {
          _correctAnswers++;
          _currentStreak++;
          _totalPoints += 10;
          if (_currentStreak > _bestStreak) {
            _bestStreak = _currentStreak;
          }
        } else {
          _currentStreak = 0;
          _totalPoints += 2;
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Resposta Correta' : 'Resposta Incorreta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect
                  ? 'Muito bem!'
                  : 'A resposta correta é "${challenge['respostaCorreta']}".',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCorrect ? '+10 pontos!' : '+2 pontos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _selectTutorChoice(int index, String? value) {
    if (value == null) return;
    setState(() {
      _tutorSelectedChoices[index] = value;
    });
  }

  TextEditingController _getTutorTextController(int index) {
    return _tutorTextControllers.putIfAbsent(index, () => TextEditingController());
  }

  Future<void> _selectTutorFile(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        setState(() {
          _tutorPickedFiles[index] = picked;
          _tutorFileNames[index] = picked.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  void _submitTutorResponse(int index) async {
    final challenge = _apiChallenges[index];
    final responseType = challenge['tipoResposta'];
    final desafioId = challenge['id'];
    String? responseText;
    String? filePath;

    // A API só retorna os tipos mapeados em ResponseType: TEXTO, ARQUIVO, CODIGO, IMAGEM
    if (responseType == 'TEXTO' || responseType == 'CODIGO') {
      responseText = _getTutorTextController(index).text.trim();
      if (responseText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite sua resposta antes de enviar.')),
        );
        return;
      }
    } else if (responseType == 'ARQUIVO' || responseType == 'IMAGEM') {
      final picked = _tutorPickedFiles[index];
      if (picked == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um arquivo antes de enviar.')),
        );
        return;
      }
      responseText = picked.name;
      filePath = picked.path; // ou bytes se for web
    }

    try {
      if (responseType == 'ARQUIVO' || responseType == 'IMAGEM') {
        if (filePath != null) {
          await ApiClient.enviarResposta(desafioId, filePath: filePath);
        } else {
           // Usar bytes se for web, no flutter seria picked.bytes
          final picked = _tutorPickedFiles[index];
          await ApiClient.enviarResposta(
            desafioId,
            fileBytes: picked?.bytes,
            fileName: picked?.name,
          );
        }
      } else {
        await ApiClient.enviarResposta(desafioId, textoResposta: responseText);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar resposta: $e')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resposta enviada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sua resposta foi enviada com sucesso.'),
            if (responseText != null) ...[
              const SizedBox(height: 12),
              Text('Resposta: $responseText'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAddChallengeDialog() {
    final questionController = TextEditingController();
    final optionControllers = <TextEditingController>[
      TextEditingController(),
    ];

    int? selectedCorrectIndex = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar novo desafio'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 100,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: questionController,
                        decoration: const InputDecoration(
                          labelText: 'Enunciado do desafio',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Opções de resposta',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            tooltip: 'Remover opção',
                            onPressed: optionControllers.length > 1
                                ? () {
                                    setStateDialog(() {
                                      if (selectedCorrectIndex != null &&
                                          selectedCorrectIndex! ==
                                              optionControllers.length - 1) {
                                        selectedCorrectIndex =
                                            optionControllers.length - 2;
                                      }
                                      optionControllers.removeLast();
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'Adicionar opção',
                            onPressed: optionControllers.length < 4
                                ? () {
                                    setStateDialog(() {
                                      optionControllers
                                          .add(TextEditingController());
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: List.generate(optionControllers.length, (index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: selectedCorrectIndex,
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      selectedCorrectIndex = value;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: optionControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Opção ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final question = questionController.text.trim();
                    final options = optionControllers
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    if (question.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Digite o enunciado do desafio.')),
                      );
                      return;
                    }

                    if (options.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Adicione pelo menos uma opção de resposta.')),
                      );
                      return;
                    }

                    if (selectedCorrectIndex == null ||
                        selectedCorrectIndex! >= options.length) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Selecione uma opção correta válida.')),
                      );
                      return;
                    }

                    final correctAnswer = options[selectedCorrectIndex!];
                    final justification =
                        'Esta é a resposta correta para este desafio.';

                    ApiClient.createChallenge({
                      'titulo': 'Desafio Global',
                      'descricao': question,
                      'nivelDificuldade': 'MEDIA',
                      'tipoResposta': 'MULTIPLA_ESCOLHA',
                      'tags': '',
                      'opcoes': options,
                      'respostaCorreta': correctAnswer,
                      'paraTodasTutorandas': true,
                    }).then((_) {
                      _loadApiChallenges();
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao criar desafio global: $e')),
                      );
                    });

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRemoveChallenge(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remover desafio'),
          content: const Text(
            'Tem certeza que deseja remover este desafio?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final challengeId = globalChallenges[index]['id'];
                ApiClient.removerDesafio(challengeId).then((_) {
                  _loadApiChallenges();
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao remover: $e')),
                  );
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Remover',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTutorChallengeDialog() {
    final questionController = TextEditingController();
    final optionControllers = <TextEditingController>[
      TextEditingController(),
    ];
    TutorResponseType selectedType = TutorResponseType.multipleChoice;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Adicionar desafio do tutor'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 100,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<TutorResponseType>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Desafio',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TutorResponseType.multipleChoice,
                            child: Text('Alternativa'),
                          ),
                          DropdownMenuItem(
                            value: TutorResponseType.text,
                            child: Text('Texto'),
                          ),
                          DropdownMenuItem(
                            value: TutorResponseType.file,
                            child: Text('Arquivo'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: questionController,
                        decoration: const InputDecoration(
                          labelText: 'Enunciado do desafio',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      if (selectedType == TutorResponseType.multipleChoice) ...[
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Opções de resposta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              tooltip: 'Remover opção',
                              onPressed: optionControllers.length > 1
                                  ? () {
                                      setStateDialog(() {
                                        optionControllers.removeLast();
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Adicionar opção',
                              onPressed: optionControllers.length < 4
                                  ? () {
                                      setStateDialog(() {
                                        optionControllers
                                            .add(TextEditingController());
                                      });
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: List.generate(optionControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: TextField(
                                controller: optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Opção ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final question = questionController.text.trim();
                    if (question.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Digite o enunciado.')),
                      );
                      return;
                    }

                    String apiResponseType = 'TEXTO';
                    if (selectedType == TutorResponseType.text) {
                      apiResponseType = 'TEXTO';
                    } else if (selectedType == TutorResponseType.file) {
                      apiResponseType = 'ARQUIVO';
                    } else if (selectedType == TutorResponseType.multipleChoice) {
                      apiResponseType = 'TEXTO'; // Fallback for backend
                    }

                    ApiClient.createChallenge({
                      'titulo': 'Desafio',
                      'descricao': question,
                      'nivelDificuldade': 'MEDIA',
                      'tipoResposta': apiResponseType,
                      'tags': '',
                      'paraTodasTutorandas': true,
                    }).then((_) {
                      _loadApiChallenges();
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao criar desafio: $e')),
                      );
                    });

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _showStatistics() {
    int daysWithChallenges = DateTime.now().difference(_firstChallengeDate).inDays + 1;
    double successRate = _totalAttempts > 0 ? (_correctAnswers / _totalAttempts * 100) : 0;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Estatísticas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 20),
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.purple[400]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Menina Digitais',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nível ${((_totalPoints ~/ 50) + 1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(context,'Concluídos', _totalAttempts.toString(), Icons.check_circle, Colors.blue),
                    _buildStatCard(context,'Corretos', _correctAnswers.toString(), Icons.thumb_up, Colors.green),
                    _buildStatCard(context,'Taxa de Acerto', '${successRate.toStringAsFixed(1)}%', Icons.trending_up, Colors.orange),
                    _buildStatCard(context,'Dias de Desafios', daysWithChallenges.toString(), Icons.calendar_today, Colors.red),
                  ],
                ),
                const SizedBox(height: 20),
                // Streak Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    border: Border.all(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🔥 Sequência',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Atual', style: TextStyle(fontSize: 12)),
                              Text(
                                _currentStreak.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Melhor', style: TextStyle(fontSize: 12)),
                              Text(
                                _bestStreak.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Points Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '⭐ Pontos Totais',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _totalPoints.toString(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Achievements
                _buildAchievements(successRate),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color,) {
    final width = MediaQuery.of(context).size.width;

    const baseWidth = 400.0;
    double scale = width / baseWidth;
    if (scale < 0.7) scale = 0.7;
    if (scale > 1.2) scale = 1.2;

    final iconSize = 32.0 * scale;
    final valueFontSize = 20.0 * scale;
    final labelFontSize = 11.0 * scale;
    final verticalSpacing = 8.0 * scale;
    final cardPadding = 12.0 * scale;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: verticalSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: verticalSpacing / 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: labelFontSize,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(double successRate) {
    final achievements = <String, bool>{
      '🥇 Primeira vitória': _correctAnswers >= 1,
      '🔥 Sequência de 3': _bestStreak >= 3,
      '💯 Perfeição': successRate == 100 && _totalAttempts > 0,
      '🌟 Superestrela': _totalPoints >= 50,
      '⚡ Rápido': _totalAttempts >= 5,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 Conquistas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements.entries.map((entry) {
            return Opacity(
              opacity: entry.value ? 1.0 : 0.3,
              child: Chip(
                label: Text(entry.key),
                backgroundColor: entry.value ? Colors.amber : Colors.grey[300],
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.value ? Colors.black : Colors.grey,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGlobalChallenges(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Desafios Globais',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Escolha a melhor resposta para cada desafio abaixo:',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: globalChallenges.length,
              itemBuilder: (context, index) {
                final challenge = globalChallenges[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Desafio ${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            if (GlobalState.userRole != 'Tutoranda')
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: 'Remover desafio',
                                onPressed: () => _confirmRemoveChallenge(index),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge['descricao'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        ...(challenge['opcoes'] as List<dynamic>? ?? []).map((option) {
                          return RadioListTile<String>(
                            value: option.toString(),
                            groupValue: _selectedAnswers[index],
                            title: Text(option.toString()),
                            activeColor: Colors.deepPurple,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) => _selectAnswer(index, value),
                          );
                        }),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _submitResponse(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: const Text('Enviar resposta', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (GlobalState.userRole == 'Tutoranda')
            ElevatedButton(
              onPressed: _showStatistics,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Ver minhas estatísticas',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTutorResponseWidget(int index) {
    final challenge = _apiChallenges[index];
    final responseType = challenge['tipoResposta'];

    if (responseType == 'TEXTO' || responseType == 'CODIGO') {
      return TextField(
        controller: _getTutorTextController(index),
        minLines: 3,
        maxLines: 6,
        decoration: const InputDecoration(
          labelText: 'Sua resposta',
          border: OutlineInputBorder(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => _selectTutorFile(index),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: const Text('Selecionar arquivo', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Text(
          _tutorFileNames[index] ?? 'Nenhum arquivo selecionado',
          style: TextStyle(
            color: _tutorFileNames[index] == null ? Colors.grey : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildTutorChallenges(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final challenges = _apiChallenges;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Desafios do Tutor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Responda os desafios abaixo usando múltipla escolha, texto ou arquivo.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              challenge['titulo'] ?? 'Desafio ${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge['descricao'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        _buildTutorResponseWidget(index),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _submitTutorResponse(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: const Text('Enviar resposta', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Desafios Globais'),
            if (GlobalState.userRole != 'admin')
              const Tab(text: 'Desafios do Tutor'),
          ],
        ),
      ),
      drawer: NavBar.buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalChallenges(context),
          if (GlobalState.userRole != 'admin')
            _buildTutorChallenges(context),
        ],
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  Widget? _getFloatingActionButton() {
    if (_selectedTabIndex == 0) {
      if (GlobalState.userRole != 'Tutoranda') {
        return FloatingActionButton(
          onPressed: _showAddChallengeDialog,
          child: const Icon(Icons.add),
          tooltip: 'Adicionar novo desafio',
        );
      }
    } else if (_selectedTabIndex == 1) {
      if (GlobalState.userRole == 'Tutor') {
        return FloatingActionButton(
          onPressed: _showAddTutorChallengeDialog,
          child: const Icon(Icons.add),
          tooltip: 'Adicionar desafio do tutor',
        );
      }
    }
    return null;
  }
}
