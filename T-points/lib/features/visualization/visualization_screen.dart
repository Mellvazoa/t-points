/// Visualization screen — L/U curves in (s, m) axes.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:t_points/core/theme.dart';
import 'package:t_points/core/providers.dart';
import 'package:t_points/features/calculation/calculation_engine.dart';
import 'package:t_points/features/sessions/session_model.dart';
import 'package:t_points/shared/widgets.dart';

class VisualizationScreen extends ConsumerStatefulWidget {
  const VisualizationScreen({super.key});

  @override
  ConsumerState<VisualizationScreen> createState() =>
      _VisualizationScreenState();
}

class _VisualizationScreenState extends ConsumerState<VisualizationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSysId = ref.watch(activeSystemIdProvider);
    final systems = ref.watch(systemsProvider);
    final activeSystem = activeSysId != null
        ? systems.cast<ScoreSystem?>().firstWhere(
            (s) => s!.id == activeSysId,
            orElse: () => null,
          )
        : null;
    
    final result = activeSysId != null 
        ? ref.watch(computationResultProvider(activeSysId))
        : null;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.chartUpper,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Визуализация',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Кривые L(s) и U(s) — допустимая область (s, m)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // System Selector
            if (systems.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: systems.length,
                  itemBuilder: (context, index) {
                    final sys = systems[index];
                    final isActive = sys.id == activeSysId;
                    return GestureDetector(
                      onTap: () => ref.read(activeSystemIdProvider.notifier).state = sys.id,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.chartUpper.withAlpha(50) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? AppColors.chartUpper : AppColors.surfaceLight),
                        ),
                        child: Center(
                          child: Text(
                            sys.name,
                            style: TextStyle(
                              color: isActive ? AppColors.secondaryLight : AppColors.textSecondary,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),

            if (result == null ||
                result.lowerCurve.isEmpty ||
                result.upperCurve.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart_rounded,
                          size: 64,
                          color: AppColors.textMuted.withAlpha(80)),
                      const SizedBox(height: 16),
                      Text(
                        'Недостаточно данных для графика',
                        style: TextStyle(
                          color: AppColors.textMuted.withAlpha(120),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Legend
                    _ChartLegend(),
                    const SizedBox(height: 16),
                    // Chart
                    Expanded(
                      child: NeuContainer(
                        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                        child: _buildChart(result, activeSystem?.pairs ?? []),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Info
                    if (result.globalBounds != null)
                      _BoundsInfo(result: result),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ComputationResult result, List<ScorePair> pairs) {
    final lowerSpots = result.lowerCurve
        .map<FlSpot>((p) => FlSpot(p.s, p.m))
        .toList();
    final upperSpots = result.upperCurve
        .map<FlSpot>((p) => FlSpot(p.s, p.m))
        .toList();

    if (lowerSpots.isEmpty || upperSpots.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    // Calculate axis bounds
    double minS = double.infinity, maxS = double.negativeInfinity;
    double minM = double.infinity, maxM = double.negativeInfinity;

    for (final spot in [...lowerSpots, ...upperSpots]) {
      if (spot.x < minS) minS = spot.x;
      if (spot.x > maxS) maxS = spot.x;
      if (spot.y.isFinite) {
        if (spot.y < minM) minM = spot.y;
        if (spot.y > maxM) maxM = spot.y;
      }
    }

    // Add padding
    final sRange = maxS - minS;
    final mRange = maxM - minM;
    minS -= sRange * 0.05;
    maxS += sRange * 0.05;
    minM -= mRange * 0.1;
    maxM += mRange * 0.1;

    final gb = result.globalBounds;
    final hasBounds = gb != null;

    double getL(double s) {
      double maxL = double.negativeInfinity;
      for (final pair in pairs) {
        final l = pair.b - s * (pair.t - 49) / 10;
        if (l > maxL) maxL = l;
      }
      return maxL;
    }

    double getU(double s) {
      double minU = double.infinity;
      for (final pair in pairs) {
        final u = pair.b - s * (pair.t - 50) / 10;
        if (u < minU) minU = u;
      }
      return minU;
    }

    final filledLowerSpots = <FlSpot>[];
    final filledUpperSpots = <FlSpot>[];

    if (hasBounds) {
      // 1. Add the exact start point at gb.sMin
      filledLowerSpots.add(FlSpot(gb.sMin, getL(gb.sMin)));
      filledUpperSpots.add(FlSpot(gb.sMin, getU(gb.sMin)));

      // 2. Add all intermediate points strictly between gb.sMin and gb.sMax
      filledLowerSpots.addAll(
        lowerSpots.where((s) => s.y.isFinite && s.x > gb.sMin && s.x < gb.sMax),
      );
      filledUpperSpots.addAll(
        upperSpots.where((s) => s.y.isFinite && s.x > gb.sMin && s.x < gb.sMax),
      );

      // 3. Add the exact end point at gb.sMax
      filledLowerSpots.add(FlSpot(gb.sMax, getL(gb.sMax)));
      filledUpperSpots.add(FlSpot(gb.sMax, getU(gb.sMax)));
    }

    // Build the between area data
    final betweenData = <LineChartBarData>[];

    // Lower curve (L) -> index 0
    betweenData.add(
      LineChartBarData(
        spots: lowerSpots.where((FlSpot s) => s.y.isFinite).toList(),
        isCurved: true,
        curveSmoothness: 0.2,
        color: AppColors.chartLower,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    );

    // Upper curve (U) -> index 1
    betweenData.add(
      LineChartBarData(
        spots: upperSpots.where((FlSpot s) => s.y.isFinite).toList(),
        isCurved: true,
        curveSmoothness: 0.2,
        color: AppColors.chartUpper,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
    );

    if (hasBounds) {
      // Dummy Lower curve for filling -> index 2
      betweenData.add(
        LineChartBarData(
          spots: filledLowerSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );

      // Dummy Upper curve for filling -> index 3
      betweenData.add(
        LineChartBarData(
          spots: filledUpperSpots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    // Area between curves
    final betweenAreas = <BetweenBarsData>[
      if (hasBounds)
        BetweenBarsData(
          fromIndex: 2,
          toIndex: 3,
          color: AppColors.chartFill,
        ),
    ];

    return LineChart(
      LineChartData(
        minX: minS,
        maxX: maxS,
        minY: minM,
        maxY: maxM,
        lineBarsData: betweenData,
        betweenBarsData: betweenAreas,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: mRange > 0 ? mRange / 5 : 1,
          verticalInterval: sRange > 0 ? sRange / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.chartGrid.withAlpha(80),
              strokeWidth: 0.5,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.chartGrid.withAlpha(80),
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              's',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: sRange > 0 ? sRange / 5 : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text(
              'm',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: mRange > 0 ? mRange / 5 : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.chartGrid.withAlpha(60)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceDark.withAlpha(230),
            tooltipRoundedRadius: 12,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                if (spot.barIndex >= 2) return null;
                final isLower = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isLower ? "L" : "U"}(${spot.x.toStringAsFixed(2)}) = ${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: isLower
                        ? AppColors.chartLower
                        : AppColors.chartUpper,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

class _ChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: AppColors.chartLower,
          label: 'L(s) — нижняя граница m',
        ),
        _LegendItem(
          color: AppColors.chartUpper,
          label: 'U(s) — верхняя граница m',
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.chartFill,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Допустимая область',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _BoundsInfo extends StatelessWidget {
  final dynamic result;

  const _BoundsInfo({required this.result});

  @override
  Widget build(BuildContext context) {
    final gb = result.globalBounds;
    if (gb == null) return const SizedBox.shrink();

    return NeuContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(
            label: 's_min',
            value: gb.sMin.toStringAsFixed(4),
            color: AppColors.primary,
          ),
          _InfoChip(
            label: 's_max',
            value: gb.sMax.toStringAsFixed(4),
            color: AppColors.primaryLight,
          ),
          _InfoChip(
            label: 'm_min',
            value: gb.mMin.toStringAsFixed(4),
            color: AppColors.secondary,
          ),
          _InfoChip(
            label: 'm_max',
            value: gb.mMax.toStringAsFixed(4),
            color: AppColors.secondaryLight,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withAlpha(180),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
