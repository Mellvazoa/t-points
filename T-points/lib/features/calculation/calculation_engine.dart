/// Mathematical engine for T-points calculation.
///
/// Implements the algorithm for finding valid intervals of (s, m)
/// given pairs of (b, T) where T = 50 + floor(10 * (b - m) / s).
library;

import 'dart:math' as math;

/// Represents a pair of raw score (b) and standardized score (T).
class ScorePair {
  final String systemId;
  final double b;
  final int t;

  const ScorePair({required this.systemId, required this.b, required this.t});

  @override
  String toString() => '(System=$systemId, b=$b, T=$t)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScorePair &&
          runtimeType == other.runtimeType &&
          systemId == other.systemId &&
          b == other.b &&
          t == other.t;

  @override
  int get hashCode => Object.hash(systemId, b, t);
}

/// Result of computing s-bounds for a single pair.
class SBoundsResult {
  final double? sMin;
  final double? sMax;

  const SBoundsResult({this.sMin, this.sMax});

  bool get isValid => sMin != null || sMax != null;
  bool get isFiniteInterval => sMin != null && sMax != null;

  @override
  String toString() {
    if (sMin != null && sMax != null) {
      return 's ∈ [$sMin, $sMax]';
    } else if (sMin != null) {
      return 's ∈ [$sMin, +∞)';
    } else if (sMax != null) {
      return 's ∈ (0, $sMax]';
    }
    return 'no valid s';
  }
}

/// Result of global s,m bounds computation.
class GlobalBoundsResult {
  final double sMin;
  final double sMax;
  final double mMin;
  final double mMax;

  const GlobalBoundsResult({
    required this.sMin,
    required this.sMax,
    required this.mMin,
    required this.mMax,
  });

  bool get isValid => sMin <= sMax && mMin <= mMax;

  @override
  String toString() =>
      's ∈ [${sMin.toStringAsFixed(4)}, ${sMax.toStringAsFixed(4)}], '
      'm ∈ [${mMin.toStringAsFixed(4)}, ${mMax.toStringAsFixed(4)}]';
}

/// A critical s-value where the bounds function changes behavior.
class CriticalPoint {
  final double s;
  final double lowerBound; // L(s) — нижняя граница m
  final double upperBound; // U(s) — верхняя граница m

  const CriticalPoint({
    required this.s,
    required this.lowerBound,
    required this.upperBound,
  });
}

/// Curve point for visualization.
class CurvePoint {
  final double s;
  final double m;

  const CurvePoint({required this.s, required this.m});
}

/// Full computation result with all data needed for display and visualization.
class ComputationResult {
  final SBoundsResult sBounds;
  final GlobalBoundsResult? globalBounds;
  final List<CurvePoint> lowerCurve; // L(s) curve
  final List<CurvePoint> upperCurve; // U(s) curve
  final List<CriticalPoint> criticalPoints;
  final List<PairInterval> pairIntervals;

  const ComputationResult({
    required this.sBounds,
    this.globalBounds,
    this.lowerCurve = const [],
    this.upperCurve = const [],
    this.criticalPoints = const [],
    this.pairIntervals = const [],
  });
}

/// Interval info for a single pair.
class PairInterval {
  final ScorePair pair;
  final double? sMin;
  final double? sMax;
  final double? mMin;
  final double? mMax;
  final String sIntervalStr;
  final String mIntervalStr;

  const PairInterval({
    required this.pair,
    this.sMin,
    this.sMax,
    this.mMin,
    this.mMax,
    required this.sIntervalStr,
    required this.mIntervalStr,
  });
}

