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
}
