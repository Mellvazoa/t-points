/// Data models for sessions and systems.
library;

import 'dart:convert';
import 'package:t_points/features/calculation/calculation_engine.dart';

/// A system of pairs.
class ScoreSystem {
  final String id;
  final String name;
  final List<ScorePair> pairs;

  ScoreSystem({
    required this.id,
    required this.name,
    required this.pairs,
  });

  ScoreSystem copyWith({
    String? name,
    List<ScorePair>? pairs,
  }) {
    return ScoreSystem(
      id: id,
      name: name ?? this.name,
      pairs: pairs ?? this.pairs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pairs': pairs
            .map((p) => {'systemId': p.systemId, 'b': p.b, 't': p.t})
            .toList(),
      };

  factory ScoreSystem.fromJson(Map<String, dynamic> json) {
    return ScoreSystem(
      id: json['id'] as String,
      name: json['name'] as String,
      pairs: (json['pairs'] as List)
          .map((p) => ScorePair(
                systemId: p['systemId'] as String? ?? json['id'] as String,
                b: (p['b'] as num).toDouble(),
                t: (p['t'] as num).toInt(),
              ))
          .toList(),
    );
  }
}

/// A saved session containing multiple systems and metadata.
class Session {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScoreSystem> systems;

  Session({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.systems,
  });

  Session copyWith({
    String? name,
    DateTime? updatedAt,
    List<ScoreSystem>? systems,
  }) {
    return Session(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      systems: systems ?? this.systems,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'systems': systems.map((s) => s.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      systems: (json['systems'] as List)
          .map((s) => ScoreSystem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  String serialize() => jsonEncode(toJson());

  factory Session.deserialize(String data) =>
      Session.fromJson(jsonDecode(data) as Map<String, dynamic>);
}