/// The core calculation engine.
class CalculationEngine {
  /// Get s-bounds for a list of pairs.
  ///
  /// Returns (s_min, s_max) where s_min and s_max define the valid range of s.
  /// Translates the Python `get_s_bounds` function.
  static SBoundsResult getSBounds(List<ScorePair> pairs) {
    double sMin = 0.0;
    double sMax = double.infinity;

    for (int i = 0; i < pairs.length; i++) {
      for (int j = i + 1; j < pairs.length; j++) {
        final bi = pairs[i].b;
        final ti = pairs[i].t;
        final bj = pairs[j].b;
        final tj = pairs[j].t;

        // Numerator: 10 * (b_i - b_j)
        final num_ = 10 * (bi - bj);
        // Denominator: T_i - T_j + 1 (and T_i - T_j - 1)
        final den1 = (ti - tj + 1).toDouble();
        final den2 = (ti - tj - 1).toDouble();

        if (den1 != 0) {
          final ratio = num_ / den1;
          if (den1 > 0) {
            sMin = math.max(sMin, ratio);
          } else if (den1 < 0) {
            sMax = math.min(sMax, ratio);
          }
        }

        if (den2 != 0) {
          final ratio = num_ / den2;
          if (den2 > 0) {
            sMax = math.min(sMax, ratio);
          } else if (den2 < 0) {
            sMin = math.max(sMin, ratio);
          }
        }
      }
    }

    if (sMin >= sMax) return const SBoundsResult();

    return SBoundsResult(
      sMin: sMin > 0 ? sMin : null,
      sMax: sMax < double.infinity ? sMax : null,
    );
  }

  /// Get global s-bounds with m-bounds refinement.
  ///
  /// Translates the Python `get_global_s_bounds` function.
  static GlobalBoundsResult? getGlobalSBounds(
    double sMin,
    double sMax,
    List<ScorePair> pairs,
  ) {
    if (pairs.isEmpty) return null;

    // Collect critical s-values: intersections of L and U curves from different pairs
    final List<double> criticalS = [sMin, sMax];

    // Build critical s-values from intersections
    for (int i = 0; i < pairs.length; i++) {
      for (int j = i + 1; j < pairs.length; j++) {
        final bi = pairs[i].b;
        final ti = pairs[i].t;
        final bj = pairs[j].b;
        final tj = pairs[j].t;

        // Check all combinations of L_i, U_i with L_j, U_j
        // L(s) = b - s*(T - 49)/10, U(s) = b - s*(T - 50)/10
        final coeffs = [
          [ti - 49, tj - 49],
          [ti - 49, tj - 50],
          [ti - 50, tj - 49],
          [ti - 50, tj - 50],
        ];

        for (final c in coeffs) {
          final ci = c[0].toDouble();
          final cj = c[1].toDouble();
          if (ci != cj) {
            final sIntersect = 10 * (bi - bj) / (ci - cj);
            if (sIntersect > sMin && sIntersect < sMax) {
              criticalS.add(sIntersect);
            }
          }
        }
      }
    }

    // Sort critical s-values
    criticalS.sort();

    double globalSMin = double.infinity;
    double globalSMax = 0;

    // At each critical s-value, compute m bounds
    for (final s in criticalS) {
      if (s <= 0) continue;

      double mLow = double.negativeInfinity;
      double mHigh = double.infinity;

      for (final pair in pairs) {
        // L(s) = b - s*(T - 49)/10 — нижняя граница m
        final l = pair.b - s * (pair.t - 49) / 10;
        // U(s) = b - s*(T - 50)/10 — верхняя граница m
        final u = pair.b - s * (pair.t - 50) / 10;
        mLow = math.max(mLow, l);
        mHigh = math.min(mHigh, u);
      }

      if (mLow <= mHigh) {
        if (s < globalSMin) globalSMin = s;
        if (s > globalSMax) globalSMax = s;
      }
    }

    if (globalSMin > globalSMax) return null;

    // Compute final m-bounds at the found s interval
    double mMinFinal = double.negativeInfinity;
    double mMaxFinal = double.infinity;

    for (final pair in pairs) {
      final l1 = pair.b - globalSMin * (pair.t - 49) / 10;
      final u1 = pair.b - globalSMin * (pair.t - 50) / 10;
      final l2 = pair.b - globalSMax * (pair.t - 49) / 10;
      final u2 = pair.b - globalSMax * (pair.t - 50) / 10;

      mMinFinal = math.max(mMinFinal, math.min(l1, l2));
      mMaxFinal = math.min(mMaxFinal, math.max(u1, u2));
    }

    return GlobalBoundsResult(
      sMin: globalSMin,
      sMax: globalSMax,
      mMin: mMinFinal,
      mMax: mMaxFinal,
    );
  }

