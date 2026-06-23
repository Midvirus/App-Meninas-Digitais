import 'package:flutter/material.dart';
import 'NavBar.dart';
import 'global_state.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

enum FeedbackResponseType { multipleChoice, text, file }

class ReceivedFeedback {
  final String challengeTitle;
  final String question;
  final DateTime feedbackDate;
  final FeedbackResponseType responseType;
  final String response;
  final double grade;
  final String feedbackText;

  const ReceivedFeedback({
    required this.challengeTitle,
    required this.question,
    required this.feedbackDate,
    required this.responseType,
    required this.response,
    required this.grade,
    required this.feedbackText,
  });
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.title});
  final String title;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Sample in-memory feedbacks (replace with real data later)
  final List<ReceivedFeedback> _feedbacks = [
    ReceivedFeedback(
      challengeTitle: 'Desafio 1',
      question: 'Qual destas opcoes e uma linguagem de programacao?',
      feedbackDate: DateTime.now().subtract(const Duration(hours: 2)),
      responseType: FeedbackResponseType.multipleChoice,
      response: 'Python',
      grade: 9.0,
      feedbackText:
          'Excelente! Python e de fato uma linguagem de programacao muito utilizada. Continue assim!',
    ),
    ReceivedFeedback(
      challengeTitle: 'Desafio 2',
      question:
          'Explique com detalhes o que e um botao de radio em um formulario e como ele se diferencia de um checkbox.',
      feedbackDate: DateTime.now().subtract(const Duration(days: 1)),
      responseType: FeedbackResponseType.text,
      response:
          'Um botao de radio e um elemento de interface grafica que permite ao usuario selecionar apenas uma opcao de um grupo de opcoes mutuamente exclusivas. Diferente do checkbox, que permite multiplas selecoes simultaneas, o botao de radio garante que apenas uma escolha seja feita por vez.',
      grade: 7.5,
      feedbackText:
          'Boa explicacao! Voce acertou o conceito principal. Para melhorar, poderia citar exemplos praticos de uso, como formularios de cadastro ou pesquisas de satisfacao. Na proxima tente aprofundar mais a comparacao com o checkbox, detalhando cenarios de uso de cada um.',
    ),
    ReceivedFeedback(
      challengeTitle: 'Desafio 3',
      question: 'Envie o nome de um arquivo que comprove sua atividade.',
      feedbackDate: DateTime.now().subtract(const Duration(hours: 6)),
      responseType: FeedbackResponseType.file,
      response: 'atividade_ana_entrega_final_revisada_v2.pdf',
      grade: 8.5,
      feedbackText:
          'Arquivo recebido com sucesso! A atividade foi bem executada. Alguns pontos podem ser melhorados na proxima entrega.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (GlobalState.userRole != 'Tutoranda') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  IconData _responseIcon(FeedbackResponseType t) {
    switch (t) {
      case FeedbackResponseType.multipleChoice:
        return Icons.radio_button_checked;
      case FeedbackResponseType.text:
        return Icons.text_snippet;
      case FeedbackResponseType.file:
        return Icons.attach_file;
    }
  }

  String _responseLabel(FeedbackResponseType t) {
    switch (t) {
      case FeedbackResponseType.multipleChoice:
        return 'Escolha';
      case FeedbackResponseType.text:
        return 'Texto';
      case FeedbackResponseType.file:
        return 'Arquivo';
    }
  }

  Color _gradeColor(double g) {
    if (g >= 7) return Colors.green;
    if (g >= 5) return Colors.orange;
    return Colors.red;
  }

  // ---------------------------------------------------------------------------
  // Detail dialog — full content, scrollable
  // ---------------------------------------------------------------------------

  void _openDetailDialog(ReceivedFeedback fb) {
    final gradeColor = _gradeColor(fb.grade);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding:
              const EdgeInsets.fromLTRB(20, 20, 20, 0),
          title: Row(
            children: [
              const Icon(Icons.feedback, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fb.challengeTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gradeColor),
                ),
                child: Text(
                  'Nota: ${fb.grade.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Feedback: ${_formatDate(fb.feedbackDate)}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Section: Enunciado
                    _sectionLabel('Enunciado', Icons.help_outline,
                        Colors.deepPurple),
                    const SizedBox(height: 6),
                    _contentBox(
                      color: Colors.deepPurple.withOpacity(0.06),
                      borderColor: Colors.deepPurple.withOpacity(0.2),
                      child: Text(fb.question,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    // Section: Resposta
                    _sectionLabel(
                        'Sua resposta (${_responseLabel(fb.responseType)})',
                        _responseIcon(fb.responseType),
                        Colors.blueGrey),
                    const SizedBox(height: 6),
                    _contentBox(
                      color: Colors.grey[100]!,
                      borderColor: Colors.grey.shade300,
                      child: fb.responseType == FeedbackResponseType.file
                          ? Row(
                              children: [
                                const Icon(Icons.insert_drive_file,
                                    size: 18, color: Colors.deepPurple),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(fb.response,
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 14)),
                                ),
                              ],
                            )
                          : Text(fb.response,
                              style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    // Section: Feedback
                    _sectionLabel(
                        'Feedback do Tutor', Icons.rate_review, Colors.deepPurple),
                    const SizedBox(height: 6),
                    _contentBox(
                      color: Colors.deepPurple.withOpacity(0.06),
                      borderColor: Colors.deepPurple.withOpacity(0.3),
                      child: Text(fb.feedbackText,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _contentBox(
      {required Color color,
      required Color borderColor,
      required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // Card (tappable, compact)
  // ---------------------------------------------------------------------------

  Widget _buildCard(ReceivedFeedback fb) {
    final gradeColor = _gradeColor(fb.grade);

    return InkWell(
      onTap: () => _openDetailDialog(fb),
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: title badge + grade badge + date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      fb.challengeTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gradeColor),
                    ),
                    child: Text(
                      'Nota: ${fb.grade.toStringAsFixed(1)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: gradeColor,
                          fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 6),
              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(fb.feedbackDate),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Question (truncated)
              Text(
                fb.question,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Response (truncated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_responseIcon(fb.responseType),
                            size: 13, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Sua resposta:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    fb.responseType == FeedbackResponseType.file
                        ? Row(
                            children: [
                              const Icon(Icons.insert_drive_file,
                                  size: 15, color: Colors.deepPurple),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  fb.response,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            fb.response,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Feedback (truncated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.rate_review,
                            size: 13, color: Colors.deepPurple),
                        SizedBox(width: 4),
                        Text(
                          'Feedback do Tutor:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fb.feedbackText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Tap hint
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum feedback recebido ainda.',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Quando seu Tutor corrigir um desafio,\nele aparecera aqui.',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: NavBar.buildDrawer(context),
      body: _feedbacks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _feedbacks.length,
              itemBuilder: (ctx, i) => _buildCard(_feedbacks[i]),
            ),
    );
  }
}
