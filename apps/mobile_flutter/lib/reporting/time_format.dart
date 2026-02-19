String formatMinutes(
  int minutes, {
  String? localeCode,
  bool signed = false,
  bool showPlusForZero = false,
}) {
  final normalizedLocale = (localeCode ?? '').toLowerCase();
  final isSwedish = normalizedLocale.startsWith('sv');
  final absoluteMinutes = minutes.abs();
  final hours = absoluteMinutes ~/ 60;
  final mins = absoluteMinutes % 60;

  final base = isSwedish ? '$hours h $mins min' : '${hours}h ${mins}m';

  if (!signed) {
    return base;
  }

  String sign = '';
  if (minutes < 0) {
    sign = '-';
  } else if (minutes > 0 || showPlusForZero) {
    sign = '+';
  }

  return '$sign$base';
}