  /// Generate curve data for visualization.
  static List<CurvePoint> generateLowerCurve(
    List<ScorePair> pairs,
    double sStart,
    double sEnd, {
    int resolution = 500,
  }) {
    if (pairs.isEmpty) return [];

    final points = <CurvePoint>[];
    final step = (sEnd - sStart) / resolution;

    for (int i = 0; i <= resolution; i++) {
      final s = sStart + i * step;
      if (s <= 0) continue;

      double maxL = double.negativeInfinity;
      for (final pair in pairs) {
        final l = pair.b - s * (pair.t - 49) / 10;
        maxL = math.max(maxL, l);
      }
      points.add(CurvePoint(s: s, m: maxL));
    }
    return points;
  }

  static List<CurvePoint> generateUpperCurve(
    List<ScorePair> pairs,
    double sStart,
    double sEnd, {
    int resolution = 500,
  }) {
    if (pairs.isEmpty) return [];

    final points = <CurvePoint>[];
    final step = (sEnd - sStart) / resolution;

    for (int i = 0; i <= resolution; i++) {
      final s = sStart + i * step;
      if (s <= 0) continue;

      double minU = double.infinity;
      for (final pair in pairs) {
        final u = pair.b - s * (pair.t - 50) / 10;
        minU = math.min(minU, u);
      }
      points.add(CurvePoint(s: s, m: minU));
    }
    return points;
  }

  /// Compute per-pair intervals for display.
  static List<PairInterval> computePairIntervals(
    List<ScorePair> pairs,
    double sMin,
    double sMax,
  ) {
    final intervals = <PairInterval>[];

    for (final pair in pairs) {
      // m bounds at s_min and s_max
      final lAtSMin = pair.b - sMin * (pair.t - 49) / 10;
      final uAtSMin = pair.b - sMin * (pair.t - 50) / 10;
      final lAtSMax = pair.b - sMax * (pair.t - 49) / 10;
      final uAtSMax = pair.b - sMax * (pair.t - 50) / 10;

      final mLow = math.min(lAtSMin, lAtSMax);
      final mHigh = math.max(uAtSMin, uAtSMax);

      intervals.add(PairInterval(
        pair: pair,
        sMin: sMin,
        sMax: sMax,
        mMin: mLow,
        mMax: mHigh,
        sIntervalStr: _formatInterval(sMin, sMax),
        mIntervalStr: _formatInterval(mLow, mHigh),
      ));
    }

    return intervals;
  }

  /// Full computation pipeline.
  static ComputationResult compute(List<ScorePair> pairs) {
    if (pairs.length < 2) {
      return const ComputationResult(
        sBounds: SBoundsResult(),
      );
    }

    final sBounds = getSBounds(pairs);

    if (!sBounds.isValid) {
      return ComputationResult(sBounds: sBounds);
    }

    final effectiveSMin = sBounds.sMin ?? 0.01;
    final effectiveSMax = sBounds.sMax ?? (effectiveSMin * 100);

    final globalBounds = getGlobalSBounds(effectiveSMin, effectiveSMax, pairs);

    final plotSMin =
        effectiveSMin > 0 ? effectiveSMin * 0.8 : 0.01;
    final plotSMax = effectiveSMax < double.infinity
        ? effectiveSMax * 1.2
        : effectiveSMin * 120;

    final lowerCurve = generateLowerCurve(pairs, plotSMin, plotSMax);
    final upperCurve = generateUpperCurve(pairs, plotSMin, plotSMax);

    final pairIntervals = globalBounds != null
        ? computePairIntervals(pairs, globalBounds.sMin, globalBounds.sMax)
        : <PairInterval>[];

    return ComputationResult(
      sBounds: sBounds,
      globalBounds: globalBounds,
      lowerCurve: lowerCurve,
      upperCurve: upperCurve,
      pairIntervals: pairIntervals,
    );
  }

  /// Verify that a specific (s, m) pair satisfies T = 50 + floor(10*(b-m)/s).
  static int computeT(double b, double m, double s) {
    return 50 + (10 * (b - m) / s).floor();
  }

  /// Validate that given (s, m) reproduce all pairs.
  static bool validate(List<ScorePair> pairs, double s, double m) {
    for (final pair in pairs) {
      if (computeT(pair.b, m, s) != pair.t) return false;
    }
    return true;
  }

  static String _formatInterval(double low, double high) {
    final l = low.toStringAsFixed(4);
    final h = high.toStringAsFixed(4);
    return '[$l, $h]';
  }
}
