import 'package:flutter/foundation.dart';

/// One entry in the user's activity diary: a completed action, the quantity
/// recorded, and the estimated CO2e avoided.
@immutable
class ActionLog {
  const ActionLog({
    this.id,
    required this.actionId,
    required this.actionTitle,
    required this.category,
    required this.happenedOn,
    required this.kgCo2e,
    this.quantity,
    this.inputUnit,
    this.provisional = false,
    this.createdAt,
  });

  final int? id;
  final String actionId;

  /// Snapshot of the action title at log time, so history stays readable
  /// even if the catalog changes later.
  final String actionTitle;

  /// Snapshot category name (EmissionCategory.name), for aggregation.
  final String category;
  final DateTime happenedOn;

  /// Estimated kg CO2e avoided for this log entry.
  final double kgCo2e;
  final double? quantity;
  final String? inputUnit;

  /// True when the estimate is based on a provisional factor.
  final bool provisional;
  final DateTime? createdAt;

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'action_id': actionId,
    'action_title': actionTitle,
    'category': category,
    'happened_on': happenedOn.millisecondsSinceEpoch,
    'quantity': quantity,
    'input_unit': inputUnit,
    'kg_co2e': kgCo2e,
    'provisional': provisional ? 1 : 0,
    'created_at': (createdAt ?? happenedOn).millisecondsSinceEpoch,
  };

  factory ActionLog.fromRow(Map<String, Object?> row) {
    final happenedOn = DateTime.fromMillisecondsSinceEpoch(
      row['happened_on'] as int,
    );
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      row['created_at'] as int,
    );
    return ActionLog(
      id: row['id'] as int?,
      actionId: row['action_id'] as String,
      actionTitle: row['action_title'] as String,
      category: row['category'] as String,
      happenedOn: happenedOn,
      quantity: (row['quantity'] as num?)?.toDouble(),
      inputUnit: row['input_unit'] as String?,
      kgCo2e: (row['kg_co2e'] as num).toDouble(),
      provisional: (row['provisional'] as int) == 1,
      createdAt: createdAt,
    );
  }
}
