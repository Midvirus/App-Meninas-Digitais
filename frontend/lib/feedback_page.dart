import 'package:flutter/material.dart';
import 'NavBar.dart';
import 'global_state.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum SubmissionType { multipleChoice, text, file }

class TutorSubmission {
  final String challengeTitle;
  final String question;
  final String tutorandaName;
  final DateTime submittedAt;
  final SubmissionType responseType;
  final String response;

  String? feedbackText;
  double? grade;
  bool reviewed;

  TutorSubmission({
    required this.challengeTitle,
    required this.question,
    required this.tutorandaName,
    required this.submittedAt,
    required this.responseType,
    required this.response,
    this.feedbackText,
    this.grade,
    this.reviewed = false,
  });
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, required this.title});
  final String title;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> _apiSubmissions = [];
  bool _isLoading = true;

  List<dynamic> get _pending =>
      _apiSubmissions.where((s) => s['feedback'] == null && _matchesSearch(s)).toList();
  List<dynamic> get _reviewed =>
      _apiSubmissions.where((s) => s['feedback'] != null && _matchesSearch(s)).toList();

  bool _matchesSearch(dynamic s) {
    if (_searchQuery.isEmpty) return true;
    final name = (s['tutoranda']?['nome'] ?? '').toString().toLowerCase();
    return name.contains(_searchQuery.toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    if (GlobalState.userRole != 'Tutor') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
    _tabController = TabController(length: 2, vsync: this);
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final challenges = await ApiClient.listChallengesForTutora();
      List<dynamic> allResponses = [];
      for (var challenge in challenges) {
        final responses = await ApiClient.respostasDoDesafio(challenge['id']);
        allResponses.addAll(responses);
      }
      if (mounted) {
        setState(() {
          _apiSubmissions = allResponses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar respostas: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  String _responseLabel(dynamic submission) {
    if (submission['arquivoPath'] != null || submission['linkExterno'] != null) return 'Arquivo';
    return 'Texto';
  }

  IconData _responseIcon(dynamic submission) {
    if (submission['arquivoPath'] != null || submission['linkExterno'] != null) return Icons.attach_file;
    return Icons.text_snippet;
  }

  // ---------------------------------------------------------------------------
  // Response widget (used inside dialogs)
  // ---------------------------------------------------------------------------

  Widget _responseContent(dynamic s) {
    final text = s['textoResposta'] ?? s['arquivoPath'] ?? s['linkExterno'] ?? '';
    if (s['arquivoPath'] != null || s['linkExterno'] != null) {
      return Row(
        children: [
          const Icon(Icons.insert_drive_file, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      );
    }
    return Text(text);
  }

  // ---------------------------------------------------------------------------
  // Detail dialog — pending (view full response + dar feedback)
  // ---------------------------------------------------------------------------

  void _openPendingDetailDialog(dynamic submission) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  submission['desafio']?['titulo'] ?? 'Desafio',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                    // Meta info
                    Row(
                      children: [
                        const Icon(Icons.person, size: 15, color: Colors.deepPurple),
                        const SizedBox(width: 4),
                        Text(submission['tutoranda']?['nome'] ?? 'Desconhecido',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple)),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(_formatDate(DateTime.tryParse(submission['enviadoEm'] ?? '') ?? DateTime.now()),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Question
                    const Text('Enunciado',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                      ),
                      child: Text(submission['desafio']?['descricao'] ?? '',
                          style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    // Response
                    Row(
                      children: [
                        Icon(_responseIcon(submission.responseType),
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Resposta (${_responseLabel(submission.responseType)})',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _responseContent(submission),
                    ),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text('Feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _openFeedbackDialog(submission);
              },
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Detail dialog — reviewed (view full response + feedback, read-only)
  // ---------------------------------------------------------------------------

  void _openReviewedDetailDialog(dynamic submission) {
    final status = submission['status'] ?? 'PENDENTE';
    final isAprovado = status == 'APROVADO';
    final gradeColor = isAprovado ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  submission['desafio']?['titulo'] ?? 'Desafio',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gradeColor),
                ),
                child: Text(
                  status,
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
                    // Meta info
                    Row(
                      children: [
                        const Icon(Icons.person, size: 15, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(submission['tutoranda']?['nome'] ?? 'Desconhecido',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green)),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(_formatDate(DateTime.tryParse(submission['enviadoEm'] ?? '') ?? DateTime.now()),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Question
                    const Text('Enunciado',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                      ),
                      child: Text(submission['desafio']?['descricao'] ?? '',
                          style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    // Response
                    Row(
                      children: [
                        Icon(_responseIcon(submission),
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Resposta (${_responseLabel(submission)})',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _responseContent(submission),
                    ),
                    const SizedBox(height: 16),
                    // Feedback
                    const Row(
                      children: [
                        Icon(Icons.rate_review, size: 14, color: Colors.deepPurple),
                        SizedBox(width: 4),
                        Text('Feedback do Tutor',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                      ),
                      child: Text(submission.feedbackText ?? '',
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (isAprovado && submission['destaqueSolicitado'] != true && submission['emDestaque'] != true)
              TextButton.icon(
                icon: const Icon(Icons.star, color: Colors.orange),
                label: const Text('Solicitar Destaque', style: TextStyle(color: Colors.orange)),
                onPressed: () {
                  _openSolicitarDestaqueDialog(submission);
                },
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _openSolicitarDestaqueDialog(dynamic submission) {
    final controller = TextEditingController();
    bool isSending = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDlgState) {
        return AlertDialog(
          title: const Text('Solicitar Destaque'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Escreva um comentário justificando o destaque para a tutoranda:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Excelente trabalho...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: isSending ? null : () async {
                final txt = controller.text.trim();
                if (txt.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Escreva um comentário.')));
                  return;
                }
                setDlgState(() => isSending = true);
                try {
                  await ApiClient.solicitarDestaqueResposta(submission['id'], txt);
                  if (mounted) {
                    Navigator.pop(ctx); // fecha modal de destaque
                    Navigator.pop(context); // fecha modal de detalhes
                    _loadSubmissions();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Destaque solicitado com sucesso!'), backgroundColor: Colors.green));
                  }
                } catch(e) {
                  setDlgState(() => isSending = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
                }
              },
              child: isSending 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Solicitar'),
            ),
          ],
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Feedback dialog
  // ---------------------------------------------------------------------------

  void _openFeedbackDialog(dynamic submission) {
    final feedbackController =
        TextEditingController(text: submission['feedback'] ?? '');
    bool isAprovado = (submission['status'] == 'APROVADO');
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.rate_review, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Feedback',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                maxWidth: 500,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(submission['desafio']?['titulo'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple)),
                          const SizedBox(height: 4),
                          Text(submission['desafio']?['descricao'] ?? '',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(_responseIcon(submission),
                                  size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  submission['textoResposta'] ?? submission['arquivoPath'] ?? submission['linkExterno'] ?? '',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Seu feedback',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Escreva seu comentario aqui...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Colors.deepPurple, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('Aprovar Resposta?',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Switch(
                          value: isAprovado,
                          activeColor: Colors.green,
                          onChanged: (v) {
                            setDlgState(() => isAprovado = v);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                icon: isSending 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, size: 18),
                label: const Text('Enviar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isSending ? null : () async {
                  final feedback = feedbackController.text.trim();
                  if (feedback.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Escreva um feedback antes de enviar.')));
                    return;
                  }
                  
                  setDlgState(() => isSending = true);
                  
                  try {
                    await ApiClient.feedbackResposta(
                      submission['id'],
                      feedback,
                      isAprovado,
                    );
                    
                    if (mounted) {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Feedback enviado para ${submission['tutoranda']?['nome']}!'),
                        backgroundColor: Colors.green,
                      ));
                      // Recarrega a lista de submissoes
                      _loadSubmissions();
                    }
                  } catch (e) {
                    setDlgState(() => isSending = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Erro ao enviar feedback: $e'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Compact pending card
  // ---------------------------------------------------------------------------

  Widget _buildPendingCard(dynamic s) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: badge + type + date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s['desafio']?['titulo'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_responseIcon(s),
                          size: 12, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(_responseLabel(s),
                          style: TextStyle(
                              fontSize: 11, color: Colors.orange[700])),
                    ],
                  ),
                ),
                const Spacer(),
                Text(_formatDate(DateTime.tryParse(s['enviadoEm'] ?? '') ?? DateTime.now()),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 10),
            // Question (truncated)
            Text(s['desafio']?['descricao'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            // Tutoranda name
            Row(
              children: [
                const Icon(Icons.person, size: 15, color: Colors.deepPurple),
                const SizedBox(width: 4),
                Text(s['tutoranda']?['nome'] ?? 'Desconhecido',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.deepPurple,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            // Response preview (truncated, max 2 lines)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      Icon(_responseIcon(s),
                          size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Resposta:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  (s['arquivoPath'] != null || s['linkExterno'] != null)
                      ? Row(
                          children: [
                            const Icon(Icons.insert_drive_file,
                                size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(s['textoResposta'] ?? s['arquivoPath'] ?? s['linkExterno'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic, fontSize: 13)),
                            ),
                          ],
                        )
                      : Text(
                          s['textoResposta'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Detalhes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openPendingDetailDialog(s),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.rate_review, size: 16),
                  label: const Text('Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openFeedbackDialog(s),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact reviewed card
  // ---------------------------------------------------------------------------

  Widget _buildReviewedCard(dynamic s) {
    final status = s['status'] ?? 'PENDENTE';
    final isAprovado = status == 'APROVADO';
    final gradeColor = isAprovado ? Colors.green : Colors.red;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s['desafio']?['titulo'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_responseIcon(s),
                          size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(_responseLabel(s),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gradeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gradeColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_formatDate(DateTime.tryParse(s['enviadoEm'] ?? '') ?? DateTime.now()),
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 10),
            // Question (truncated)
            Text(s['desafio']?['descricao'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            // Tutoranda
            Row(
              children: [
                const Icon(Icons.person, size: 15, color: Colors.green),
                const SizedBox(width: 4),
                Text(s['tutoranda']?['nome'] ?? 'Desconhecido',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.green,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            // Response preview (truncated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      Icon(_responseIcon(s),
                          size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Resposta:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  (s['arquivoPath'] != null || s['linkExterno'] != null)
                      ? Row(
                          children: [
                            const Icon(Icons.insert_drive_file,
                                size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(s['textoResposta'] ?? s['arquivoPath'] ?? s['linkExterno'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13)),
                            ),
                          ],
                        )
                      : Text(s['textoResposta'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Feedback preview (truncated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rate_review, size: 13, color: Colors.deepPurple),
                      SizedBox(width: 4),
                      Text('Feedback:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(s['feedbackTutora'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // View details button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Ver detalhes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _openReviewedDetailDialog(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions, size: 18),
                  const SizedBox(width: 6),
                  const Text('A Corrigir'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_pending.length.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 6),
                  const Text('Corrigidos'),
                  if (_reviewed.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_reviewed.length.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: NavBar.buildDrawer(context),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por nome da Tutoranda...',
                prefixIcon:
                    const Icon(Icons.search, color: Colors.deepPurple),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _pending.isEmpty
                    ? _buildEmptyState(
                        'Nenhuma resposta aguardando correcao.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _pending.length,
                        itemBuilder: (ctx, i) => _buildPendingCard(_pending[i]),
                      ),
                _reviewed.isEmpty
                    ? _buildEmptyState('Nenhuma questao corrigida ainda.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _reviewed.length,
                        itemBuilder: (ctx, i) => _buildReviewedCard(_reviewed[i]),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
