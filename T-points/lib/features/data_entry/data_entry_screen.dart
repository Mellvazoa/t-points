/// Data Entry screen — manual input and file import with Systems support.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:t_points/core/theme.dart';
import 'package:t_points/core/providers.dart';
import 'package:t_points/shared/widgets.dart';
import 'package:t_points/features/import_export/import_export_service.dart';

class DataEntryScreen extends ConsumerStatefulWidget {
  const DataEntryScreen({super.key});

  @override
  ConsumerState<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends ConsumerState<DataEntryScreen>
    with SingleTickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _systemNameController = TextEditingController();
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
    _inputController.dispose();
    _systemNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleSubmit(String activeSysId) {
    final error = ref.read(systemsProvider.notifier).parseAndAdd(
          _inputController.text,
          defaultSystemId: activeSysId,
        );
    ref.read(inputErrorProvider.notifier).state = error;
    if (error == null) {
      _inputController.clear();
    }
  }

  Future<void> _importCsv() async {
    try {
      final systems = await ImportExportService.importCsv();
      if (systems != null && systems.isNotEmpty) {
        ref.read(systemsProvider.notifier).setSystems(systems);
        ref.read(activeSystemIdProvider.notifier).state = systems.first.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные CSV успешно импортированы')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта CSV: $e')),
        );
      }
    }
  }

  Future<void> _importExcel() async {
    try {
      final systems = await ImportExportService.importExcel();
      if (systems != null && systems.isNotEmpty) {
        ref.read(systemsProvider.notifier).setSystems(systems);
        ref.read(activeSystemIdProvider.notifier).state = systems.first.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные Excel успешно импортированы')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта Excel: $e')),
        );
      }
    }
  }

  void _showAddSystemDialog() {
    _systemNameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Новая система', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: _systemNameController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Имя системы'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_systemNameController.text.trim().isNotEmpty) {
                ref.read(systemsProvider.notifier).addSystem(_systemNameController.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systems = ref.watch(systemsProvider);
    final activeSysId = ref.watch(activeSystemIdProvider);
    final error = ref.watch(inputErrorProvider);

    final activeSystem = systems.cast<dynamic>().firstWhere((s) => s.id == activeSysId, orElse: () => null);

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
                  width: 4, height: 28,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Text('Ввод данных', style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text('Выберите систему и добавьте пары. Формат: "b T" или "ИмяСистемы b T"', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            // Systems tabs
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
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
                              color: isActive ? AppColors.primary.withAlpha(50) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isActive ? AppColors.primary : AppColors.surfaceLight),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  sys.name,
                                  style: TextStyle(
                                    color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
                                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                                if (systems.length > 1) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(systemsProvider.notifier).removeSystem(sys.id);
                                      if (isActive) {
                                        final newSystems = ref.read(systemsProvider);
                                        ref.read(activeSystemIdProvider.notifier).state = newSystems.first.id;
                                      }
                                    },
                                    child: Icon(Icons.close_rounded, size: 16, color: AppColors.error.withAlpha(180)),
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  NeuButton(
                    padding: const EdgeInsets.all(12),
                    radius: 12,
                    color: AppColors.surfaceLight,
                    onPressed: _showAddSystemDialog,
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input area
            NeuContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _inputController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontFamily: 'monospace'),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Пример 1: 10 55 20 65\nПример 2: Система2 15 50 Система2 25 60',
                      errorText: error,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                        onPressed: () => _handleSubmit(activeSysId!),
                      ),
                    ),
                    onSubmitted: (_) => _handleSubmit(activeSysId!),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      NeuButton(
                        onPressed: () => _handleSubmit(activeSysId!),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_rounded, size: 18), SizedBox(width: 8), Text('Добавить'),
                        ]),
                      ),
                      NeuButton(
                        color: AppColors.surfaceLight,
                        onPressed: _importCsv,
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.upload_file_rounded, size: 18), SizedBox(width: 8), Text('Импорт CSV'),
                        ]),
                      ),
                      NeuButton(
                        color: AppColors.surfaceLight,
                        onPressed: _importExcel,
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.table_chart_rounded, size: 18), SizedBox(width: 8), Text('Импорт Excel'),
                        ]),
                      ),
                      if (activeSystem != null && activeSystem.pairs.isNotEmpty)
                        NeuButton(
                          color: AppColors.error.withAlpha(180),
                          onPressed: () {
                            ref.read(systemsProvider.notifier).clearSystem(activeSysId!);
                          },
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.delete_outline_rounded, size: 18), SizedBox(width: 8), Text('Очистить систему'),
                          ]),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pairs count indicator
            if (activeSystem != null && activeSystem.pairs.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withAlpha(80), width: 1),
                    ),
                    child: Text(
                      '${activeSystem.pairs.length} пар${_pluralSuffix(activeSystem.pairs.length)}',
                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  if (activeSystem.pairs.length < 2)
                    Text(
                      'Нужно минимум 2 пары для расчёта',
                      style: TextStyle(color: AppColors.warning.withAlpha(200), fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Pairs list
            Expanded(
              child: activeSystem == null || activeSystem.pairs.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.data_array_rounded, size: 48, color: AppColors.textMuted.withAlpha(80)),
                            const SizedBox(height: 12),
                            Text('Нет введённых пар', style: TextStyle(color: AppColors.textMuted.withAlpha(120), fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Введите пары b T через пробел выше', style: TextStyle(color: AppColors.textMuted.withAlpha(80), fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeSystem.pairs.length,
                      itemBuilder: (context, index) {
                        final pair = activeSystem.pairs[index];
                        return _PairTile(
                          index: index,
                          pair: pair,
                          onDelete: () {
                            ref.read(systemsProvider.notifier).removePair(activeSysId!, pair);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _pluralSuffix(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'а';
    return '';
  }
}

class _PairTile extends StatefulWidget {
  final int index;
  final dynamic pair;
  final VoidCallback onDelete;

  const _PairTile({required this.index, required this.pair, required this.onDelete});

  @override
  State<_PairTile> createState() => _PairTileState();
}

class _PairTileState extends State<_PairTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300 + (widget.index % 10) * 30));
    _slideAnim = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _controller,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: _isHovered
                ? NeuDecoration.flat(color: AppColors.surface.withAlpha(220), radius: 14)
                : BoxDecoration(
                    color: AppColors.surface.withAlpha(100),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceLight.withAlpha(60)),
                  ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.primary.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('${widget.index + 1}', style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w700, fontSize: 13))),
                ),
                const SizedBox(width: 16),
                RichText(text: TextSpan(children: [
                  const TextSpan(text: 'b = ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  TextSpan(text: '${widget.pair.b}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'monospace')),
                ])),
                const SizedBox(width: 24),
                RichText(text: TextSpan(children: [
                  const TextSpan(text: 'T = ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  TextSpan(text: '${widget.pair.t}', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'monospace')),
                ])),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                    onPressed: widget.onDelete,
                    splashRadius: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
