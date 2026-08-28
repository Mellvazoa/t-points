/// Reusable neumorphic UI components.
library;

import 'package:flutter/material.dart';
import 'package:t_points/core/theme.dart';

/// A neumorphic container with flat shadow effect.
class NeuContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final bool pressed;
  final double? width;
  final double? height;

  const NeuContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 20,
    this.color,
    this.pressed = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      decoration: pressed
          ? NeuDecoration.pressed(
              color: color ?? AppColors.surfaceDark, radius: radius)
          : NeuDecoration.flat(
              color: color ?? AppColors.surface, radius: radius),
      child: child,
    );
  }
}

/// A neumorphic button with press animation.
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final double? width;
  final double? height;

  const NeuButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.radius = 16,
    this.color,
    this.width,
    this.height,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: widget.width,
        height: widget.height,
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: _isPressed
            ? NeuDecoration.pressed(
                color: widget.color ?? AppColors.primary,
                radius: widget.radius,
              )
            : NeuDecoration.convex(
                color: widget.color ?? AppColors.primary,
                radius: widget.radius,
              ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// A neumorphic icon button for the sidebar.
class NeuIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NeuIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<NeuIconButton> createState() => _NeuIconButtonState();
}

class _NeuIconButtonState extends State<NeuIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: widget.isSelected
              ? NeuDecoration.pressed(radius: 16)
              : _isHovered
                  ? NeuDecoration.flat(
                      color: AppColors.surface.withAlpha(200), radius: 16)
                  : BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                widget.icon,
                color: widget.isSelected
                    ? AppColors.primaryLight
                    : _isHovered
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? AppColors.primaryLight
                      : _isHovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated glow divider.
class GlowDivider extends StatelessWidget {
  const GlowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primaryLight,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
