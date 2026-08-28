/// Riverpod providers for the application state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:t_points/features/calculation/calculation_engine.dart';
import 'package:t_points/features/sessions/session_model.dart';

// ─── Navigation ───────────────────────────────────────────────────────

final selectedTabProvider = StateProvider<int>((ref) => 0);

// ─── Systems State ────────────────────────────────────────────────────

final systemsProvider =
    StateNotifierProvider<SystemsNotifier, List<ScoreSystem>>((ref) {
  return SystemsNotifier();
});

class SystemsNotifier extends StateNotifier<List<ScoreSystem>> {
  static const _uuid = Uuid();

  SystemsNotifier() : super([
    ScoreSystem(id: _uuid.v4(), name: 'Система 1', pairs: []),
  ]);

  void addSystem(String name) {
    state = [...state, ScoreSystem(id: _uuid.v4(), name: name, pairs: [])];
  }

  void removeSystem(String id) {
    if (state.length == 1) return; // Keep at least one
    state = state.where((s) => s.id != id).toList();
  }

  void addPair(String systemId, ScorePair pair) {
    state = state.map((s) {
      if (s.id == systemId) {
        return s.copyWith(pairs: [...s.pairs, pair]);
      }
      return s;
    }).toList();
  }

  void addPairs(String systemId, List<ScorePair> pairs) {
    state = state.map((s) {
      if (s.id == systemId) {
        return s.copyWith(pairs: [...s.pairs, ...pairs]);
      }
      return s;
    }).toList();
  }
  
  void removePair(String systemId, ScorePair pair) {
    state = state.map((s) {
      if (s.id == systemId) {
        final newPairs = List<ScorePair>.from(s.pairs)..remove(pair);
        return s.copyWith(pairs: newPairs);
      }
      return s;
    }).toList();
  }

  void clearSystem(String systemId) {
    state = state.map((s) {
      if (s.id == systemId) {
        return s.copyWith(pairs: []);
      }
      return s;
    }).toList();
  }

  void setSystems(List<ScoreSystem> systems) {
    if (systems.isEmpty) {
      state = [ScoreSystem(id: _uuid.v4(), name: 'Система 1', pairs: [])];
    } else {
      state = systems;
    }
  }

  /// Parse input string: "systemName b1 T1 b2 T2 ..." OR "b1 T1 b2 T2 ..."
  /// If using 3 tokens per pair (system_id/name b T), it parses them.
  /// The user requested 3 numbers, but actually it's "system_id b T".
  String? parseAndAdd(String input, {String? defaultSystemId}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'Введите данные';

    final parts = trimmed.split(RegExp(r'\s+'));
    
    // Check if it's multiples of 3 (system_name b T)
    if (parts.length % 3 == 0) {
      for (int i = 0; i < parts.length; i += 3) {
        final sysName = parts[i];
        final bStr = parts[i + 1];
        final tStr = parts[i + 2];

        final b = double.tryParse(bStr);
        if (b == null) return 'Некорректное число b: "$bStr"';
        final t = int.tryParse(tStr);
        if (t == null) return 'Некорректное число T: "$tStr"';
        if (t < 30) return 'T должно быть ≥ 30, получено: $t';

        // Find system or create
        var sys = state.cast<ScoreSystem?>().firstWhere(
            (s) => s!.name == sysName, orElse: () => null);
        
        if (sys == null) {
          final newSys = ScoreSystem(id: _uuid.v4(), name: sysName, pairs: []);
          state = [...state, newSys];
          sys = newSys;
        }

        final pair = ScorePair(systemId: sys.id, b: b, t: t);
        addPair(sys.id, pair);
      }
      return null;
    } 
    // Fallback to multiples of 2 if defaultSystemId is provided
    else if (parts.length % 2 == 0 && defaultSystemId != null) {
      final newPairs = <ScorePair>[];
      for (int i = 0; i < parts.length; i += 2) {
        final bStr = parts[i];
        final tStr = parts[i + 1];

        final b = double.tryParse(bStr);
        if (b == null) return 'Некорректное число b: "$bStr"';
        final t = int.tryParse(tStr);
        if (t == null) return 'Некорректное число T: "$tStr"';
        if (t < 30) return 'T должно быть ≥ 30, получено: $t';

        newPairs.add(ScorePair(systemId: defaultSystemId, b: b, t: t));
      }
      addPairs(defaultSystemId, newPairs);
      return null;
    }
    
    return 'Формат не распознан. Используйте "Система b T" или четное количество чисел "b T"';
  }
}

final activeSystemIdProvider = StateProvider<String?>((ref) {
  final systems = ref.watch(systemsProvider);
  return systems.isNotEmpty ? systems.first.id : null;
});

// ─── Computation Result ───────────────────────────────────────────────

final computationResultProvider = Provider.family<ComputationResult?, String>((ref, systemId) {
  final systems = ref.watch(systemsProvider);
  final sys = systems.cast<ScoreSystem?>().firstWhere((s) => s!.id == systemId, orElse: () => null);
  if (sys == null || sys.pairs.length < 2) return null;
  return CalculationEngine.compute(sys.pairs);
});

// ─── Sessions ─────────────────────────────────────────────────────────

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<Session>>((ref) {
  return SessionsNotifier(ref);
});

class SessionsNotifier extends StateNotifier<List<Session>> {
  final Ref _ref;
  static const _storageKey = 'tpoints_sessions_v2';
  static const _uuid = Uuid();

  SessionsNotifier(this._ref) : super([]) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? [];
    state = data.map((s) => Session.deserialize(s)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _storageKey, state.map((s) => s.serialize()).toList());
  }

  Future<void> saveCurrentSession(String name) async {
    final systems = _ref.read(systemsProvider);
    final now = DateTime.now();
    final session = Session(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
      systems: List.from(systems),
    );
    state = [session, ...state];
    await _saveSessions();
  }

  Future<void> updateSession(String id) async {
    final systems = _ref.read(systemsProvider);
    final now = DateTime.now();
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(updatedAt: now, systems: List.from(systems));
      }
      return s;
    }).toList();
    await _saveSessions();
  }

  void loadSession(Session session) {
    _ref.read(systemsProvider.notifier).setSystems(List.from(session.systems));
    _ref.read(activeSessionIdProvider.notifier).state = session.id;
    if (session.systems.isNotEmpty) {
      _ref.read(activeSystemIdProvider.notifier).state = session.systems.first.id;
    }
  }

  Future<void> deleteSession(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _saveSessions();
  }
}

final activeSessionIdProvider = StateProvider<String?>((ref) => null);

// ─── Input error state ────────────────────────────────────────────────

final inputErrorProvider = StateProvider<String?>((ref) => null);
