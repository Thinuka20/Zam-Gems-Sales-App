import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class Pie3DChart extends StatelessWidget {
  const Pie3DChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No of Bills - Outlet wise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CustomPaint(
                painter: Pie3DPainter(),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('BIG1 (28.7%)', Colors.blue),
                _buildLegendItem('BIG2 (33.3%)', Colors.red),
                _buildLegendItem('OUTLET POINT 2 (8.7%)', Colors.orange),
                _buildLegendItem('WINE AND DINE (8.7%)', Colors.green),
                _buildLegendItem('FAMILY (8.7%)', Colors.purple),
                _buildLegendItem('GRILL (11.9%)', Colors.lightGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class Pie3DPainter extends CustomPainter {
  final List<PieSection> sections = [
    PieSection(28.7, Colors.blue),
    PieSection(33.3, Colors.red),
    PieSection(8.7, Colors.orange),
    PieSection(8.7, Colors.green),
    PieSection(8.7, Colors.purple),
    PieSection(11.9, Colors.lightGreen),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final depthRect = Rect.fromCircle(
        center: center.translate(0, 20), radius: radius);

    double startAngle = -math.pi / 2;

    // Draw 3D effect (sides)
    for (var section in sections) {
      final sweepAngle = (section.percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = section.color.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.arcTo(rect, startAngle, sweepAngle, true);
      path.arcTo(depthRect, startAngle + sweepAngle, -sweepAngle, false);
      path.close();
      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }

    // Draw top of pie
    startAngle = -math.pi / 2;
    for (var section in sections) {
      final sweepAngle = (section.percentage / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw percentage text if segment is large enough
      if (section.percentage > 5) {
        final textAngle = startAngle + sweepAngle / 2;
        final x = center.dx + radius * 0.7 * math.cos(textAngle);
        final y = center.dy + radius * 0.7 * math.sin(textAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${section.percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieSection {
  final double percentage;
  final Color color;

  PieSection(this.percentage, this.color);
}

class DateWiseBarChart extends StatelessWidget {
  const DateWiseBarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No of Bills - Date wise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  minY: 0,
                  groupsSpace: 12,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 8,
                          color: Colors.purple,
                          width: 60,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 10,
                            color: Colors.grey[200],
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 4,
                          color: Colors.purple,
                          width: 60,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 10,
                            color: Colors.grey[200],
                          ),
                        ),
                      ],
                    ),
                  ],
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                      left: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final dates = ['01 Dec 24', '02 Dec 24'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dates[value.toInt()],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Bills: ${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
