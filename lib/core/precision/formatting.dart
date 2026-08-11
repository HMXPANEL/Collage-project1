/// Human-friendly display of impact estimates.
abstract final class Formatting {
  /// Renders kilograms compactly: below 1000 kg stays metric, above switches
  /// to tonnes, keeping at most two significant decimals.
  static String compactKg(double kg) {
    final abs = kg.abs();
    if (abs >= 1000) {
      return '${(kg / 1000).toStringAsFixed(2)} t';
    }
    final decimals = abs >= 10 ? 1 : 2;
    return '${kg.toStringAsFixed(decimals)} kg';
  }

  /// Renders non-zero values too small to round to 0.01 kg as `<0.01 kg`
  /// instead of a misleading `0.00 kg`.
  static String tinyKg(double kg) {
    if (kg > 0 && kg < 0.01) return '<0.01 kg';
    return compactKg(kg);
  }
}
