import 'package:flutter/material.dart';
import 'NavBar.dart';
import 'global_state.dart';
import 'api_client.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.title});
  final String title;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notificacoes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (GlobalState.userRole != 'Tutoranda') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      _loadNotificacoes();
    }
  }

  Future<void> _loadNotificacoes() async {
    setState(() => _isLoading = true);
    try {
      final notifs = await ApiClient.listarNotificacoes();
      setState(() {
        _notificacoes = notifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar notificações: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _responderDestaque(dynamic notificacao, bool aprovado) async {
    try {
      await ApiClient.responderDestaque(notificacao['referenciaId'], aprovado);
      await ApiClient.marcarNotificacaoLida(notificacao['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(aprovado ? 'Destaque autorizado!' : 'Destaque recusado!')),
        );
      }
      _loadNotificacoes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao responder solicitação: $e')),
        );
      }
    }
  }

  Future<void> _marcarLida(dynamic notificacao) async {
    try {
      await ApiClient.marcarNotificacaoLida(notificacao['id']);
      _loadNotificacoes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar como lida: $e')),
        );
      }
    }
  }

  Widget _buildNotificacaoCard(dynamic notificacao) {
    final bool isLida = notificacao['lida'] == true;
    final String tipo = notificacao['tipo'] ?? '';
    final String mensagem = notificacao['mensagem'] ?? '';
    final DateTime data = DateTime.tryParse(notificacao['criadoEm'] ?? '') ?? DateTime.now();

    final bool isHighlightRequest = tipo == 'SOLICITACAO_DESTAQUE';

    return Card(
      elevation: 2,
      color: isLida ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLida
            ? BorderSide.none
            : BorderSide(color: Colors.deepPurple.shade200, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHighlightRequest ? Icons.star : Icons.notifications,
                  color: isHighlightRequest ? Colors.orange : Colors.deepPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isHighlightRequest ? 'Solicitação de Destaque' : 'Aviso',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Text(
                  _formatDate(data),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mensagem,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            if (isHighlightRequest && !isLida) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _responderDestaque(notificacao, false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _responderDestaque(notificacao, true),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Autorizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else if (!isLida) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _marcarLida(notificacao),
                  child: const Text('Marcar como lida'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notificacoes.where((n) => n['lida'] == false).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Text(widget.title),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotificacoes,
          ),
        ],
      ),
      drawer: NavBar.buildDrawer(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificacoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Nenhuma notificação', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notificacoes.length,
                  itemBuilder: (context, index) {
                    return _buildNotificacaoCard(_notificacoes[index]);
                  },
                ),
    );
  }
}
