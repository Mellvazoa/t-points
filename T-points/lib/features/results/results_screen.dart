/// Results screen — displays computed intervals for the active system.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:t_points/core/theme.dart';
import 'package:t_points/core/providers.dart';
import 'package:t_points/features/calculation/calculation_engine.dart';
import 'package:t_points/features/import_export/import_export_service.dart';
import 'package:t_points/shared/widgets.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4, height: 28,
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 12),
                    Text('Результаты', style: Theme.of(context).textTheme.headlineLarge),
                  ],
                ),
                if (systems.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      NeuButton(
                        color: AppColors.surfaceLight,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onPressed: () {
                          final resultsMap = <String, ComputationResult?>{};
                          for (final sys in systems) {
                            resultsMap[sys.id] = ref.read(computationResultProvider(sys.id));
                          }
                          ImportExportService.exportCsv(systems, resultsMap);
                        },
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.download_rounded, size: 16), SizedBox(width: 6), Text('CSV всех систем', style: TextStyle(fontSize: 12)),
                        ]),
                      ),
                      NeuButton(
                        color: AppColors.surfaceLight,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        onPressed: () {
                          final resultsMap = <String, ComputationResult?>{};
                          for (final sys in systems) {
                            resultsMap[sys.id] = ref.read(computationResultProvider(sys.id));
                          }
                          ImportExportService.exportExcel(systems, resultsMap);
                        },
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.download_rounded, size: 16), SizedBox(width: 6), Text('Excel всех систем', style: TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),
              ],
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
                          color: isActive ? AppColors.secondary.withAlpha(50) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? AppColors.secondary : AppColors.surfaceLight),
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

            if (result == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined, size: 64, color: AppColors.textMuted.withAlpha(80)),
                      const SizedBox(height: 16),
                      Text(
                        'Введите минимум 2 пары в выбранной системе',
                        style: TextStyle(color: AppColors.textMuted.withAlpha(120), fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GlobalBoundsCard(result: result),
                      const SizedBox(height: 24),
                      _SBoundsCard(result: result),
                      const SizedBox(height: 24),
                      if (result.pairIntervals.isNotEmpty) ...[
                        Text('Интервалы по парам', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...result.pairIntervals.asMap().entries.map(
                              (entry) => _PairIntervalCard(index: entry.key, interval: entry.value),
                            ),
                      ],
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

class _GlobalBoundsCard extends StatelessWidget {
  final dynamic result;
  const _GlobalBoundsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final gb = result.globalBounds;
    return NeuContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.hub_rounded, color: AppColors.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Text('Глобальные границы', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const GlowDivider(),
          if (gb != null) ...[
            _IntervalRow(label: 's', min: gb.sMin.toStringAsFixed(4), max: gb.sMax.toStringAsFixed(4), color: AppColors.primary),
            const SizedBox(height: 10),
            _IntervalRow(label: 'm', min: gb.mMin.toStringAsFixed(4), max: gb.mMax.toStringAsFixed(4), color: AppColors.secondary),
          ] else
            const Text('Подходящий интервал не найден — проверьте данные.', style: TextStyle(color: AppColors.warning, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SBoundsCard extends StatelessWidget {
  final dynamic result;
  const _SBoundsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final sb = result.sBounds;
    return NeuContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.secondary.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.straighten_rounded, color: AppColors.secondaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Text('Границы s (по парам)', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const GlowDivider(),
          Text(sb.toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _IntervalRow extends StatelessWidget {
  final String label;
  final String min;
  final String max;
  final Color color;
  const _IntervalRow({required this.label, required this.min, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(60), width: 1),
          ),
          child: Center(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14, fontStyle: FontStyle.italic))),
        ),
        const SizedBox(width: 14),
        Text('∈  [ $min,  $max ]', style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PairIntervalCard extends StatelessWidget {
  final int index;
  final dynamic interval;
  const _PairIntervalCard({required this.index, required this.interval});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(160),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('${index + 1}', style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 13))),
          ),
          const SizedBox(width: 14),
          Text('b=${interval.pair.b}  T=${interval.pair.t}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'monospace')),
          const SizedBox(width: 24),
          Expanded(child: Text('s: ${interval.sIntervalStr}   m: ${interval.mIntervalStr}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}
