import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'NavBar.dart';
import 'global_state.dart';
import 'api_client.dart';

class ProjectDataPage extends StatefulWidget {
  const ProjectDataPage({super.key, required this.title});
  final String title;

  @override
  State<ProjectDataPage> createState() => _ProjectDataPageState();
}

class _ProjectDataPageState extends State<ProjectDataPage> {
  // ── State variables ─────────────────────────────────────────────────────────────
  bool _isLoading = true;

  int totalParticipants = 0;
  int totalTutors = 0;
  int totalTutorandas = 0;

  int totalChallenges = 0;
  int openChallenges = 0;
  int closedChallenges = 0;

  int totalPublications = 0;
  int publicationsThisMonth = 0;
  int publicationsWithLikes = 0;
  int avgLikes = 0;
  int categories = 0;

  int totalResponses = 0;
  int sentResponses = 0;

  int totalFeedbacks = 0;
  int givenFeedbacks = 0;

  int get pendingResponses => totalResponses - sentResponses;
  int get pendingFeedbacks => totalFeedbacks - givenFeedbacks;
  double get responseRate => totalResponses > 0 ? sentResponses / totalResponses : 0.0;
  double get feedbackRate => totalFeedbacks > 0 ? givenFeedbacks / totalFeedbacks : 0.0;

