/// Main shell — sidebar navigation with neumorphic design.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:t_points/core/theme.dart';
import 'package:t_points/core/providers.dart';
import 'package:t_points/shared/widgets.dart';
import 'package:t_points/features/data_entry/data_entry_screen.dart';
import 'package:t_points/features/results/results_screen.dart';
import 'package:t_points/features/visualization/visualization_screen.dart';
import 'package:t_points/features/sessions/sessions_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final systems = ref.watch(systemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ─── Sidebar ──────────────────────────────────────────
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                right: BorderSide(
                  color: AppColors.surfaceLight,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo
                _Logo(),
                const SizedBox(height: 8),
                const GlowDivider(),
                const SizedBox(height: 8),

                // Navigation items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      NeuIconButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Ввод данных',
                        isSelected: selectedTab == 0,
                        onTap: () => ref
                            .read(selectedTabProvider.notifier)
                            .state = 0,
                      ),
                      NeuIconButton(
                        icon: Icons.analytics_rounded,
                        label: 'Результаты',
                        isSelected: selectedTab == 1,
                        onTap: () => ref
                            .read(selectedTabProvider.notifier)
                            .state = 1,
                      ),
                      NeuIconButton(
                        icon: Icons.show_chart_rounded,
                        label: 'Визуализация',
                        isSelected: selectedTab == 2,
                        onTap: () => ref
                            .read(selectedTabProvider.notifier)
                            .state = 2,
                      ),
                      NeuIconButton(
                        icon: Icons.folder_rounded,
                        label: 'Сессии',
                        isSelected: selectedTab == 3,
                        onTap: () => ref
                            .read(selectedTabProvider.notifier)
                            .state = 3,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Status indicator
                if (systems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withAlpha(100),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Системы активны',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${systems.length} систем загружено',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ─── Content ──────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildScreen(selectedTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DataEntryScreen(key: ValueKey('data'));
      case 1:
        return const ResultsScreen(key: ValueKey('results'));
      case 2:
        return const VisualizationScreen(key: ValueKey('viz'));
      case 3:
        return const SessionsScreen(key: ValueKey('sessions'));
      default:
        return const DataEntryScreen(key: ValueKey('data'));
    }
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'T',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'T-points',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Калькулятор баллов',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
