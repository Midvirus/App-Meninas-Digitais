import 'package:flutter/material.dart';
import 'NavBar.dart';
import 'supabase_client.dart';

class Challenge {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String justification;

  Challenge({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.justification,
  });
}

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key, required this.title});
  final String title;

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final List<Challenge> _challenges = [
    Challenge(
      question: 'Qual destas opções é uma linguagem de programação?',
      options: ['Caneta', 'Python', 'Computador'],
      correctAnswer: 'Python',
      justification: 'Python é uma linguagem de programação usada para criar software.',
    ),
    Challenge(
      question: 'O que é um botão de rádio em um formulário?',
      options: ['Uma seleção única', 'Um campo de texto', 'Uma imagem'],
      correctAnswer: 'Uma seleção única',
      justification: 'Botões de rádio permitem escolher apenas uma opção dentre várias.',
    ),
    Challenge(
      question: 'Qual é a melhor prática ao usar radio buttons?',
      options: [
        'Permitir múltiplas respostas ao mesmo tempo',
        'Exigir que o usuário escolha apenas uma opção',
        'Não rotular as opções',
      ],
      correctAnswer: 'Exigir que o usuário escolha apenas uma opção',
      justification: 'Radio buttons são usados quando apenas uma resposta deve ser selecionada.',
    ),
    Challenge(
      question: 'Pergunta teste para verificar o funcionamento do sistema de desafios. Qual é a resposta correta?',
      options: [
        'A opção 2 está correta',
        'Metade das opções estão mentindo',
        'Essa é a opção correta',
        'A opção 1 é a resposta certa',
      ],
      correctAnswer: 'Essa é a opção correta',
      justification: 'É o que ela diz, o que mais você esperava?',
    ),
  ];

  final Map<int, String> _selectedAnswers = {};
  
  // Gamification tracking
  int _totalAttempts = 0;
  int _correctAnswers = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalPoints = 0;
  final DateTime _firstChallengeDate = DateTime.now();
  final Map<int, bool> _answeredCorrectly = {};

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      // Not authenticated, redirect to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
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

    final challenge = _challenges[index];
    final isCorrect = selected == challenge.correctAnswer;
    
    // Update statistics
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
                  ? 'Muito bem! ${challenge.justification}'
                  : 'A resposta correta é "${challenge.correctAnswer}". ${challenge.justification}',
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
                  'Estatísticas do Jogador',
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
                  children: [
                    _buildStatCard('Desafios Concluídos', _totalAttempts.toString(), Icons.check_circle, Colors.blue),
                    _buildStatCard('Respostas Corretas', _correctAnswers.toString(), Icons.thumb_up, Colors.green),
                    _buildStatCard('Taxa de Acerto', '${successRate.toStringAsFixed(1)}%', Icons.trending_up, Colors.orange),
                    _buildStatCard('Dias de Desafios', daysWithChallenges.toString(), Icons.calendar_today, Colors.red),
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
                              const Text('Sequência Atual', style: TextStyle(fontSize: 12)),
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
                              const Text('Melhor Sequência', style: TextStyle(fontSize: 12)),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: NavBar.buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Desafios com Radio Buttons',
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
                itemCount: _challenges.length,
                itemBuilder: (context, index) {
                  final challenge = _challenges[index];
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
                          Text(
                            'Desafio ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challenge.question,
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          ...challenge.options.map((option) {
                            return RadioListTile<String>(
                              value: option,
                              groupValue: _selectedAnswers[index],
                              title: Text(option),
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
      ),
    );
  }
}