  @override
  void initState() {
    super.initState();
    if (GlobalState.userRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiClient.indicadores();
      if (mounted) {
        setState(() {
          totalParticipants = data['totalParticipants'] ?? 0;
          totalTutors = data['totalTutors'] ?? 0;
          totalTutorandas = data['totalTutorandas'] ?? 0;
          totalChallenges = data['totalChallenges'] ?? 0;
          openChallenges = data['openChallenges'] ?? 0;
          closedChallenges = data['closedChallenges'] ?? 0;
          totalPublications = data['totalPublications'] ?? 0;
          publicationsThisMonth = data['publicationsThisMonth'] ?? 0;
          publicationsWithLikes = data['publicationsWithLikes'] ?? 0;
          avgLikes = data['avgLikes'] ?? 0;
          categories = data['categories'] ?? 0;
          totalResponses = data['totalResponses'] ?? 0;
          sentResponses = data['sentResponses'] ?? 0;
          totalFeedbacks = data['totalFeedbacks'] ?? 0;
          givenFeedbacks = data['givenFeedbacks'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ── Palette ─────────────────────────────────────────────────────────────────
  static const Color _purple = Color(0xFF6C3FC5);
  static const Color _purpleLight = Color(0xFFEDE7F6);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _greenLight = Color(0xFFE8F5E9);
  static const Color _orange = Color(0xFFE65100);
  static const Color _orangeLight = Color(0xFFFFF3E0);
  static const Color _blue = Color(0xFF1565C0);
  static const Color _blueLight = Color(0xFFE3F2FD);
  static const Color _red = Color(0xFFC62828);
  static const Color _redLight = Color(0xFFFFEBEE);
  static const Color _violet = Color(0xFF7B1FA2);
  static const Color _violetLight = Color(0xFFF3E5F5);

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
                color: _purple, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _purple),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a grid of stat cards that adapts:
  /// width < 360 → 1 column, width < 540 → 2 columns, else → 3 columns
  Widget _statCardGrid(List<_StatCardData> items) {
    return LayoutBuilder(builder: (context, constraints) {
      final int cols = constraints.maxWidth < 360
          ? 1
          : constraints.maxWidth < 540
              ? 2
              : 3;
      final double spacing = 10;
      final double cellW =
          (constraints.maxWidth - spacing * (cols - 1)) / cols;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items
            .map((d) => SizedBox(width: cellW, child: _statCard(d)))
            .toList(),
      );
    });
  }

  Widget _statCard(_StatCardData d) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: d.bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: d.color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: d.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(d.icon, color: d.color, size: 20),
                ),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(d.value,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: d.color)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(d.label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            if (d.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(d.subtitle!,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _progressCard({
    required String label,
    required int done,
    required int total,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String doneLabel,
    required String pendingLabel,
  }) {
    final double pct = total > 0 ? done / total : 0;
    final int pending = total - done;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                ),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 9,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _pill(doneLabel, '$done', _green, _greenLight),
                _pill(pendingLabel, '$pending', _red, _redLight),
                Text('Total: $total',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 11,
            height: 11,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ── Quick metrics 2×2 grid ──────────────────────────────────────────────────
  Widget _quickMetrics2x2(List<_MetricData> items) {
    return LayoutBuilder(builder: (context, constraints) {
      final double spacing = 8;
      final int cols = constraints.maxWidth < 280 ? 1 : 2;
      final double cellW =
          (constraints.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items
            .map((d) => SizedBox(width: cellW, child: _quickMetricCell(d)))
            .toList(),
      );
    });
  }

  Widget _quickMetricCell(_MetricData d) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: d.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(d.icon, color: d.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(d.value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: d.color)),
                ),
                Text(d.label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Donut chart ──────────────────────────────────────────────────────────────
  Widget _participantsDonut() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Composição de Participantes',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, constraints) {
              final bool narrow = constraints.maxWidth < 300;
              final double chartSize = narrow ? 120 : 150;

              return Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: chartSize * 0.22,
                        sections: [
                          PieChartSectionData(
                            value: totalTutors.toDouble(),
                            color: _purple,
                            title: '$totalTutors',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            radius: chartSize * 0.33,
                          ),
                          PieChartSectionData(
                            value: totalTutorandas.toDouble(),
                            color: const Color(0xFFBA68C8),
                            title: '$totalTutorandas',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                            radius: chartSize * 0.33,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendItem('Tutores ($totalTutors)', _purple),
                      const SizedBox(height: 8),
                      _legendItem(
                          'Tutorandas ($totalTutorandas)',
                          const Color(0xFFBA68C8)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _purpleLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Total  ',
                                style: TextStyle(
                                    fontSize: 12, color: _purple)),
                            Text('$totalParticipants',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _purple)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Bar chart ────────────────────────────────────────────────────────────────
  Widget _challengesBar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Desafios — Visao Geral',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: totalChallenges.toDouble() * 1.25,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(fontSize: 10);
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Total', style: style);
                            case 1:
                              return const Text('Abertos', style: style);
                            case 2:
                              return const Text('Encerr.', style: style);
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                          toY: totalChallenges.toDouble(),
                          color: _purple,
                          width: 22,
                          borderRadius: BorderRadius.circular(5)),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                          toY: openChallenges.toDouble(),
                          color: _orange,
                          width: 22,
                          borderRadius: BorderRadius.circular(5)),
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(
                          toY: closedChallenges.toDouble(),
                          color: _green,
                          width: 22,
                          borderRadius: BorderRadius.circular(5)),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _legendItem('Total ($totalChallenges)', _purple),
                _legendItem('Abertos ($openChallenges)', _orange),
                _legendItem('Encerr. ($closedChallenges)', _green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        drawer: NavBar.buildDrawer(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: NavBar.buildDrawer(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        children: [
          // ── Participantes ──────────────────────────────────────────────────
          _sectionTitle('Participantes'),
          _statCardGrid([
            _StatCardData(
              label: 'Total de Participantes',
              value: '$totalParticipants',
              icon: Icons.group,
              color: _purple,
              bgColor: _purpleLight,
            ),
            _StatCardData(
              label: 'Tutores',
              value: '$totalTutors',
              icon: Icons.school,
              color: _blue,
              bgColor: _blueLight,
            ),
            _StatCardData(
              label: 'Tutorandas',
              value: '$totalTutorandas',
              icon: Icons.person,
              color: _violet,
              bgColor: _violetLight,
            ),
          ]),
          const SizedBox(height: 12),
          _participantsDonut(),

          // ── Desafios ───────────────────────────────────────────────────────
          _sectionTitle('Desafios'),
          _statCardGrid([
            _StatCardData(
              label: 'Total Publicados',
              value: '$totalChallenges',
              icon: Icons.quiz,
              color: _purple,
              bgColor: _purpleLight,
            ),
            _StatCardData(
              label: 'Desafios Abertos',
              value: '$openChallenges',
              icon: Icons.lock_open,
              color: _orange,
              bgColor: _orangeLight,
            ),
            _StatCardData(
              label: 'Encerrados',
              value: '$closedChallenges',
              icon: Icons.lock,
              color: _green,
              bgColor: _greenLight,
            ),
          ]),
          const SizedBox(height: 12),
          _challengesBar(),

          // ── Mural ──────────────────────────────────────────────────────────
          _sectionTitle('Mural de Publicações'),
          _statCard(_StatCardData(
            label: 'Total de Publicaões no Mural',
            value: '$totalPublications',
            icon: Icons.push_pin,
            color: _blue,
            bgColor: _blueLight,
            subtitle: 'Posts publicados por tutores e admin',
          )),
          const SizedBox(height: 10),
          _quickMetrics2x2([
            _MetricData('Publicações/mês', '$publicationsThisMonth',
                Icons.today, _purple),
            _MetricData('Com curtidas', '$publicationsWithLikes',
                Icons.favorite, _red),
            _MetricData(
                'Media de curtidas', '$avgLikes', Icons.thumb_up, _blue),
            _MetricData(
                'Categorias', '$categories', Icons.category, _green),
          ]),

          // ── Respostas ──────────────────────────────────────────────────────
          _sectionTitle('Respostas dos Desafios'),
          _progressCard(
            label: 'Respostas Enviadas',
            done: sentResponses,
            total: totalResponses,
            color: _green,
            bgColor: _greenLight,
            icon: Icons.check_circle_outline,
            doneLabel: 'Enviadas',
            pendingLabel: 'Pendentes',
          ),
          const SizedBox(height: 8),
          _statCardGrid([
            _StatCardData(
              label: 'Respostas Enviadas',
              value: '$sentResponses',
              icon: Icons.send,
              color: _green,
              bgColor: _greenLight,
            ),
            _StatCardData(
              label: 'Respostas Pendentes',
              value: '$pendingResponses',
              icon: Icons.hourglass_empty,
              color: _red,
              bgColor: _redLight,
            ),
          ]),

          // ── Feedbacks ──────────────────────────────────────────────────────
          _sectionTitle('Feedbacks'),
          _progressCard(
            label: 'Feedbacks Dados',
            done: givenFeedbacks,
            total: totalFeedbacks,
            color: _purple,
            bgColor: _purpleLight,
            icon: Icons.rate_review,
            doneLabel: 'Dados',
            pendingLabel: 'A dar',
          ),
          const SizedBox(height: 8),
          _statCardGrid([
            _StatCardData(
              label: 'Feedbacks Dados',
              value: '$givenFeedbacks',
              icon: Icons.rate_review,
              color: _purple,
              bgColor: _purpleLight,
            ),
            _StatCardData(
              label: 'Feedbacks Pendentes',
              value: '$pendingFeedbacks',
              icon: Icons.pending,
              color: _red,
              bgColor: _redLight,
            ),
          ]),

          // ── Engajamento ────────────────────────────────────────────────────
          _sectionTitle('Engajamento Geral'),
          _quickMetrics2x2([
            _MetricData(
                'Taxa de Resposta',
                '${(responseRate * 100).toStringAsFixed(0)}%',
                Icons.bar_chart,
                _green),
            _MetricData(
                'Taxa de Feedback',
                '${(feedbackRate * 100).toStringAsFixed(0)}%',
                Icons.feedback,
                _purple),
            _MetricData(
                'Media de Nota', '7.8', Icons.star, _orange),
            _MetricData(
                'Dias Ativos', '42', Icons.calendar_month, _blue),
          ]),
        ],
      ),
    );
  }
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? subtitle;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.subtitle,
  });
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricData(this.label, this.value, this.icon, this.color);
}
