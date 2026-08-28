/// Sessions screen — save/load/delete sessions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:t_points/core/theme.dart';
import 'package:t_points/core/providers.dart';
import 'package:t_points/shared/widgets.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen>
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

  void _showSaveDialog() {
    final controller = TextEditingController(
      text:
          'Сессия ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Сохранить сессию',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Название сессии',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(sessionsProvider.notifier)
                  .saveCurrentSession(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final systems = ref.watch(systemsProvider);
    final activeSessionId = ref.watch(activeSessionIdProvider);

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
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Сессии',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const Spacer(),
                if (systems.isNotEmpty) ...[
                  NeuButton(
                    onPressed: _showSaveDialog,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Сохранить текущую'),
                      ],
                    ),
                  ),
                  if (activeSessionId != null) ...[
                    const SizedBox(width: 8),
                    NeuButton(
                      color: AppColors.surfaceLight,
                      onPressed: () {
                        ref
                            .read(sessionsProvider.notifier)
                            .updateSession(activeSessionId);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.update_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Обновить'),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              size: 64,
                              color: AppColors.textMuted.withAlpha(80)),
                          const SizedBox(height: 16),
                          Text(
                            'Нет сохранённых сессий',
                            style: TextStyle(
                              color: AppColors.textMuted.withAlpha(120),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Введите данные и сохраните текущую сессию',
                            style: TextStyle(
                              color: AppColors.textMuted.withAlpha(80),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isActive = session.id == activeSessionId;
                        return _SessionTile(
                          session: session,
                          isActive: isActive,
                          onLoad: () {
                            ref
                                .read(sessionsProvider.notifier)
                                .loadSession(session);
                            ref.read(selectedTabProvider.notifier).state = 0;
                          },
                          onDelete: () {
                            ref
                                .read(sessionsProvider.notifier)
                                .deleteSession(session.id);
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
}

class _SessionTile extends StatefulWidget {
  final dynamic session;
  final bool isActive;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(20),
        decoration: widget.isActive
            ? NeuDecoration.pressed(radius: 16)
            : _isHovered
                ? NeuDecoration.flat(
                    color: AppColors.surface.withAlpha(200), radius: 16)
                : BoxDecoration(
                    color: AppColors.surface.withAlpha(100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.surfaceLight.withAlpha(40)),
                  ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? AppColors.primary.withAlpha(40)
                    : AppColors.surfaceLight.withAlpha(60),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  widget.isActive
                      ? Icons.folder_rounded
                      : Icons.folder_outlined,
                  color: widget.isActive
                      ? AppColors.primaryLight
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.session.name,
                    style: TextStyle(
                      color: widget.isActive
                          ? AppColors.primaryLight
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.session.systems.length} систем  •  '
                    '${dateFormat.format(widget.session.updatedAt)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 1.0 : 0.3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded,
                        color: AppColors.success, size: 20),
                    tooltip: 'Загрузить',
                    onPressed: widget.onLoad,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                    tooltip: 'Удалить',
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
