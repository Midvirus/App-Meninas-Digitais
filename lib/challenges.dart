import 'package:flutter/material.dart';
import 'NavBar.dart';

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
  ];

  final Map<int, String> _selectedAnswers = {};

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Resposta Correta' : 'Resposta Incorreta'),
        content: Text(
          isCorrect
              ? 'Muito bem! ${challenge.justification}'
              : 'A resposta correta é "${challenge.correctAnswer}". ${challenge.justification}',
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

  void _showSummary() {
    final answers = _challenges.asMap().entries.map((entry) {
      final index = entry.key;
      final challenge = entry.value;
      final answer = _selectedAnswers[index] ?? 'Sem resposta';
      return '${index + 1}. ${challenge.question}\nResposta: $answer';
    }).join('\n\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suas respostas'),
        content: SingleChildScrollView(child: Text(answers)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
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
              onPressed: _showSummary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Ver minhas respostas',
                style: TextStyle(fontSize: 16, color: Colors.white),
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}
